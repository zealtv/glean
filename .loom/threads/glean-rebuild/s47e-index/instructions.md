# s47e-index

**Outcome.** `glean.sh index` regenerates `findings/INDEX.md` — one bullet per finding (wikilink + title + description).

## Why

Hosts load `INDEX.md` as part of always-loaded context (e.g. via a symlink), so the agent knows *what findings exist* without paying for their bodies. The body is fetched only when triggered.

## Spec

- `glean.sh index` walks `findings/*.md`, skipping `INDEX.md` itself.
- For each finding:
  - `<id>` from the basename minus `.md`.
  - **title** from the first `# ` line; fallback to `<id>` if absent.
  - **description** from the first non-empty, non-heading line *after* the title; fallback to `(no description)` if absent.
- Writes `findings/INDEX.md`:
  ```
  <!-- auto-generated; run glean.sh index to refresh -->

  - [[preserve-claim-kind]] — Preserve claim kind — Downstream parsers depend on the original claim_kind field…
  - [[avoid-overfit-on-eval]] — Avoid overfit on eval — …
  ```
- Sorted by id, ascending.
- Empty findings dir → INDEX with header comment and no bullets.
- Idempotent.

## Verify

- Two findings with distinct titles and descriptions → INDEX lists both.
- Finding with no description → bullet shows `(no description)`, no error.
- Finding with no title → bullet uses id as the title.
- Empty findings/ → INDEX has only the header comment.
- Re-running `index` produces identical output.
- INDEX.md never includes itself as a bullet.

## Touchpoints

- `glean.sh` — new `cmd_index`. Add to `usage`.
- Parsing helpers: a small awk one-liner for title + a second for first non-empty post-title line; or one awk script that yields both. Keep dependencies to standard POSIX tools.
- `test.sh` (`s47h`) — index tests with hand-crafted findings.

## Consistency / staleness

- `usage` lists `index`.
- README rewrite in `s47i`.

Waits on `s47b-finding-contract`.
