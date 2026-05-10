# s47a-finding-shape

**Outcome.** A finding is plain markdown. The body uses a fixed set of optional H2 sections — `Claim`, `Why`, `Scope`, `Triggers`, `Associations` — and nothing else parses as structured. No frontmatter, no YAML, no JSON sidecar.

## Spec

- A finding lives at `findings/<id>/finding.md`.
- The first non-blank line is the title (level-1 heading).
- The body may contain any of (all optional, any order):
  - `## Claim` — one-line summary.
  - `## Why` — motivation / rationale.
  - `## Scope` — when this applies.
  - `## Triggers` — phrases or topics that should surface this finding (fetch matches against this).
  - `## Associations` — links to other findings, contexts, or external refs.
- Free prose outside these sections is allowed and ignored by `index`/`fetch`.

## Touchpoints

- Finding template (whichever file scribble's `init` seeds; check `scribble.sh` `init` action).
- `README.md` — document the section contract under a "Finding shape" heading.
- `scribble.sh` `usage` — no surface change here; `index`/`fetch`/`capture` come in later children.

## Verify

- Init a fresh scribble; the seeded template includes all five sections (or a documented subset) and a `Triggers` section.
- A hand-written finding with only `## Claim` parses fine (sections are optional).
- A finding with unknown sections (e.g. `## Foo`) does not error — they're just ignored.

## Consistency / staleness

- Existing scribble docs (`README.md`, `AGENTS.md`) — sweep for any reference to YAML, frontmatter, or earlier shapes; rewrite or remove.
- `scribble.sh` source — confirm no parsing of metadata other than these sections; flag anything inconsistent for follow-up.
- Gremlin's `stage-10-memory.waiting/instructions.md` references this contract; cross-check wording.

This stitch does not implement parsing — `s47b` and `s47c` will. It just defines the contract everyone else builds against.
