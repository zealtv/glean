#!/usr/bin/env bash
# usage: ./install.sh <host-dir>
# Lays down a .glean/ at the host directory — a sanctioned standalone install
# for scopes not delivered by any bundle. Idempotent: re-running repairs
# glean.sh and README.md and re-seeds missing trays (via glean.sh init); it
# never touches findings or the host-customized distil.md (copied only when
# absent).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${1:?usage: install.sh <host-dir>}"
[ -d "$target" ] || { echo "no such host dir: $target" >&2; exit 1; }

dest="$target/.glean"
mkdir -p "$dest"
cp -f "$REPO_DIR/.glean/glean.sh" "$dest/glean.sh"
chmod +x "$dest/glean.sh"
cp -f "$REPO_DIR/README.md" "$dest/README.md"
if [ ! -e "$dest/distil.md" ] && [ -e "$REPO_DIR/.glean/distil.md" ]; then
  cp "$REPO_DIR/.glean/distil.md" "$dest/distil.md"
fi
"$dest/glean.sh" init

echo "installed $dest"
