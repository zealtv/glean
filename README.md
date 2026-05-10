# 🔮 glean

A tiny, file-based protocol for memory and distillation.

You glean a finding from larger work. A finding is one small unit of current
guidance — what's worth carrying forward.

When you open `.glean/findings/`, you are looking at the guidance worth
carrying now.

```
.glean/
  in/                            ← raw inbox; anything goes
  findings/
    INDEX.md                     ← generated; always-loaded surface
    preserve-claim-kind.md       ← one flat file per finding
    avoid-overfit-on-eval.md
  dropped/
    foo.md                       ← retired finding or in/ item
    foo.reason.md                ← why it was dropped
  distil.md                      ← host-local brief, editable
```

The file system is the protocol.

## The finding contract

A finding is one markdown file at `findings/<id>.md`. The parser only needs
two things:

- **Title** — first `# ` line. Falls back to `<id>` if absent.
- **Description** — first non-empty line *between* the title and the next
  heading. One sentence. Falls back to `(no description)` if absent.

Everything else is free prose. Findings are editable in place; `drop` is
purely retirement.

`distil.md` *suggests* common sections — none enforced by the parser:

```markdown
# Preserve claim kind

Downstream parsers depend on the original claim_kind field.

## Why
Q3 ingest break traced back to a normalize step that lowercased it.

## Triggers
claim_kind, normalize, parser, downstream

## Associations
- [[avoid-overfit-on-eval]]

## Context
Examples, references, longer notes live here.
```

Wikilinks `[[id]]` resolve to `findings/<id>.md`. Associations are just
bullet links — nothing parses them, but they read well and an agent can grep
for backlinks trivially.

## Disclosure layers

Three tiers of cost, by design:

| Tier | What | When |
|---|---|---|
| **Always loaded** | `findings/INDEX.md` | A host symlinks this into its always-loaded context surface. The agent sees one bullet per finding (id + title + description). |
| **Fetched on demand** | `findings/<id>.md` body | Agent runs `fetch` to get matching paths, then reads the bodies. |
| **Read by hand** | Anything else | Long examples, references — surface a finding as a starting point and follow links. |

Promotion to always-loaded is the host's call (e.g. by symlinking a specific
finding into the host's always-context surface). Glean stays unaware of how
its output is consumed.

## Commands

```
./glean.sh init
./glean.sh ingest <src> [name]      # land raw material in in/ (use - for stdin)
./glean.sh capture <id>             # stdin → findings/<id>.md (one-shot polished)
./glean.sh index                    # regenerate findings/INDEX.md
./glean.sh fetch [--all] <q...>     # paths of findings matching query
./glean.sh drop <id> [reason...]    # retire to dropped/, write <id>.reason.md
./glean.sh status                   # list trays
./glean.sh sweep [days]             # remove dropped/ older than N days (default 14)
```

### Two entry points

- **`ingest <src> [name]`** lands raw material in `in/`. File or directory.
  Use `-` as `<src>` to read stdin (requires explicit name). Mirrors
  nestlings, uses the family-wide `.landing` write-protection suffix during
  the move so an interrupted ingest leaves only `.landing` residue.
- **`capture <id>`** writes a polished finding in one shot. Pipe stdin and
  it lands at `findings/<id>.md` verbatim. Run on a TTY (no pipe) to seed
  a template instead.

Use `ingest` for "I have raw stuff and don't know yet what to do with it";
use `capture` for "I already know this is a finding."

### `fetch` modes

Default is **strict**: matches against id, title, description, and contents
of `## Triggers`. Add `--all` (or `-a`) to grep the whole file. Strict by
default keeps the agent's context lean and rewards writers who curate their
Triggers section.

## Distillation

Distil is the act of turning raw material in `in/` into findings (or drops).

Glean exposes scaffolding (`capture`, `drop`, `index`, `fetch`); judgment is
the agent's. There is **no** `distil` command — distillation is what the
agent does when it reads `distil.md`, looks at `in/`, and operates via the
commands above.

The `distil.md` brief seeded by `init` is host-local: edit it freely to
shape distillation for *this* glean. The protocol doesn't care what the
brief says — it only cares about the finding contract.

## Family

Glean is the memory tile in a five-protocol family:

- 🪡 **loom** — planning; threads of work.
- 🪺 **nestlings** — work tray; in/ → tend → out/.
- 🦫 **groundhog** — recurring items on a schedule.
- 🔮 **glean** — memory; in/ → distil → findings/.
- 👀 **gremlin** — agent host that brings them together.

All small, file-based, no metadata files, no frontmatter. The aesthetic is:
the filesystem is the API.

## What glean is not

- Not a database.
- Not an LLM.
- Not a search engine.
- Not aware of any consumer — glean has no idea who's reading its output.

A markdown filing cabinet with a tiny parse contract. That's all.

## What ships

This repo's own `.glean/` is the scaffold you get from `glean.sh init`,
seeded with one finding (`keep-glean-small`) that encodes the protocol's
spirit. Clone, peek inside, and either reuse the structure or run `init`
in your own project.
