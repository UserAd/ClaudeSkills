#!/usr/bin/env bash
#
# sessions.sh — enumerate and filter Claude/Codex/pi session transcripts for
# the memory dream/distill workflow. STRICTLY READ-ONLY on all session files:
# it only enumerates (find), stats (stat), and reads the minimum prefix needed
# for a session-start timestamp / codex cwd. It never opens a session file for
# writing and never reads conversational content beyond the first parseable
# record. Source files are byte-identical after any run (contract C-09).
#
# Bash 3.2-compatible (macOS default shell): no mapfile/readarray, no
# associative arrays, no ${var^^}/${var,,}, no `declare -A`. Uses `while read`,
# `case`, and BSD `date -j` epoch math with a GNU `date -d` fallback.
#
# Contract: specs/feature-memory-dream-distill/contracts/sessions-cli.md
#
# Subcommands:
#   sources
#   list --source <claude|codex|pi|all> --since <bound> [--until <bound>]
#
# <bound>: relative (24h|7d|30d|<N>h|<N>d) or absolute (YYYY-MM-DD).
# Defaults: --since 24h, --until = now.
#
# Exit codes: 0 ok (incl. zero matches) | 2 usage error | 3 no source present.

set -euo pipefail

# ---------------------------------------------------------------------------
# Source-root resolution (env-overridable test seams — contract lines 16-23).
# Defaults derive from the current working directory ($(pwd)) so the helper is
# portable across project checkouts: PROJECT_ROOT defaults to pwd, and the
# claude/pi session roots are the pwd-encoded directory names (each `/` in the
# project root becomes `-`). `${var//\//-}` is Bash 3.2-safe global
# substitution. Env overrides always win (the bats suite relies on this).
# CODEX_SESS_DIR stays the global ~/.codex/sessions — codex sessions are not
# project-scoped on disk; the codex adapter filters by payload.cwd==PROJECT_ROOT.
# ---------------------------------------------------------------------------
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
_enc="${PROJECT_ROOT//\//-}"
CLAUDE_SESS_DIR="${CLAUDE_SESS_DIR:-$HOME/.claude/projects/${_enc}}"
CODEX_SESS_DIR="${CODEX_SESS_DIR:-$HOME/.codex/sessions}"
PI_SESS_DIR="${PI_SESS_DIR:-$HOME/.pi/agent/sessions/-${_enc}--}"

usage() {
  cat <<'EOF'
Usage:
  sessions.sh sources
  sessions.sh list --source <claude|codex|pi|all> --since <bound> [--until <bound>]

Enumerate and filter local AI session transcripts (read-only).

<bound>: relative (24h, 7d, 30d) or absolute (YYYY-MM-DD).
Defaults: --since 24h, --until = now.

Environment overrides (test seams):
  CLAUDE_SESS_DIR  CODEX_SESS_DIR  PI_SESS_DIR  PROJECT_ROOT

Exit codes: 0 success (incl. zero matches) | 2 usage error | 3 no source present.
EOF
}

# Emit a usage error to stderr and exit 2.
die_usage() {
  echo "sessions.sh: $1" >&2
  usage >&2
  exit 2
}

# ---------------------------------------------------------------------------
# Date/epoch helpers (T020). BSD `date -j` first, GNU `date -d` fallback (R9).
# ---------------------------------------------------------------------------

# Current epoch seconds.
now_epoch() {
  date +%s
}

# Convert an ISO-8601 instant (YYYY-MM-DDTHH:MM:SS[.fff][Z]) to epoch seconds.
# Strips fractional seconds and trailing Z; treats the instant as UTC.
# Echoes epoch on success; returns non-zero on failure.
iso_to_epoch() {
  iso="$1"
  # Normalize: drop fractional seconds and trailing Z -> YYYY-MM-DDTHH:MM:SS
  norm=$(printf '%s' "$iso" | sed -E 's/\.[0-9]+//; s/Z$//')
  # BSD date: parse as UTC.
  if e=$(TZ=UTC date -j -f '%Y-%m-%dT%H:%M:%S' "$norm" +%s 2>/dev/null); then
    printf '%s' "$e"
    return 0
  fi
  # GNU fallback: re-attach Z so GNU treats it as UTC.
  if e=$(date -u -d "${norm}Z" +%s 2>/dev/null); then
    printf '%s' "$e"
    return 0
  fi
  return 1
}

