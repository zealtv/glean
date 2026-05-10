# s47f-fetch

**Outcome.** `glean.sh fetch [--all] <q...>` returns paths of findings whose curated surface (or whole body, with `--all`) matches any query term (case-insensitive substring).

## Why

The prefetch seam. The agent reads `INDEX.md` always; when something looks relevant it runs `fetch` to get paths, then reads the bodies. Strict by default keeps the agent's context lean; `--all` widens for cases where the curated Triggers section isn't enough.

## Spec

- `glean.sh fetch [--all] <q...>` — accepts one or more query terms.
- **Default scope** (strict): id, H1 title, description line, and contents of the `## Triggers` section. Match if any term matches any of those for any finding.
- **`--all` (or `-a`)**: whole-file grep. Match against the entire finding body, including prose outside Triggers.
- Case-insensitive substring matching.
- Output: one finding path per line on stdout (e.g. `.glean/findings/preserve-claim-kind.md`), sorted by id, deduplicated.
- No matches → exit 0, empty stdout.
- No queries (just `fetch` or `fetch --all`) → error to stderr, exit 1.
- `INDEX.md` is excluded from the search.

## Mechanics

Strict-mode parsing (per finding):
- id = basename without `.md`
- title = first `# ` line
- description = first non-empty non-heading line after title
- triggers body = lines between `## Triggers` and the next `## ` (or EOF)

A small awk script can extract these zones. Whole-file mode is just `grep -li`.

## Verify

- Findings with distinct title/description/Triggers/body words; fetch each → correct subset returned.
- Multi-term query is union (any term matches).
- Case-insensitive: `fetch FOO` matches `foo`.
- ID match: `fetch <known-id>` is a direct lookup.
- A word that's only in the *body* (not Triggers/title/description) is found in `--all` mode but NOT in default mode.
- No-match → empty stdout, exit 0.
- No-query → exit 1, error message.
- INDEX.md never appears in output.

## Touchpoints

- `glean.sh` — new `cmd_fetch`. Add to `usage`.
- `test.sh` (`s47h`) — fetch tests covering strict and `--all` modes.

## Consistency / staleness

- `usage` lists `fetch [--all] <q...>`.
- README rewrite in `s47i` documents both modes.

Waits on `s47b-finding-contract`.
