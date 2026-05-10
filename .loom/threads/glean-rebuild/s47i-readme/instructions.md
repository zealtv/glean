# s47i-readme

**Outcome.** `README.md` and `AGENTS.md` document glean's new shape end-to-end. Ships last so it doesn't document fiction.

## Sections to cover (README.md)

1. **What glean is** — a tiny file-based memory protocol; you glean a finding from larger work; the filesystem is the protocol.
2. **The directory shape** — `.glean/{in/, findings/, dropped/, distil.md}`. What each is for.
3. **The finding contract** — title (H1, required) + single-line description + free body. Suggested optional sections (`## Why`, `## Triggers`, `## Associations`, `## Context`). Wikilink associations. Editable in place.
4. **Disclosure layers** — `INDEX.md` is always-loaded by hosts (via symlink to a host's context surface); finding bodies are fetched on demand; promotion to always-loaded is the host's call (briefly mention; don't bake it in).
5. **Commands** — `init`, `ingest`, `capture`, `index`, `fetch`, `drop`, `status`, `sweep`. One short paragraph each, mirroring `usage`.
6. **Distillation** — distil is the act, governed by the host's editable `distil.md` brief. Glean provides scaffolding; judgment is the agent's. No `distil` command.
7. **Family** — a one-liner pointing at loom, nestlings, groundhog, gremlin. Glean fits the same aesthetic (small, file-based, no metadata files).
8. **What glean is not** — not a database, not an LLM, not a search engine. A markdown filing cabinet with a tiny parse contract.

## Sections to cover (AGENTS.md)

Currently a one-liner: `simplicity, clarity, extensibility`. Keep that ethos. Add a short section reinforcing:
- No frontmatter, no YAML, no JSON.
- The protocol is unaware of any consumer.
- Findings are small, few, editable in place.

## Verify

Read README cold. A new contributor (or model) should be able to answer:
- What does a finding look like?
- How do I add one?
- How does the agent find them later?
- Why isn't this a database?
- How does this fit with the rest of the family?
- How is distillation customised per host?

Every command listed actually exists in `glean.sh`. Every finding-shape claim matches what `index`/`fetch` actually do.

## Touchpoints

- `~/repos/glean/README.md` — full rewrite.
- `~/repos/glean/AGENTS.md` — light expansion aligned with new shape.
- `~/repos/glean/.loom/README.md` is loom's own README (vendored) — leave alone.

## Consistency / staleness

- All earlier `ingest`/`ready`/`finding`/`context` language is gone from the codebase by this point — README must not resurrect it.
- Cross-check terminology: glean, finding, distil. Not gleaning, not scribble, not dream.
- Family-name list should match the current set: loom, nestlings, groundhog, gremlin.

Waits on `s47a`–`s47h`. Otherwise documents fiction.
