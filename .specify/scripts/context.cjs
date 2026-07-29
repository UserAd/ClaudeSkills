#!/usr/bin/env node
'use strict';

/*
 * context.cjs — phase tracking + context assembly for a spec-kit feature.
 *
 * Commands:
 *   phase                 Print the current phase number (the [~] phase, else first [ ]).
 *   start  <phaseNumber>  Mark phase as in-progress  → [~] in the tasks.md <index>.
 *   finish <phaseNumber>  Mark phase as completed     → [x] in the tasks.md <index>.
 *   context [phaseNumber] Print the phase context (defaults to current phase).
 *
 * Sources (resolved for the current feature):
 *   plan.md   → <tech_context>...</tech_context>
 *   tasks.md  → <index>...</index>  and  <phase_N>...</phase_N>
 *
 * Feature resolution mirrors .specify/scripts/bash/common.sh:
 *   SPECIFY_FEATURE env → git branch → latest specs/* → "main".
 *   Feature dir located by exact name, else create-new-feature.sh's
 *   branch_to_dirname mapping (slash→dash), else NNN- numeric prefix.
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const INDEX_LINE = /^(\s*)\[([ ~xX])\]\s+\[(\d+|[Nn])\]\s+(.*\S)\s*$/;

function git(cmd) {
  return execSync(`git ${cmd}`, { cwd: __dirname, stdio: ['ignore', 'pipe', 'ignore'] })
    .toString()
    .trim();
}

function repoRoot() {
  try {
    return git('rev-parse --show-toplevel');
  } catch {
    // script lives at <root>/.specify/scripts/context.cjs
    return path.resolve(__dirname, '..', '..');
  }
}

function currentFeature(root) {
  if (process.env.SPECIFY_FEATURE) return process.env.SPECIFY_FEATURE;
  try {
    const branch = git('rev-parse --abbrev-ref HEAD');
    if (branch) return branch;
  } catch {
    /* not a git repo */
  }
  const specs = path.join(root, 'specs');
  let latest = null;
  let mtime = -1;
  if (fs.existsSync(specs)) {
    for (const name of fs.readdirSync(specs)) {
      const full = path.join(specs, name);
      if (fs.statSync(full).isDirectory()) {
        const t = fs.statSync(full).mtimeMs;
        if (t > mtime) {
          mtime = t;
          latest = name;
        }
      }
    }
  }
  return latest || 'main';
}