# Convert epoch seconds to normalized ISO-8601 UTC (YYYY-MM-DDTHH:MM:SSZ).
epoch_to_iso() {
  ep="$1"
  if iso=$(TZ=UTC date -j -f '%s' "$ep" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null); then
    printf '%s' "$iso"
    return 0
  fi
  date -u -d "@${ep}" '+%Y-%m-%dT%H:%M:%SZ'
}

# Parse a date bound (relative 24h/7d/30d/<N>h/<N>d or absolute YYYY-MM-DD) to
# epoch seconds, relative to a supplied "now" epoch. For the --until default,
# absolute YYYY-MM-DD resolves to END-of-day (23:59:59 UTC) so an inclusive
# upper bound covers the whole day. For --since, absolute YYYY-MM-DD resolves
# to START-of-day (00:00:00 UTC). $3 = "start" | "end".
# Echoes epoch on success; returns 2 on a malformed bound.
bound_to_epoch() {
  bound="$1"
  ref_now="$2"
  edge="$3"

  case "$bound" in
    # Relative: <N>h or <N>d.
    *[0-9]h)
      n=${bound%h}
      case "$n" in (*[!0-9]*) return 2 ;; esac
      [ -n "$n" ] || return 2
      printf '%s' "$(( ref_now - n * 3600 ))"
      return 0
      ;;
    *[0-9]d)
      n=${bound%d}
      case "$n" in (*[!0-9]*) return 2 ;; esac
      [ -n "$n" ] || return 2
      printf '%s' "$(( ref_now - n * 86400 ))"
      return 0
      ;;
    # Absolute: YYYY-MM-DD.
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      if [ "$edge" = "end" ]; then
        iso="${bound}T23:59:59Z"
      else
        iso="${bound}T00:00:00Z"
      fi
      if e=$(iso_to_epoch "$iso"); then
        printf '%s' "$e"
        return 0
      fi
      return 2
      ;;
    *)
      return 2
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Filesystem helpers.
# ---------------------------------------------------------------------------

# True if a path is a directory that contains at least one regular file
# (recursively). Used for E1 `present`.
dir_has_files() {
  d="$1"
  [ -d "$d" ] || return 1
  # Stop at first file. find prints then we test non-empty.
  found=$(find "$d" -type f -print 2>/dev/null | head -n1)
  [ -n "$found" ]
}

# File size in bytes (BSD stat -f%z, GNU stat -c%s fallback).
file_size() {
  f="$1"
  stat -f%z "$f" 2>/dev/null || stat -c%s "$f" 2>/dev/null || echo 0
}

# File mtime as epoch seconds (BSD stat -f%m, GNU stat -c%Y fallback).
file_mtime_epoch() {
  f="$1"
  stat -f%m "$f" 2>/dev/null || stat -c%Y "$f" 2>/dev/null || echo 0
}

# ---------------------------------------------------------------------------
# Per-source started_at extraction (read-only; minimal prefix read).
# Each echoes: "<epoch> <ts_source> <id>" on success, or non-zero on a
# fatal read error. ts_source is "record" or "mtime". A missing record
# timestamp yields the mtime fallback (C-04/C-10), never a crash.
# ---------------------------------------------------------------------------

