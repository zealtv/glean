# s47c-fetch

**Outcome.** `scribble.sh fetch <query...>` returns paths of findings whose id, title, `## Claim`, `## Scope`, or `## Triggers` content matches any query term (case-insensitive substring).

## Why

The prefetch seam. The agent reads `INDEX.md` always; when something looks relevant it runs `fetch` to pull paths, then reads those finding bodies. This is what makes scribble feel like memory rather than a filing cabinet.

## Spec

- `scribble.sh fetch <query...>` — accepts one or more query terms.
- Match: case-insensitive substring against any of {id, title, Claim body, Scope body, Triggers body}. Match if **any** term matches **any** field.
- Output: one finding path per line on stdout, sorted by id, deduplicated.
- No matches → exit 0, empty stdout.
- No queries → error to stderr, exit 1.

## Touchpoints

- `scribble.sh` — new `fetch` subcommand; add to `usage`.
- `README.md` — document the command, the match fields, and the substring/case-insensitive semantics.

## Verify

- Findings with distinct claim/scope/trigger words; fetch by each term; correct subset returned.
- Multi-term query returns the union.
- Case-insensitive: `fetch FOO` matches `foo`.
- ID match works (so `fetch <known-id>` is a direct lookup).
- No-match → empty output, exit 0.

## Consistency / staleness

- `usage`, `README.md` Commands.
- If older `finding`/`context` subcommands existed for similar purposes (see `scribble.sh`), decide explicitly: keep, deprecate, or replace. Note in this stitch's notes.

Waits on `s47a-finding-shape`.
