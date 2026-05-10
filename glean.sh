#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
usage:
  glean.sh init
  glean.sh ingest <src> [name]
  glean.sh ingest - <name>
  glean.sh capture <id>
  glean.sh index
  glean.sh fetch [--all] <q...>
  glean.sh finding <finding-id>
  glean.sh context <finding-id>
  glean.sh drop <id> [reason...]
  glean.sh status
USAGE
}

die() {
  echo "error: $*" >&2
  exit 1
}

find_repo_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/.glean" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

require_glean() {
  REPO_ROOT="$(find_repo_root || true)"
  [[ -n "${REPO_ROOT:-}" ]] || die "could not find .glean/ in this directory or any parent"
  GLEAN_DIR="$REPO_ROOT/.glean"
}

validate_id() {
  local id="$1"
  [[ "$id" =~ ^[A-Za-z0-9._-]+$ ]] || die "invalid id '$id' (use letters, numbers, ., _, -)"
  [[ "$id" != *"/"* ]] || die "id cannot contain /"
}

strip_suffix() {
  local name="$1"
  printf '%s\n' "${name%.scribbling}"
}

find_unique_dir() {
  local id="$1"
  local matches=()
  mapfile -t matches < <(find "$GLEAN_DIR" -mindepth 1 -maxdepth 2 -type d \( -name "$id" -o -name "$id.scribbling" \) -print)
  if (( ${#matches[@]} == 0 )); then
    return 1
  fi
  if (( ${#matches[@]} > 1 )); then
    printf '%s\n' "${matches[@]}" >&2
    die "multiple items found for id '$id'"
  fi
  printf '%s\n' "${matches[0]}"
}

ensure_absent() {
  local id="$1"
  if find_unique_dir "$id" >/dev/null 2>&1; then
    die "item '$id' already exists"
  fi
}

cmd_init() {
  mkdir -p .glean/in .glean/findings .glean/dropped
  if [[ ! -f .glean/distil.md ]]; then
    cat > .glean/distil.md <<'DISTIL'
# Distil

This is the local brief for distillation in this glean.

Distil is the act of turning raw material in `in/` into findings (or drops).
Edit this file freely — the protocol doesn't care what you write here.

## What a finding looks like

A finding is one markdown file at `findings/<id>.md`:

- **Title** — first line, an H1 (`# Some claim`). Required.
- **Description** — first non-empty line after the title. One sentence.
  Surfaces in `INDEX.md`; an agent reads it to decide relevance.
- **Body** — free markdown. Common sections (all optional):
  - `## Why` — motivation, source, the experience that earned this finding.
  - `## Triggers` — phrases, topics, or symptoms that should bring this
    finding to mind. `fetch` searches this by default.
  - `## Associations` — wikilinks to related findings: `- [[other-id]]`.
  - `## Context` — examples, references, longer notes.

## Posture

- Prefer associating or revising over creating. The tray stays small and few.
- Distillation produces findings worth carrying forward. If material doesn't
  earn that, drop it with a reason.
- An item leaving `in/` is the signal it has been distilled — either a
  finding changed, or it landed in `dropped/`.

## Local notes

(Anything host-specific goes here.)
DISTIL
  fi
  echo "initialized .glean/"
}

cmd_ingest() {
  require_glean
  local src="${1:-}"
  [[ -n "$src" ]] || die "ingest requires <src> [name]"
  shift
  local name="${1:-}"

  if [[ "$src" == "-" ]]; then
    [[ -n "$name" ]] || die "ingest from stdin requires a name"
    validate_id "$name"
    local dest="$GLEAN_DIR/in/$name.md"
    local landing="$dest.landing"
    [[ ! -e "$dest" ]] || die "in/$name.md already exists"
    [[ ! -e "$landing" ]] || die "in/$name.md.landing already exists (clean up?)"
    cat > "$landing"
    mv "$landing" "$dest"
    echo "$dest"
    return 0
  fi

  [[ -e "$src" ]] || die "source not found: $src"
  if [[ -z "$name" ]]; then
    name="$(basename "$src")"
  fi
  validate_id "$name"
  local dest="$GLEAN_DIR/in/$name"
  local landing="$dest.landing"
  [[ ! -e "$dest" ]] || die "in/$name already exists"
  [[ ! -e "$landing" ]] || die "in/$name.landing already exists (clean up?)"

  if [[ -d "$src" ]]; then
    cp -R "$src" "$landing"
  else
    cp "$src" "$landing"
  fi
  mv "$landing" "$dest"
  echo "$dest"
}

extract_title() {
  local line
  line="$(grep -m1 '^# ' "$1" 2>/dev/null || true)"
  printf '%s' "${line#\# }"
}

extract_description() {
  awk '
    /^# / && !found_title { found_title=1; next }
    found_title && /^[[:space:]]*$/ { next }
    found_title && /^#/ { exit }
    found_title { print; exit }
  ' "$1"
}

extract_triggers() {
  awk '
    /^## Triggers[[:space:]]*$/ { in_section=1; next }
    in_section && /^## / { exit }
    in_section { print }
  ' "$1"
}

cmd_index() {
  require_glean
  local dir="$GLEAN_DIR/findings"
  local idx="$dir/INDEX.md"
  mkdir -p "$dir"

  local files=()
  mapfile -t files < <(find "$dir" -mindepth 1 -maxdepth 1 -type f -name '*.md' ! -name 'INDEX.md' 2>/dev/null | sort)

  {
    echo "<!-- auto-generated; run glean.sh index to refresh -->"
    echo
    local f id title desc
    for f in "${files[@]}"; do
      id="$(basename "$f" .md)"
      title="$(extract_title "$f")"
      desc="$(extract_description "$f")"
      [[ -n "$title" ]] || title="$id"
      [[ -n "$desc" ]] || desc="(no description)"
      echo "- [[$id]] — $title — $desc"
    done
  } > "$idx"

  echo "$idx"
}

cmd_fetch() {
  require_glean
  local mode="strict"
  if [[ "${1:-}" == "--all" || "${1:-}" == "-a" ]]; then
    mode="all"
    shift
  fi
  (( $# > 0 )) || die "fetch requires <q...>"
  local terms=("$@")

  local dir="$GLEAN_DIR/findings"
  local files=()
  mapfile -t files < <(find "$dir" -mindepth 1 -maxdepth 1 -type f -name '*.md' ! -name 'INDEX.md' 2>/dev/null | sort)

  local f haystack term
  for f in "${files[@]}"; do
    if [[ "$mode" == "all" ]]; then
      haystack="$(cat "$f")"
    else
      local id title desc triggers
      id="$(basename "$f" .md)"
      title="$(extract_title "$f")"
      desc="$(extract_description "$f")"
      triggers="$(extract_triggers "$f")"
      haystack="$id"$'\n'"$title"$'\n'"$desc"$'\n'"$triggers"
    fi

    for term in "${terms[@]}"; do
      if printf '%s' "$haystack" | grep -iqF -- "$term"; then
        printf '%s\n' "$f"
        break
      fi
    done
  done
}

cmd_capture() {
  require_glean
  local id="${1:-}"
  [[ -n "$id" ]] || die "capture requires <id>"
  validate_id "$id"

  local dest="$GLEAN_DIR/findings/$id.md"
  [[ ! -e "$dest" ]] || die "findings/$id.md already exists"
  [[ ! -e "$GLEAN_DIR/findings/$id" ]] || die "findings/$id already exists (old-shape directory)"

  mkdir -p "$GLEAN_DIR/findings"

  if [[ -t 0 ]]; then
    cat > "$dest" <<'TEMPLATE'
# <title>

<single-line description>

## Why

## Triggers

## Associations

## Context
TEMPLATE
  else
    cat > "$dest"
  fi

  echo "$dest"
}

cmd_finding() {
  require_glean
  local id="${1:-}"
  [[ -n "$id" ]] || die "finding requires <finding-id>"
  validate_id "$id"
  [[ ! -e "$GLEAN_DIR/findings/$id" ]] || die "finding '$id' already exists"

  local dir="$GLEAN_DIR/findings/$id"
  mkdir -p "$dir"
  cat > "$dir/finding.md" <<'FINDING'
# Finding title

## Claim
State the current guidance.

## Why
Why this seems worth carrying.

## Scope
Where this applies, or does not apply.

## Associations
- ../related-finding/
FINDING
  echo "finding $dir"
}

cmd_context() {
  require_glean
  local id="${1:-}"
  [[ -n "$id" ]] || die "context requires <finding-id>"
  validate_id "$id"
  local dir="$GLEAN_DIR/findings/$id"
  [[ -d "$dir" ]] || die "finding '$id' not found"

  local file="$dir/context.md"
  if [[ ! -e "$file" ]]; then
    cat > "$file" <<'CONTEXT'
# Context

Use this file for sources, notes, and examples.

This file supports progressive disclosure. Keep the core guidance in `finding.md`.
CONTEXT
  fi
  echo "context $file"
}

cmd_drop() {
  require_glean
  local id="${1:-}"
  shift || true
  [[ -n "$id" ]] || die "drop requires <id>"
  validate_id "$id"

  local src
  src="$(find_unique_dir "$id" || true)"
  [[ -n "$src" ]] || die "item '$id' not found"

  case "$src" in
    "$GLEAN_DIR/dropped"/*)
      echo "already dropped: $id"
      return 0
      ;;
  esac

  local canonical
  canonical="$(strip_suffix "$(basename "$src")")"
  local dest="$GLEAN_DIR/dropped/$canonical"
  [[ ! -e "$dest" ]] || die "destination already exists: $dest"
  mv "$src" "$dest"

  local reason="$GLEAN_DIR/dropped/$canonical.reason.md"
  {
    echo "# why $canonical was dropped"
    echo
    if (( $# > 0 )); then
      printf '%s\n' "$*"
    else
      echo "Add the reason here."
    fi
  } > "$reason"

  echo "dropped $canonical"
}

print_dirs() {
  local dir="$1"
  if find "$dir" -mindepth 1 -maxdepth 1 -type d | grep -q .; then
    find "$dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | sed 's/^/- /'
  else
    echo "(empty)"
  fi
}

cmd_status() {
  require_glean
  echo "in"
  print_dirs "$GLEAN_DIR/in"
  echo
  echo "findings"
  print_dirs "$GLEAN_DIR/findings"
  echo
  echo "dropped"
  print_dirs "$GLEAN_DIR/dropped"
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    init) shift; cmd_init "$@" ;;
    ingest) shift; cmd_ingest "$@" ;;
    capture) shift; cmd_capture "$@" ;;
    index) shift; cmd_index "$@" ;;
    fetch) shift; cmd_fetch "$@" ;;
    finding) shift; cmd_finding "$@" ;;
    context) shift; cmd_context "$@" ;;
    drop) shift; cmd_drop "$@" ;;
    status) shift; cmd_status "$@" ;;
    -h|--help|help|"") usage ;;
    *) die "unknown command '$cmd'" ;;
  esac
}

main "$@"