# claude: skip null-timestamp meta records, take first record with a non-null
# .timestamp. id = that record's .sessionId. Reads only the first few lines.
extract_claude() {
  f="$1"
  ts=""
  id=""
  ln=0
  # Read at most the first 12 lines looking for a parseable timestamp.
  while IFS= read -r line || [ -n "$line" ]; do
    ln=$((ln + 1))
    [ "$ln" -gt 12 ] && break
    [ -n "$line" ] || continue
    # jq -e fails on malformed JSON; tolerate and continue.
    cand=$(printf '%s' "$line" | jq -r '.timestamp // empty' 2>/dev/null || true)
    if [ -n "$cand" ] && [ "$cand" != "null" ]; then
      ts="$cand"
      id=$(printf '%s' "$line" | jq -r '.sessionId // empty' 2>/dev/null || true)
      break
    fi
  done <"$f"

  if [ -n "$ts" ] && e=$(iso_to_epoch "$ts"); then
    [ -n "$id" ] || id=$(basename "$f" .jsonl)
    printf '%s record %s' "$e" "$id"
    return 0
  fi
  # Fallback: mtime.
  me=$(file_mtime_epoch "$f")
  [ -n "$id" ] || id=$(basename "$f" .jsonl)
  printf '%s mtime %s' "$me" "$id"
  return 0
}

# pi: line-1 type:"session" with .timestamp + .id. mtime fallback otherwise.
extract_pi() {
  f="$1"
  line1=$(head -n1 "$f" 2>/dev/null || true)
  ts=""
  id=""
  if [ -n "$line1" ]; then
    ts=$(printf '%s' "$line1" | jq -r '.timestamp // empty' 2>/dev/null || true)
    id=$(printf '%s' "$line1" | jq -r '.id // empty' 2>/dev/null || true)
  fi
  if [ -n "$ts" ] && [ "$ts" != "null" ] && e=$(iso_to_epoch "$ts"); then
    [ -n "$id" ] || id=$(basename "$f" .jsonl)
    printf '%s record %s' "$e" "$id"
    return 0
  fi
  me=$(file_mtime_epoch "$f")
  [ -n "$id" ] || id=$(basename "$f" .jsonl)
  printf '%s mtime %s' "$me" "$id"
  return 0
}

# codex: line-1 must be type:"session_meta" with payload.cwd == PROJECT_ROOT.
# Returns 1 (skip, not project) when cwd does not match or line 1 is not
# session_meta. Otherwise echoes started_at from payload.timestamp (mtime
# fallback) and id from payload.id.
extract_codex() {
  f="$1"
  line1=$(head -n1 "$f" 2>/dev/null || true)
  [ -n "$line1" ] || return 1
  type=$(printf '%s' "$line1" | jq -r '.type // empty' 2>/dev/null || true)
  [ "$type" = "session_meta" ] || return 1
  cwd=$(printf '%s' "$line1" | jq -r '.payload.cwd // empty' 2>/dev/null || true)
  [ "$cwd" = "$PROJECT_ROOT" ] || return 1

  ts=$(printf '%s' "$line1" | jq -r '.payload.timestamp // empty' 2>/dev/null || true)
  id=$(printf '%s' "$line1" | jq -r '.payload.id // empty' 2>/dev/null || true)
  if [ -n "$ts" ] && [ "$ts" != "null" ] && e=$(iso_to_epoch "$ts"); then
    [ -n "$id" ] || id=$(basename "$f" .jsonl)
    printf '%s record %s' "$e" "$id"
    return 0
  fi
  me=$(file_mtime_epoch "$f")
  [ -n "$id" ] || id=$(basename "$f" .jsonl)
  printf '%s mtime %s' "$me" "$id"
  return 0
}

# Emit one normalized E2 JSON record (JSONL) for a qualifying file.
# Args: source path started_epoch ts_source id
emit_record() {
  src="$1"; path="$2"; sep="$3"; tssrc="$4"; id="$5"
  started_iso=$(epoch_to_iso "$sep")
  mtime_iso=$(epoch_to_iso "$(file_mtime_epoch "$path")")
  size=$(file_size "$path")
  jq -cn \
    --arg source "$src" \
    --arg id "$id" \
    --arg path "$path" \
    --arg started_at "$started_iso" \
    --arg mtime "$mtime_iso" \
    --argjson size_bytes "$size" \
    --arg ts_source "$tssrc" \
    '{source:$source,id:$id,path:$path,started_at:$started_at,mtime:$mtime,size_bytes:$size_bytes,ts_source:$ts_source}'
}

