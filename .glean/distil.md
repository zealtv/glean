# Distil

This is the local brief for distillation in this glean.

Distil is the act of turning raw material in `in/` into findings (or drops).
Edit this file freely — the protocol doesn't care what you write here.

## Posture

Glean stays small, legible, and revisable. Keep it that way.

- Do not force synthesis.
- Do not mistake compression for understanding.
- Do not create a new finding when association or revision is enough.
- Do not let `findings/` grow into a heap.
- Do not carry forward material that does not improve judgment.

A heap of findings is just another inbox. The value of memory comes from the
discipline of distillation, not the volume of capture.

## Default movement

When you distil an item in `in/`, the item should leave `in/`.

- A finding changed → digestion succeeded; the inbox item is dropped.
- Material doesn't earn its place → the inbox item goes to `dropped/` with
  a reason.

Items remain in `in/` only while still awaiting distillation.

## Preferred order

When working on material in `in/`, prefer in this order:

1. **Associate** it with existing findings.
2. **Revise** an existing finding if that is enough.
3. **Create** a new finding only when needed.
4. **Drop** the item if it does not merit carry-forward.

## What a finding looks like

A finding is one markdown file at `findings/<id>.md`:

- **Title** — first line, an H1 (`# Some claim`). Required.
- **Description** — first non-empty line after the title. One sentence.
  Surfaces in `INDEX.md`; an agent reads it to decide relevance.
- **Body** — free markdown. Common sections (all optional):
  - `## Why` — motivation, source, the experience that earned this finding.
  - `## Triggers` — phrases, topics, or symptoms that should bring this
    finding to mind. `fetch` searches this by default.
  - `## Associations` — wikilinks to related findings: `- [[other-id]]`.
  - `## Context` — examples, references, longer notes.

## Local notes

(Anything host-specific goes here.)
