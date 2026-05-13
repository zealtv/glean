# status-refreshes-index

**Outcome.** `glean.sh status` rebuilds `INDEX.md` as part of its job, so
humans (and agents) running `status` always leave with a fresh catalog.

This stitch and `fetch-staleness-warning` together cover the two drift
paths: `fetch` detects staleness during agent flow without changing reads,
`status` actively repairs it during deliberate inspection. Neither is
redundant with the other — they serve different surfaces.

## Scope

- In `cmd_status`, call `cmd_index` (or equivalent) before printing the tray
  summary, so the listed counts and the on-disk `INDEX.md` are guaranteed
  consistent at the moment `status` returns.
- The index rebuild reuses the atomic landing-write from
  `landing-atomic-index/`. Do not bypass it.
- `status` output gains no new lines unless something noteworthy changed.
  A silent refresh is fine; loud refresh is not.

## Constraints

- The status command stays cheap. The index rebuild is O(findings), which
  is acceptable on a small corpus and matches what runner startup does
  already in hosts.
- `status` must not error out if the index rebuild fails — print a single
  stderr warning and continue with the tray summary. The tray state is
  what the human came to see.
- Order matters: rebuild first, then list trays. A reader who runs
  `status` and then opens `INDEX.md` should see consistent state.

## Dependencies

- Depends on `landing-atomic-index/`. Tie that first so `status` inherits
  atomic writes for free.

## Verification

1. Hand-edit `INDEX.md` to a clearly wrong line (e.g. delete every bullet).
   Run `glean.sh status` — confirm `INDEX.md` is restored to a correct
   catalog and `status` printed normally.
2. Add a new finding by hand without running `index`. Run `status` —
   confirm `INDEX.md` now lists the new finding.
3. Make `findings/INDEX.md` unwritable. Run `status` — confirm one stderr
   warning about the failed index refresh and that the tray summary still
   prints to stdout.
4. Run `status` twice in a row with no changes between — second run
   produces an `INDEX.md` byte-identical to the first.