# ---------------------------------------------------------------------------
# Source enumeration: produce candidate "<started_epoch>\t<json>" rows on
# stdout (caller sorts + windows). Diagnostics to stderr. Returns 0 if the
# source was present and read; returns 1 if the source was missing/empty
# (caller emits the single stderr skip note).
# ---------------------------------------------------------------------------

# claude + pi share dir-scoped enumeration; $2 selects the extractor.
enumerate_dir_source() {
  src="$1"; root="$2"
  dir_has_files "$root" || return 1
  # Stable file ordering; -print0-free for Bash 3.2 portability. Filenames in
  # these roots are CLI-generated (no spaces/newlines), so a plain loop is safe.
  find "$root" -type f -name '*.jsonl' 2>/dev/null | sort | while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ -r "$f" ] || { echo "sessions.sh: unreadable, skipped: $f" >&2; continue; }
    if [ "$src" = "claude" ]; then
      info=$(extract_claude "$f")
    else
      info=$(extract_pi "$f")
    fi
    sep=${info%% *}
    rest=${info#* }
    tssrc=${rest%% *}
    id=${rest#* }
    rec=$(emit_record "$src" "$f" "$sep" "$tssrc" "$id")
    printf '%s\t%s\n' "$sep" "$rec"
  done
  return 0
}

# codex: prune by <YYYY>/<MM>/<DD> dirs, then read line 1 of each rollout.
enumerate_codex() {
  root="$1"
  dir_has_files "$root" || return 1
  # Only descend YYYY/MM/DD-shaped paths (C-05). find -path glob prunes.
  find "$root" -type f -name 'rollout-*.jsonl' \
    -path '*/[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9]/*' 2>/dev/null \
    | sort | while IFS= read -r f; do
      [ -n "$f" ] || continue
      [ -r "$f" ] || { echo "sessions.sh: unreadable, skipped: $f" >&2; continue; }
      if info=$(extract_codex "$f"); then
        sep=${info%% *}
        rest=${info#* }
        tssrc=${rest%% *}
        id=${rest#* }
        rec=$(emit_record "codex" "$f" "$sep" "$tssrc" "$id")
        printf '%s\t%s\n' "$sep" "$rec"
      fi
      # non-project rollouts: silently excluded (C-02), not a diagnostic.
    done
  return 0
}

# Count project-matched sessions for a source (used by `sources`). Echoes int.
count_source() {
  src="$1"
  case "$src" in
    claude) enumerate_dir_source claude "$CLAUDE_SESS_DIR" 2>/dev/null | grep -c . || true ;;
    pi)     enumerate_dir_source pi "$PI_SESS_DIR" 2>/dev/null | grep -c . || true ;;
    codex)  enumerate_codex "$CODEX_SESS_DIR" 2>/dev/null | grep -c . || true ;;
  esac
}

# ---------------------------------------------------------------------------
# Subcommand: sources (T019). One JSONL object per source: source/root/
# present/count.
# ---------------------------------------------------------------------------
cmd_sources() {
  for src in claude codex pi; do
    case "$src" in
      claude) root="$CLAUDE_SESS_DIR" ;;
      codex)  root="$CODEX_SESS_DIR" ;;
      pi)     root="$PI_SESS_DIR" ;;
    esac
    if dir_has_files "$root"; then
      present=true
      count=$(count_source "$src")
      [ -n "$count" ] || count=0
    else
      present=false
      count=0
    fi
    jq -cn \
      --arg source "$src" \
      --arg root "$root" \
      --argjson present "$present" \
      --argjson count "$count" \
      '{source:$source,root:$root,present:$present,count:$count}'
  done
  return 0
}

