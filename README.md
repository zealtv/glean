# 🔮 glean

A tiny, file-based protocol for memory and distillation.

You glean a finding from larger work. A finding is one small unit of current
guidance — what's worth carrying forward.


```
.glean/
  in/                            ← raw inbox; anything goes
  findings/
    INDEX.md                     ← generated; always-loaded surface
    example-finding-001.md       ← one flat file per finding
    example-finding-002.md
  dropped/
    foo.md                       ← retired finding or in/ item
    foo.reason.md                ← why it was dropped
  distil.md                      ← host-local distilation instructions, editable
```

The file system is the protocol.

## The finding contract

A finding is one markdown file at `findings/<id>.md`, it only needs two things:

- **Title** — first `# ` line. 
- **Description** — first non-empty line *between* the title and the next
  heading. One sentence. 

Everything else is free prose. Findings can link to other resources. The supplied `distil.md` *suggests* common sections:

- **Triggers** — comma separated items under `## Triggers` are keywords searched by the `fetch` command.
- **Associations** — wikilinks `[[id]]` under `##Associations` that resolve to `findings/<id>.md`. Associations are just bullet links - nothing parses them, but they read well and an agent can grep for backlinks trivially.
- **Context** — examples, references, and longer notes can live under `## Context`, and can be loaded on demand for leaner systems.
- **Why** - reasoning or historical context.


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

## Procedure

The default flow is three steps: ingest, distil, fetch.

### Ingest

**Ingest** raw material into `in/`.
  ```sh
  ./glean.sh ingest some/note.md          # file or directory
  echo "rough thought" | ./glean.sh ingest - rough
   ```


### Distil

**Distil** is the act of turning raw material in `in/` into findings.

Read each item in `in/`, then either:
- sharpen an existing finding (edit `findings/<id>.md` in place);
- create a new finding (`./glean.sh capture <id>`, piping the polished body);
- drop the item (`./glean.sh drop <id> "reason"`).

In each case the inbox item leaves `in/` — that's the signal it's been
distilled. Run `./glean.sh index` afterwards to refresh `INDEX.md`.

There is **no** `distil` command — distillation is what the
agent does when it reads `distil.md`, looks at `in/`, and operates via the
commands above. 

The `distil.md` brief seeded by `init` is host-local: edit it freely to
shape distillation for *this* glean system. The protocol doesn't care what the
brief says — it only cares about the finding contract.

### Fetch

Return findings matching the query.  

Fetch has two modes. 
  - **strict** (default): matches against id, title, description, and contents of `## Triggers`. 
  - *all* (`--all`or `-a`): grep the whole file. 

Strict by default keeps the agent's context lean and rewards writers who curate their
Triggers section.


## Commands

```
./glean.sh init
./glean.sh ingest <src> [name]      # land raw material in in/ (use - for stdin)
./glean.sh capture <id>             # stdin → findings/<id>.md (one-shot pre-disitilled findings)
./glean.sh index                    # regenerate findings/INDEX.md
./glean.sh fetch [--all] <q...>     # paths of findings matching query
./glean.sh drop <id> [reason...]    # retire to dropped/, write <id>.reason.md
./glean.sh status                   # list trays
./glean.sh sweep [days]             # remove dropped/ older than N days (default 14)
```
