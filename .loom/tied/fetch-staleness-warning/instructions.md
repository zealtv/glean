# fetch-staleness-warning

**Outcome.** When `fetch` runs against an `INDEX.md` that is older than at
least one finding under `findings/`, it prints a one-line warning to stderr
so the caller (agent or human) knows to refresh.

## Scope

- In `cmd_fetch`, before walking `findings/`, do a cheap mtime check:

  ```sh
  find "$dir" -maxdepth 1 -type f -name '*.md' ! -name 'INDEX.md' \
       -newer "$dir/INDEX.md" -print -quit
  ```

  If that prints anything, write one line to stderr along the lines of:

  ```text
  warning: INDEX.md is stale; run glean.sh index
  ```

- If `INDEX.md` does not exist yet, warn that it is missing rather than that
  it is stale, and still proceed with the fetch.
- `fetch` does **not** rebuild the index. It stays read-only over
  `findings/`. The point is to detect, not repair.

## Constraints

- The check must add at most one stat-style filesystem call beyond what
  `fetch` already does. Do not walk the tree twice.
- stdout of `fetch` is unchanged. The warning goes to stderr only, so
  callers grepping fetch output for paths are unaffected.
- Do not warn more than once per invocation, even if many findings are
  newer than the index.
- Do not warn when `findings/` is empty.

## Verification

1. Populate `findings/`, run `glean.sh index`, then run `glean.sh fetch
   <term>` — no warning.
2. Touch one finding so its mtime is newer than `INDEX.md`. Run `fetch
   <term>` — confirm exactly one stale-index warning on stderr and that
   stdout still contains the expected matching paths.
3. Delete `INDEX.md` entirely. Run `fetch <term>` — confirm a
   missing-index warning on stderr and that the fetch still returns
   matches from disk.
4. Run `fetch <term>` against an empty `findings/` — no warning, no
   matches.
