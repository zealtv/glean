#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
usage:
  glean.sh init
  glean.sh ingest <src> [name]
  glean.sh ingest - <name>
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
    finding) shift; cmd_finding "$@" ;;
    context) shift; cmd_context "$@" ;;
    drop) shift; cmd_drop "$@" ;;
    status) shift; cmd_status "$@" ;;
    -h|--help|help|"") usage ;;
    *) die "unknown command '$cmd'" ;;
  esac
}

main "$@"
