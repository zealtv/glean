# s47c-ingest

**Outcome.** `glean.sh ingest <src> [name]` lands raw material in `in/` using the family-wide `.landing` write-protection suffix. Mirrors nestlings exactly. Replaces the old `ingest`/`ready` two-step.

## Spec

- `glean.sh ingest <src> [name]` — copies or moves `<src>` (file or directory) into `in/[<name>]`.
- During the copy/move, the destination carries the `.landing` suffix: `in/<name>.landing/` (or `in/<name>.landing` for a single file). When the operation completes, atomic rename strips the suffix.
- `<name>` defaults to `basename(<src>)`.
- `<src>` accepts `-` to read stdin. With stdin, default `<name>` is required (we have nothing to derive it from); land as `in/<name>.md`.
- Validates `<name>` via `validate_id`.
- Refuses if `in/<name>` already exists (without suffix). Use `drop` first.
- Prints the resulting path on stdout.

## Mechanics

- Mirrors nestlings' `.landing` pattern: write-protect during landing, atomic rename when ready.
- `find_unique_dir` (existing helper) needs updating to recognize `.landing` suffix as well as `.scribbling` (which gets retired in `s47g`). Or just sweep `.scribbling` references out as part of this stitch since the old `ingest`/`ready` go away too.

## Verify

- `glean.sh ingest some/file.md` → file lives at `.glean/in/file.md`. No `.landing` residue.
- `glean.sh ingest some/dir foo` → directory at `.glean/in/foo/`. No residue.
- `echo "raw" | glean.sh ingest - foo` → `.glean/in/foo.md` contains "raw".
- `glean.sh ingest - foo` with no stdin and no source → error.
- Conflict on existing `in/<name>` → error to stderr, exit 1, original untouched.
- During the copy of a large directory, an interrupted run leaves only `.landing` (which subsequent commands ignore) — never a half-baked `in/<name>`.

## Touchpoints

- `glean.sh` — replace existing `cmd_ingest` (which created stub `note.md` files, old shape) with the new signature; remove `cmd_ready` (subsumed). Update `usage`.
- Helpers: `strip_suffix` should handle `.landing` (and stop handling `.scribbling` once `cmd_ready` is gone — coordinate with `s47g`).
- `test.sh` (`s47h`) — add ingest tests.

## Consistency / staleness

- `usage` block — replace `ingest <item-id>` and `ready <item-id>` with single `ingest <src> [name]` line.
- README and AGENTS still mention old shape; they get rewritten in `s47i`.
- No "for gremlin" branches.

Waits on `s47b-finding-contract`.
