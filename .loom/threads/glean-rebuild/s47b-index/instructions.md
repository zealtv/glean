# s47b-index

**Outcome.** `scribble.sh index` regenerates `findings/INDEX.md` — one bullet per finding (id, title, Claim line as preview).

## Why

Gremlin loads `INDEX.md` as part of always-loaded context (via the `context/` symlink pattern), so the agent always knows *what findings exist* without paying for their bodies. The body is fetched only when triggered.

Mirrors the shape of gremlin's `bin/index-skills.sh`.

## Spec

- `scribble.sh index` walks `findings/*/finding.md`.
- For each, extract:
  - `<id>` from the directory name.
  - title from the first H1 line.
  - first non-empty line under `## Claim` as the preview (or empty string if the section is absent).
- Write `findings/INDEX.md`:
  - small header comment ("auto-generated; run `scribble.sh index` to refresh").
  - one `- <id> — <title> — <claim>` bullet per finding, sorted by id.
- Empty findings dir → INDEX with header and no bullets.

## Touchpoints

- `scribble.sh` — new `index` subcommand; add to `usage`.
- `README.md` — document the command.

## Verify

- Two findings with distinct titles and Claims → INDEX.md lists both correctly.
- Finding without `## Claim` → bullet has empty preview, no error.
- Empty findings → INDEX has only the header.
- Re-run `index` is idempotent.

## Consistency / staleness

- `usage` block — list `index`.
- `README.md` Commands section — list `index`.
- Sweep for any earlier `INDEX.md`-like artifact and reconcile.

Waits on `s47a-finding-shape` (the parse contract).
