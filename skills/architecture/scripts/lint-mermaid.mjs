#!/usr/bin/env node
// Mermaid diagram linter for standalone .mmd files and embedded blocks in markdown.
// Based on GitLab's check_mermaid.mjs approach.
//
// Usage:
//   node scripts/lint-mermaid.mjs                  - Lint all .mmd and .md files
//   node scripts/lint-mermaid.mjs "docs/**/*.md"   - Lint specific pattern
//   node scripts/lint-mermaid.mjs file.mmd file.md - Lint specific files

import fs from "fs";
import { glob } from "glob";
import { JSDOM } from "jsdom";
import DOMPurify from "isomorphic-dompurify";

// Setup virtual DOM for mermaid (required for Node.js environment)
const dom = new JSDOM("<!DOCTYPE html><html><body></body></html>", {
  url: "http://localhost",
});
global.window = dom.window;
global.document = dom.window.document;
Object.defineProperty(global, "navigator", {
  value: dom.window.navigator,
  writable: true,
  configurable: true,
});

// isomorphic-dompurify provides a ready-to-use instance
global.DOMPurify = DOMPurify;

// Import mermaid after DOM setup
const mermaid = (await import("mermaid")).default;

// Initialize mermaid with validation-only config
mermaid.initialize({
  theme: "neutral",
  securityLevel: "strict",
  startOnLoad: false,
  suppressErrorRendering: true,
});

const MERMAID_BLOCK_REGEX = /```mermaid\s*\n([\s\S]*?)```/gm;

// Calculate line number from string position
function getLineNumber(content, position) {
  return content.substring(0, position).split("\n").length;
}

// Validate mermaid diagram syntax
async function validateMermaid(code, filename, lineOffset = 0) {
  try {
    await mermaid.parse(code.trim());
    return null;
  } catch (error) {
    const errorMessage = error.message || String(error);
    // Extract line number from mermaid error if available
    const lineMatch = errorMessage.match(/line\s*(\d+)/i);
    const errorLine = lineMatch ? parseInt(lineMatch[1], 10) : 1;
    return {
      file: filename,
      line: lineOffset + errorLine,
      message: errorMessage.split("\n")[0],
    };
  }
}

// Process a standalone .mmd file
async function processMermaidFile(filepath) {
  const content = fs.readFileSync(filepath, "utf-8");
  return validateMermaid(content, filepath, 0);
}

// Process a markdown file and extract mermaid blocks
async function processMarkdownFile(filepath) {
  const content = fs.readFileSync(filepath, "utf-8");
  const errors = [];

  let match;
  while ((match = MERMAID_BLOCK_REGEX.exec(content)) !== null) {
    const mermaidCode = match[1];
    const lineOffset = getLineNumber(content, match.index);
    const error = await validateMermaid(mermaidCode, filepath, lineOffset);
    if (error) {
      errors.push(error);
    }
  }

  return errors;
}

// Main entry point
async function main() {
  const args = process.argv.slice(2);

  // Default patterns if no arguments provided
  const patterns =
    args.length > 0 ? args : ["**/*.mmd", "**/*.md", "!node_modules/**"];

  // Resolve files from patterns
  const files = await glob(patterns, {
    ignore: ["node_modules/**", ".git/**", "tmp/**"],
    nodir: true,
  });

  if (files.length === 0) {
    console.log("No files found to lint.");
    process.exit(0);
  }

  const mmdFiles = files.filter((f) => f.endsWith(".mmd"));
  const mdFiles = files.filter((f) => f.endsWith(".md"));

  let totalErrors = 0;
  const allErrors = [];

  // Process standalone .mmd files
  for (const file of mmdFiles) {
    const error = await processMermaidFile(file);
    if (error) {
      allErrors.push(error);
      totalErrors++;
    }
  }

  // Process markdown files for embedded mermaid blocks
  for (const file of mdFiles) {
    const errors = await processMarkdownFile(file);
    allErrors.push(...errors);
    totalErrors += errors.length;
  }

  // Report results
  if (allErrors.length > 0) {
    console.error("\nMermaid syntax errors found:\n");
    for (const error of allErrors) {
      console.error("  " + error.file + ":" + error.line);
      console.error("    " + error.message + "\n");
    }
    console.error("\nTotal: " + totalErrors + " error(s) in " + files.length + " files");
    console.error("\nSee https://mermaid.js.org/syntax/flowchart.html for syntax reference.");
    process.exit(1);
  }

  console.log(
    "Mermaid lint passed: " + mmdFiles.length + " .mmd files, " + mdFiles.length + " .md files checked"
  );
  process.exit(0);
}

main().catch((error) => {
  console.error("Unexpected error:", error);
  process.exit(1);
});
