# s47b-finding-contract

**Outcome.** The parser contract for findings is settled and documented. A finding is one markdown file at `findings/<id>.md`. The parser only needs two things: a title and a single-line description. Everything else is free prose.

This is a spec stitch — no code lands here. The contract it settles is what `s47c`–`s47g` build against.

## The contract

- **Title** — first `# ` line in the file. If absent, parsers fall back to `<id>`.
- **Description** — first non-empty, non-heading line *after* the title. Single line. If absent, INDEX shows `(no description)`.
- **Body** — anything else. Free prose. Parsers don't care.
- **Suggested optional H2 sections** (from `distil.md` brief, not enforced):
  - `## Why` — motivation.
  - `## Triggers` — phrases/topics. `fetch` searches this by default.
  - `## Associations` — wikilinks: `- [[other-id]]`.
  - `## Context` — examples, references, longer notes.
- **Associations format**: wikilinks `- [[id]]`. Greppable; agent resolves by appending `.md`.
- **Mutability**: findings are editable in place. `drop` is retirement only.

## Verify

- `distil.md` template (already seeded by `s47a` `cmd_init`) describes the contract clearly.
- A hand-written finding with only a title parses without error (description shows as `(no description)` later in `s47e`).
- A finding with unknown sections (e.g. `## Foo`) is fine — body is free prose.
- The contract is tight enough that `s47c`–`s47g` can be implemented unambiguously.

## Touchpoints

- `.glean/distil.md` template inside `glean.sh` `cmd_init` — already aligned with this contract.
- This stitch's `instructions.md` is the canonical reference until `s47i` lifts it into the README.

## Consistency / staleness

- No old shape language survives in `glean.sh` `cmd_init` (already done in `s47a`).
- `AGENTS.md` and `README.md` still describe the old shape; they get rewritten in `s47i`.
