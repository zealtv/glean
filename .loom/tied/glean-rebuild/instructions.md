# glean-rebuild

**Outcome.** Glean (formerly scribble) ships with a new shape: flat-file findings, free-prose body with a parser-only contract (title + single-line description), wikilink associations, two entry points (raw `ingest`, polished `capture`), `index`/`fetch` for discovery, and a configurable `distil.md` brief that governs the act of distillation. Old `ingest`/`ready`/`finding`/`context` subcommands are retired.

## Why

The old shape — directories per finding, two-step ingest+ready, no index, no fetch, no one-shot capture — doesn't match the real use case (an agent that distils notes and needs always-loaded awareness of what's remembered).

The new shape:

- **Flat findings** at `findings/<id>.md`. Title (H1) + single-line description as the parser contract; everything else is free prose.
- **Two entry points.** `ingest <src> [name]` lands raw material in `in/` (mirrors nestlings, uses family-wide `.landing` write-protection suffix). `capture <id>` reads stdin and writes a polished finding in one shot.
- **Discovery seam.** `index` regenerates `findings/INDEX.md` (always-loaded by hosts via symlink). `fetch [--all] <q...>` returns matching paths — strict by default (id + title + description + `## Triggers`), `--all` to widen to whole-file grep.
- **Distillation is the agent's job.** The protocol provides scaffolding (capture, drop, index, fetch); the host's editable `distil.md` brief governs judgment. No `distil` command — distil is what the agent does.
- **Findings editable in place.** `drop` is purely retirement.

Hard constraint: glean is unaware of any consumer (gremlin). No consumer-named branches, files, or comments.

## Children

| Stitch | Outcome |
|---|---|
| ~~`s47a-rename-and-skeleton`~~ | **Tied** in commit `421c40c` — repo/script/dotdir renamed, `init` seeds `distil.md`. |
| `s47b-finding-contract` | Parser rules documented (title + description). Spec stitch — no code. **Settles the contract that everything else depends on.** |
| `s47c-ingest` | `glean.sh ingest <src> [name]` with `.landing` suffix mechanics; `-` for stdin. |
| `s47d-capture` | `glean.sh capture <id>` with template-on-TTY behaviour. |
| `s47e-index` | `glean.sh index` writes `findings/INDEX.md` (one bullet per finding). |
| `s47f-fetch` | `glean.sh fetch [--all] <q...>` with strict-default scope. |
| `s47g-drop-status-sweep` | Reshape `drop`, `status`, add `sweep` for the flat-file world; retire old `ingest`/`ready`/`finding`/`context`. |
| `s47h-tests` | Build `test.sh`. Lands incrementally as earlier stitches tie. |
| `s47i-readme` | Full README + AGENTS rewrite. **Ships last** (otherwise documents fiction). |
| `s47j-update-gremlin-thread` | Cross-repo: update gremlin's waiting thread to reflect glean's new name, paths, vocabulary, and shape. Unblocks gremlin's `s48`–`s52`. |

## Dependencies

- `s47b` is the contract; `s47c`–`s47g` wait on it.
- `s47h` (tests) co-evolves with `s47c`–`s47g` — each command lands behind a green check.
- `s47i` (readme) waits on `s47a`–`s47h`.
- `s47j` (gremlin update) waits on `s47i` so the README it points to is real.

## Cross-repo

- The downstream consumer's plan lives at `~/repos/gremlin/.loom/threads/stage-10-memory.waiting/`. It's blocked on this thread tying. Updating its references is `s47j` — the only cross-repo edit this rebuild does.

## What NOT to do

- Don't add a "for gremlin" code branch, file, or comment anywhere.
- Don't introduce frontmatter, YAML, or JSON to findings. Plain markdown.
- Don't make glean perform distillation. The protocol exposes `capture`/`drop`/etc. and gets out of the way; judgment is the agent's.
- Don't enforce content structure at `capture`. Parser is lenient: missing title falls back to id; missing description shows `(no description)` in INDEX.
- Don't keep the old subcommands once the new ones land. Clean break — nothing external depends on glean yet.
