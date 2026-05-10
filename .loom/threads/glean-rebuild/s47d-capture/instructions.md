# s47d-capture

**Outcome.** `scribble.sh capture <id>` reads stdin and lands a finding ready in one shot at `findings/<id>/finding.md`.

## Why

The dream skill (gremlin-side) distils a small note and pipes it into scribble. One shot — no separate `ingest`/`ready` two-step. Replaces the previously-suggested `ingest <id> -` form.

## Spec

- `scribble.sh capture <id>` reads stdin until EOF.
- Validates `<id>` (existing `validate_id` in `scribble.sh`).
- If `findings/<id>/` exists → error to stderr, exit 1 (do not silently overwrite). User can `drop` first if they want to replace.
- Otherwise: `mkdir -p findings/<id>/`, write stdin to `findings/<id>/finding.md`.
- Exit 0; print the resulting path on stdout.

## Touchpoints

- `scribble.sh` — new `capture` subcommand; add to `usage`. Decide what happens to the older `ingest` and `ready` subcommands (recommend: deprecate with a one-line note, or remove if nothing depends on them — check before removing).
- `README.md` — document `capture` and remove/update `ingest`/`ready` references.

## Verify

- `printf "# title\n\n## Claim\nfoo" | scribble.sh capture my-finding` creates `findings/my-finding/finding.md` with that body, prints the path, exits 0.
- Re-capture with same id → stderr error, exit 1, original file unchanged.
- Empty stdin → write empty `finding.md` (allowed, lets the user fill in later) — *or* refuse; pick one and document. Recommend allow.
- Invalid id → validation error.

## Consistency / staleness

- `usage`, `README.md`.
- `index` and `fetch` should immediately recognise a captured finding without re-init.
- Sweep for any docs that still reference the old `ingest`/`ready` flow.

Waits on `s47a-finding-shape`.
