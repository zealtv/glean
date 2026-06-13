# recall-by-trigger

**Outcome.** Glean gains a recall primitive: given a block of text, return the
findings whose `## Triggers` phrases occur in that text. This is the inverse of
`fetch` (which treats the query as the needle and the finding as the haystack)
and is what callers need for automatic, trigger-driven recall at reply time.

## Why

Field evidence from a live gremlin (roo: 10 findings, ~10MB of run.log) showed
`fetch` is essentially never used for recall — only the always-loaded `INDEX.md`
catalog and hand-promoted symlinks actually reach the model. The `## Triggers`
section therefore does no work at recall time. A host that wants deterministic,
trigger-driven recall has no primitive to build on. `recall` is that primitive.

## Contract

- `glean.sh recall [text...]` — text from args, or stdin if none.
- For each finding, parse `## Triggers` into phrases (bullet lines and/or
  comma-separated), case-insensitive substring match each phrase against the
  input text. Emit the finding path once if any phrase matches.
- Triggers stay optional. A finding with no triggers never auto-recalls but
  still surfaces via `INDEX.md`. Document that triggers now power recall.
- Keep glean pure: no new folders, no ledger. One new read-only subcommand.

## Done when

- `recall` added to usage, dispatch, README, and distil.md.
- Parses the real-world bullet-list trigger format.
- Verified against a sample of real findings.
