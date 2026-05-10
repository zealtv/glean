# plain-md-finding-protocol

**Outcome.** Scribble's findings are plain markdown with a section-based contract; `index`, `fetch`, and `capture` are the workbench. No YAML, no frontmatter — just `## Claim`, `## Why`, `## Scope`, `## Triggers`, `## Associations` (all optional, fixed set).

## Why

Gremlin's stage-10 memory thread vendors scribble as the memory protocol. The integration relies on:

- always-loaded `INDEX.md` (so the agent knows what findings exist),
- on-demand `finding.md` (fetched by name or by trigger match),
- a one-shot `capture` for landing distilled notes.

Plain markdown keeps findings readable by humans and by every model with no parser. The section headings are the contract — `index` and `fetch` parse them directly.

## Children (claim in alphabetical order; `s47a` ships first)

- `s47a-finding-shape` — section contract + template + README parse rules.
- `s47b-index` — `scribble.sh index` writes `findings/INDEX.md`.
- `s47c-fetch` — `scribble.sh fetch <query...>` returns matching paths.
- `s47d-capture` — `scribble.sh capture <id>` reads stdin and lands a finding.
- `s47e-readme` — README documents disclosure layers and the dream-as-item recipe.

`s47b`, `s47c`, `s47d`, `s47e` all wait on `s47a` (contract must be settled first). `s47e` additionally waits on `s47b`–`s47d` (otherwise it documents fiction).

## Downstream

- Gremlin's `stage-10-memory.waiting/` thread depends on this entire goal stitch. Each gremlin-side child (`s48-vendor-scribble`, `s49-init-wires-scribble`, `s50-dream-skill`, …) waits for the corresponding scribble surface to land.

## Cross-cutting checks

Each child stitch ends with: docs updated, scribble.sh `usage` text updated, and a sweep for staleness (older `ingest`/`ready`/`finding`/`context` subcommand language that the new shape replaces or coexists with — decide explicitly per stitch).
