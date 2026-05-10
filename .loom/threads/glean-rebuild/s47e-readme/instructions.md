# s47e-readme

**Outcome.** `README.md` documents the plain-markdown finding protocol end-to-end: shape, disclosure layers, commands, and the dream-as-item composition recipe.

## Sections to add or revise

1. **Finding shape** — section contract from `s47a` (H2s: `Claim`, `Why`, `Scope`, `Triggers`, `Associations`); plain markdown; no frontmatter.
2. **Disclosure layers** — `INDEX.md` is always carried by the agent; `finding.md` is fetched by query; deeper context (anything else inside the finding dir) is read by hand. Promotion to always-loaded is by symlink from a host's `context/` directory (gremlin-side concern; describe briefly).
3. **Commands** — `init`, `index`, `fetch`, `capture`, `drop`, `status` (and any retained legacy commands). Mirror `usage`.
4. **Dream-as-item recipe** — gremlin-side composition example: `groundhog → nest → dream skill → scribble.sh capture`. Brief; the gremlin docs are the primary home, scribble just acknowledges the integration so the moving parts are findable.
5. **What scribble is not** — not a database, not an LLM, not a search engine; a markdown filing cabinet with a parse contract.

## Touchpoints

- `README.md` — major rewrite of the relevant sections.
- `AGENTS.md` — sweep for inconsistencies; align or remove the ones that conflict with the new shape.

## Verify

- Read README cold; can a new contributor (or model) understand:
  - what a finding looks like,
  - how to add one,
  - how the agent finds them later,
  - why this isn't a database,
  - how it integrates with a gremlin?
- Every command listed actually exists in `scribble.sh`.

## Consistency / staleness

- All earlier ingest/ready/finding/context subcommand language — reconcile based on the decisions in `s47c`/`s47d`.
- Cross-check terminology with gremlin's `stage-10-memory.waiting/instructions.md`.

Waits on `s47a`–`s47d` (otherwise documents fiction).