// Mirror create-new-feature.sh branch_to_dirname:
//   sed 's|/|-|g' | sed -E 's/-+/-/g' | sed 's/^-//' | sed 's/-$//'
function branchToDir(name) {
  return name
    .replace(/\//g, '-')
    .replace(/-+/g, '-')
    .replace(/^-+/, '')
    .replace(/-+$/, '');
}

function featureDir(root, feature) {
  const specs = path.join(root, 'specs');

  const exact = path.join(specs, feature);
  if (fs.existsSync(exact)) return exact;

  // slash-prefixed branch (tech/foo) → dir (tech-foo)
  const mapped = path.join(specs, branchToDir(feature));
  if (mapped !== exact && fs.existsSync(mapped)) return mapped;

  const m = /^(\d{3})-/.exec(feature);
  if (m && fs.existsSync(specs)) {
    const prefix = `${m[1]}-`;
    const matches = fs
      .readdirSync(specs)
      .filter((n) => n.startsWith(prefix) && fs.statSync(path.join(specs, n)).isDirectory())
      .sort();
    if (matches.length >= 1) return path.join(specs, matches[0]);
  }
  return mapped; // best-effort path; caller validates existence
}

function readFile(p) {
  return fs.existsSync(p) ? fs.readFileSync(p, 'utf8') : null;
}

function extractTag(content, tag) {
  if (!content) return null;
  // Match only a tag that stands alone on its own line (the structural form
  // the templates emit), so prose that merely MENTIONS the tag elsewhere in
  // the document — common in spec-kit docs about the engine itself — does not
  // hijack the match. Non-greedy → first structural close after the open.
  const re = new RegExp(`^<${tag}>$\\s*([\\s\\S]*?)\\s*^</${tag}>$`, 'm');
  const m = re.exec(content);
  return m ? m[1].trim() : null;
}

function indexBounds(tasks) {
  const text = tasks || '';
  // Line-anchored, for the same reason as extractTag: ignore prose mentions
  // of <index> and bind to the structural block only.
  const om = /^<index>$/m.exec(text);
  const cm = /^<\/index>$/m.exec(text);
  if (!om || !cm || cm.index < om.index) return null;
  const open = om.index;
  const close = cm.index;
  return { open, close, inner: text.slice(open + '<index>'.length, close) };
}

function parseIndex(tasks) {
  const b = indexBounds(tasks || '');
  if (!b) return [];
  const phases = [];
  for (const line of b.inner.split('\n')) {
    const m = INDEX_LINE.exec(line);
    if (m) phases.push({ status: m[2].toLowerCase() === 'x' ? 'x' : m[2], number: m[3], name: m[4] });
  }
  return phases;
}

function currentPhaseNumber(phases) {
  const inProgress = phases.find((p) => p.status === '~');
  if (inProgress) return inProgress.number;
  const notStarted = phases.find((p) => p.status === ' ');
  if (notStarted) return notStarted.number;
  return null; // empty or all complete
}

function setPhaseStatus(tasksPath, num, marker) {
  const tasks = readFile(tasksPath);
  if (tasks == null) throw new Error(`tasks.md not found: ${tasksPath}`);
  const b = indexBounds(tasks);
  if (!b) throw new Error('No <index>...</index> block in tasks.md');

  let found = false;
  let otherInProgress = null;
  const lines = b.inner.split('\n').map((line) => {
    const m = INDEX_LINE.exec(line);
    if (!m) return line;
    if (m[3] === String(num)) {
      found = true;
      // replace only the status bracket (first [ ]/[~]/[x] on the line)
      return line.replace(/\[[ ~xX]\]/, `[${marker}]`);
    }
    if (marker === '~' && m[2] === '~') otherInProgress = m[3];
    return line;
  });
  if (!found) throw new Error(`Phase ${num} not present in <index>`);

  const updated = tasks.slice(0, b.open) + '<index>' + lines.join('\n') + tasks.slice(b.close);
  fs.writeFileSync(tasksPath, updated);
  return { otherInProgress };
}

function listSpecFiles(fdir, root) {
  const out = [];
  (function walk(dir) {
    for (const name of fs.readdirSync(dir).sort()) {
      const full = path.join(dir, name);
      if (fs.statSync(full).isDirectory()) walk(full);
      else out.push(path.relative(root, full));
    }
  })(fdir);

  const priority = ['spec.md', 'plan.md', 'research.md', 'data-model.md', 'quickstart.md', 'tasks.md'];
  const rank = (rel) => {
    const base = path.basename(rel);
    const i = priority.indexOf(base);
    return i === -1 ? priority.length : i;
  };
  return out.sort((a, b) => rank(a) - rank(b) || a.localeCompare(b));
}

function buildContext(root, fdir, num) {
  const plan = readFile(path.join(fdir, 'plan.md'));
  const tasks = readFile(path.join(fdir, 'tasks.md'));

  const phase = parseIndex(tasks).find((p) => p.number === String(num));
  const phaseName = phase ? phase.name : `Phase ${num}`;
  const tech = extractTag(plan, 'tech_context') || '(no <tech_context> found in plan.md)';
  const phaseBody = extractTag(tasks, `phase_${num}`) || `(no <phase_${num}> found in tasks.md)`;
  const files = listSpecFiles(fdir, root)
    .map((f) => `- ${f}`)
    .join('\n');

  return [
    `# Context for ${phaseName}`,
    '',
    '# Tech content',
    '',
    tech,
    '',
    '# Phase tasks',
    '',
    phaseBody,
    '',
    '# Files',
    '',
    '**NOTICE:** Do not read them upfront.',
    '',
    files,
    '',
  ].join('\n');
}

function usage() {
  return [
    'Usage: node .specify/scripts/context.cjs <command> [args]',
    '',
    '  phase                 Print current phase number',
    '  start  <phaseNumber>  Mark phase in-progress  [~]',
    '  finish <phaseNumber>  Mark phase completed     [x]',
    '  context [phaseNumber] Print phase context (default: current phase)',
    '',
  ].join('\n');
}

function requireFeatureDir(fdir) {
  if (!fs.existsSync(fdir)) {
    process.stderr.write(`Feature directory not found: ${fdir}\n`);
    process.exit(1);
  }
}

function fail(msg) {
  process.stderr.write(`${msg}\n`);
  process.exit(1);
}

function main() {
  const [cmd, arg] = process.argv.slice(2);
  const root = repoRoot();
  const feature = currentFeature(root);
  const fdir = featureDir(root, feature);
  const tasksPath = path.join(fdir, 'tasks.md');

  switch (cmd) {
    case 'phase': {
      requireFeatureDir(fdir);
      const tasks = readFile(tasksPath);
      if (tasks == null) fail(`tasks.md not found: ${path.relative(root, tasksPath)}`);
      if (indexBounds(tasks) == null) fail('No <index>...</index> block in tasks.md');
      const num = currentPhaseNumber(parseIndex(tasks));
      if (num == null) {
        process.stderr.write('No current phase (index empty or all phases complete)\n');
        process.exit(0);
      }
      process.stdout.write(`${num}\n`);
      break;
    }

    case 'start':
    case 'finish': {
      requireFeatureDir(fdir);
      const num = (arg || '').trim();
      if (!/^\d+$/.test(num)) {
        process.stderr.write(`Usage: node .specify/scripts/context.cjs ${cmd} <phaseNumber>\n`);
        process.exit(1);
      }
      const marker = cmd === 'start' ? '~' : 'x';
      let otherInProgress = null;
      try {
        ({ otherInProgress } = setPhaseStatus(tasksPath, num, marker));
      } catch (e) {
        fail(e.message);
      }
      if (cmd === 'start' && otherInProgress && otherInProgress !== num) {
        process.stderr.write(
          `Warning: phase ${otherInProgress} still [~]; legend expects at most one in-progress phase.\n`,
        );
      }
      process.stdout.write(`Phase ${num} -> [${marker}]  (${path.relative(root, tasksPath)})\n`);
      break;
    }

    case 'context': {
      requireFeatureDir(fdir);
      let num = (arg || '').trim();
      if (!num) {
        num = currentPhaseNumber(parseIndex(readFile(tasksPath)));
        if (num == null) {
          process.stderr.write('No current phase to build context for\n');
          process.exit(1);
        }
      }
      process.stdout.write(buildContext(root, fdir, num));
      break;
    }

    default:
      process.stdout.write(usage());
      if (cmd && cmd !== 'help' && cmd !== '--help' && cmd !== '-h') process.exit(1);
  }
}

main();