# ---------------------------------------------------------------------------
# Subcommand: list (T023). Union selected sources, window-filter on
# started_epoch, sort desc, emit JSONL. Diagnostics to stderr.
# ---------------------------------------------------------------------------
cmd_list() {
  source_sel="all"
  since_bound="24h"
  until_bound=""        # empty => now
  since_set=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --source)
        [ "$#" -ge 2 ] || die_usage "--source requires a value"
        source_sel="$2"; shift 2 ;;
      --source=*)
        source_sel="${1#--source=}"; shift ;;
      --since)
        [ "$#" -ge 2 ] || die_usage "--since requires a value"
        since_bound="$2"; since_set=1; shift 2 ;;
      --since=*)
        since_bound="${1#--since=}"; since_set=1; shift ;;
      --until)
        [ "$#" -ge 2 ] || die_usage "--until requires a value"
        until_bound="$2"; shift 2 ;;
      --until=*)
        until_bound="${1#--until=}"; shift ;;
      -*)
        die_usage "unknown flag: $1" ;;
      *)
        die_usage "unexpected argument: $1" ;;
    esac
  done

  case "$source_sel" in
    claude|codex|pi|all) : ;;
    *) die_usage "bad --source: $source_sel (want claude|codex|pi|all)" ;;
  esac

  ref_now=$(now_epoch)

  if ! since_epoch=$(bound_to_epoch "$since_bound" "$ref_now" start); then
    die_usage "unparseable --since: $since_bound"
  fi
  if [ -n "$until_bound" ]; then
    if ! until_epoch=$(bound_to_epoch "$until_bound" "$ref_now" end); then
      die_usage "unparseable --until: $until_bound"
    fi
  else
    until_epoch="$ref_now"
  fi

  # Mention of since_set keeps it referenced (default already applied above).
  [ "$since_set" -eq 0 ] && : # default 24h window in effect

  # Determine which sources to enumerate.
  case "$source_sel" in
    all) sel_list="claude codex pi" ;;
    *)   sel_list="$source_sel" ;;
  esac

  any_present=0
  raw=""
  for src in $sel_list; do
    case "$src" in
      claude) root="$CLAUDE_SESS_DIR" ;;
      codex)  root="$CODEX_SESS_DIR" ;;
      pi)     root="$PI_SESS_DIR" ;;
    esac
    if ! dir_has_files "$root"; then
      echo "sessions.sh: source '$src' missing or empty ($root) — skipped" >&2
      continue
    fi
    any_present=1
    case "$src" in
      claude) out=$(enumerate_dir_source claude "$root") || true ;;
      pi)     out=$(enumerate_dir_source pi "$root") || true ;;
      codex)  out=$(enumerate_codex "$root") || true ;;
    esac
    if [ -n "$out" ]; then
      if [ -n "$raw" ]; then
        raw="$raw
$out"
      else
        raw="$out"
      fi
    fi
  done

  # No selected source present at all → exit 3.
  if [ "$any_present" -eq 0 ]; then
    echo "sessions.sh: no source available" >&2
    exit 3
  fi

  # Empty enumeration → zero matches, exit 0 (C-07).
  [ -n "$raw" ] || return 0

  # Window filter on the leading epoch, then sort desc and strip the key.
  printf '%s\n' "$raw" | while IFS="$(printf '\t')" read -r ep rec; do
    [ -n "$ep" ] || continue
    if [ "$ep" -ge "$since_epoch" ] && [ "$ep" -le "$until_epoch" ]; then
      printf '%s\t%s\n' "$ep" "$rec"
    fi
  done | sort -t "$(printf '\t')" -k1,1nr | cut -f2-

  return 0
}

# ---------------------------------------------------------------------------
# Dispatch (T018).
# ---------------------------------------------------------------------------
main() {
  [ "$#" -ge 1 ] || die_usage "missing subcommand"
  sub="$1"; shift
  case "$sub" in
    sources)
      [ "$#" -eq 0 ] || die_usage "sources takes no options"
      cmd_sources ;;
    list)
      cmd_list "$@" ;;
    -h|--help|help)
      usage ;;
    *)
      die_usage "unknown subcommand: $sub" ;;
  esac
}

main "$@"
