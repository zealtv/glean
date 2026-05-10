# s47g-drop-status-sweep

**Outcome.** `drop`, `status`, and a new `sweep` command work cleanly against the flat-file shape. The old `ingest`/`ready`/`finding`/`context` subcommands are retired (clean break — nothing depends on them).

## Spec

### `drop <id> [reason...]`

- Locates `<id>` as either:
  - `findings/<id>.md`
  - `in/<id>` (file or directory)
  - `in/<id>.landing` (write-in-progress; treat as droppable too)
- Moves the located item to `dropped/<id>` (preserving file/dir nature).
- Writes `dropped/<id>.reason.md` with the reason text (or `Add the reason here.` stub if none).
- Refuses if already in `dropped/`.

### `status`

- Three sections: `in`, `findings`, `dropped`.
- For each, list entries (one per line, prefixed `- `). Empty sections show `(empty)`.
- For findings, list `<id>` (not the full filename). For inbox items, list as-is (preserving `.landing` suffixes so the user can see in-flight landings).

### `sweep [days]`

- Removes `dropped/` entries older than N days (default 14). `0` = purge all.
- Mirrors loom/nestlings `sweep`. Removes both the item and its `*.reason.md` sibling together.
- Print one line per removed item.

### Retirements

Remove the following commands and their helpers entirely:
- `cmd_ingest` (old, stub-creating version) — replaced by `s47c`'s new `cmd_ingest`.
- `cmd_ready` — subsumed by new `ingest` (no two-step).
- `cmd_finding` — replaced by `s47d`'s `cmd_capture`.
- `cmd_context` — `## Context` section in the finding body replaces the sibling file.
- Old `.scribbling` suffix handling in `strip_suffix` and `find_unique_dir` — replaced by `.landing` handling.

`usage` block matches the new command set exactly.

## Verify

- `drop` against a flat finding → `findings/<id>.md` moves to `dropped/<id>.md`, `dropped/<id>.reason.md` is written.
- `drop` against an in/ item (file or dir, with or without `.landing`) → moves to `dropped/`, reason written.
- `drop` of an already-dropped id → no-op with informative message.
- `status` shows three sections, lists entries, handles empty cases.
- `sweep 0` empties `dropped/`. `sweep 14` only removes items mtime older than 14 days.
- `sweep` cleans up reason files alongside their items.
- `glean.sh ingest` (old) and `glean.sh ready`/`finding`/`context` no longer exist — `unknown command` errors.
- `usage` matches: `init | ingest | capture | index | fetch | drop | status | sweep`.

## Touchpoints

- `glean.sh` — major surgery. `cmd_drop` updated for flat files; `cmd_status` updated for flat findings + `.landing` visibility; new `cmd_sweep`. Delete obsolete commands.
- `test.sh` (`s47h`) — drop/status/sweep tests; assert old commands fail.

## Consistency / staleness

- `usage` block — final form.
- README rewrite in `s47i`.

Waits on `s47b-finding-contract`. Best landed after `s47c`–`s47f` so the retirements happen in one clean pass without leaving the script in a half-state.
