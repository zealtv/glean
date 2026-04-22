#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
usage:
  scribble.sh init
  scribble.sh ingest <item-id>
  scribble.sh ready <item-id>
  scribble.sh finding <finding-id>
  scribble.sh context <finding-id>
  scribble.sh drop <id> [reason...]
  scribble.sh status
USAGE
}

die() {
  echo "error: $*" >&2
  exit 1
}

find_repo_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/.scribble" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

require_scribble() {
  REPO_ROOT="$(find_repo_root || true)"
  [[ -n "${REPO_ROOT:-}" ]] || die "could not find .scribble/ in this directory or any parent"
  SCRIBBLE_DIR="$REPO_ROOT/.scribble"
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
  mapfile -t matches < <(find "$SCRIBBLE_DIR" -mindepth 1 -maxdepth 2 -type d \( -name "$id" -o -name "$id.scribbling" \) -print)
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
  mkdir -p .scribble/in .scribble/findings .scribble/dropped
  if [[ ! -f .scribble/dream.md ]]; then
    cat > .scribble/dream.md <<'DREAM'
# Dream

Dream works across the whole Scribble surface.

It reads what has arrived in `in/`, compares it with what already lives in `findings/`, and either sharpens the live surface or lets material fall away.

Dream should keep Scribble small, legible, and revisable.

## Baseline posture

- Do not force synthesis.
- Do not mistake compression for understanding.
- Do not create a new finding when association or revision is enough.
- Do not let `findings/` grow into a heap.
- Do not carry forward material that does not improve judgment.

## Default movement

When dream acts on an item in `in/`, that item should leave `in/`.

Successful digestion changes `findings/`.
Unusable, weak, malformed, or withdrawn material goes to `dropped/`.

Items should remain in `in/` only while still awaiting digestion.

## Preferred order

When working on material in `in/`, prefer this order:

1. associate it with existing findings
2. revise an existing finding if that is enough
3. create a new finding only when needed
4. drop the item if it does not merit carry-forward
DREAM
  fi
  echo "initialized .scribble/"
}

cmd_ingest() {
  require_scribble
  local id="${1:-}"
  [[ -n "$id" ]] || die "ingest requires <item-id>"
  validate_id "$id"
  ensure_absent "$id"

  local dir="$SCRIBBLE_DIR/in/$id.scribbling"
  mkdir -p "$dir"
  cat > "$dir/note.md" <<'NOTE'
# Note

Add the incoming material here.
NOTE
  echo "ingest $dir"
}

cmd_ready() {
  require_scribble
  local id="${1:-}"
  [[ -n "$id" ]] || die "ready requires <item-id>"
  validate_id "$id"

  local src="$SCRIBBLE_DIR/in/$id.scribbling"
  local dest="$SCRIBBLE_DIR/in/$id"
  [[ -d "$src" ]] || die "incomplete item not found: $src"
  [[ ! -e "$dest" ]] || die "ready item already exists: $dest"
  mv "$src" "$dest"
  echo "ready $dest"
}

cmd_finding() {
  require_scribble
  local id="${1:-}"
  [[ -n "$id" ]] || die "finding requires <finding-id>"
  validate_id "$id"
  [[ ! -e "$SCRIBBLE_DIR/findings/$id" ]] || die "finding '$id' already exists"

  local dir="$SCRIBBLE_DIR/findings/$id"
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
  require_scribble
  local id="${1:-}"
  [[ -n "$id" ]] || die "context requires <finding-id>"
  validate_id "$id"
  local dir="$SCRIBBLE_DIR/findings/$id"
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
  require_scribble
  local id="${1:-}"
  shift || true
  [[ -n "$id" ]] || die "drop requires <id>"
  validate_id "$id"

  local src
  src="$(find_unique_dir "$id" || true)"
  [[ -n "$src" ]] || die "item '$id' not found"

  case "$src" in
    "$SCRIBBLE_DIR/dropped"/*)
      echo "already dropped: $id"
      return 0
      ;;
  esac

  local canonical
  canonical="$(strip_suffix "$(basename "$src")")"
  local dest="$SCRIBBLE_DIR/dropped/$canonical"
  [[ ! -e "$dest" ]] || die "destination already exists: $dest"
  mv "$src" "$dest"

  local reason="$SCRIBBLE_DIR/dropped/$canonical.reason.md"
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
  require_scribble
  echo "in"
  print_dirs "$SCRIBBLE_DIR/in"
  echo
  echo "findings"
  print_dirs "$SCRIBBLE_DIR/findings"
  echo
  echo "dropped"
  print_dirs "$SCRIBBLE_DIR/dropped"
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    init) shift; cmd_init "$@" ;;
    ingest) shift; cmd_ingest "$@" ;;
    ready) shift; cmd_ready "$@" ;;
    finding) shift; cmd_finding "$@" ;;
    context) shift; cmd_context "$@" ;;
    drop) shift; cmd_drop "$@" ;;
    status) shift; cmd_status "$@" ;;
    -h|--help|help|"") usage ;;
    *) die "unknown command '$cmd'" ;;
  esac
}

main "$@"
