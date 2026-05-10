# s47j-update-gremlin-thread

**Outcome.** Gremlin's waiting thread reflects glean's new name, paths, vocabulary, and shape. Unblocks gremlin's `s48`–`s52`.

This is the only cross-repo edit the rebuild does. The stitch lives in glean's loom because it's a *consequence* of glean's rename; its edits are entirely inside the gremlin repo.

## Touchpoints

- `~/repos/gremlin/.loom/threads/stage-10-memory.waiting/instructions.md`

The folder name `stage-10-memory.waiting/` itself stays put — it's named after gremlin's stage, not the consumed protocol.

## Mechanical replacements

- `scribble` → `glean` (project name throughout)
- `.scribble/` → `.glean/` (vendored dotdir paths)
- `dream` (the skill) → `distil` (and `skills/dream.md` → `skills/distil.md`)
- `dream.md` (the brief) → `distil.md`
- `findings/<id>/finding.md` → `findings/<id>.md` (flat-file shape)
- `~/repos/scribble/.loom/threads/plain-md-finding-protocol/` → `~/repos/glean/.loom/threads/glean-rebuild/`
- Stitch ids that reference scribble surfaces: `s48-vendor-scribble` → `s48-vendor-glean`, etc.

## Conceptual updates

Replace any text describing the **old contract** (five fixed H2 sections: `Claim`/`Why`/`Scope`/`Triggers`/`Associations`) with the **new contract**:
- Title (H1, required) + single-line description as the parser contract.
- `## Why`, `## Triggers`, `## Associations`, `## Context` as suggested-but-optional sections in the brief.

Add references to:
- Capture's TTY-template fallback (`capture` with no pipe seeds a template).
- `fetch --all` flag (whole-file mode).
- Family-wide `.landing` write-protection suffix on ingest.

Preserve:
- Distillation as a deliberate act (not automatic).
- Promotion-by-symlink (host's `context/` surface).
- Transcript graveyard staying outside `.glean/in/` (host's call when to ingest).

## Verify

- `grep -i scribble ~/repos/gremlin/.loom/threads/stage-10-memory.waiting/instructions.md` → no hits (other than possibly historical references in change-log style commentary, which should be reworded).
- `grep -i dream ~/repos/gremlin/.loom/threads/stage-10-memory.waiting/instructions.md` → no hits.
- The thread's stitch ids and surface references match what glean actually ships.
- The dependency note pointing at glean's loom URL is correct.

## Touchpoints

- `~/repos/gremlin/.loom/threads/stage-10-memory.waiting/instructions.md` — significant rewrite.
- Cross-check: any sibling stitches inside gremlin that reference scribble (e.g. `s48`–`s52` if their `instructions.md` files exist) get updated too.

## Consistency / staleness

- Don't introduce glean *implementation* details into the gremlin thread beyond what gremlin needs to know to vendor it. Glean's interface is `init`, `ingest`, `capture`, `index`, `fetch`, `drop`, `status`, `sweep` — that's what gremlin sees.
- Confirm gremlin's "scribble stays pure markdown" line still reads correctly after replacement (now: "glean stays pure markdown").

Waits on `s47i-readme` so the README it points to is real and the conceptual updates can be referenced.
