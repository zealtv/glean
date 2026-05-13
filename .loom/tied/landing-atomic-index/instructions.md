# landing-atomic-index

**Outcome.** `cmd_index` writes the catalog atomically, so concurrent
indexers cannot produce a torn or half-written `INDEX.md`.

## Scope

- In `cmd_index`, write the generated catalog to `INDEX.md.landing` inside
  `findings/`.
- On success, `mv` `INDEX.md.landing` over `INDEX.md`. POSIX rename within
  the same directory is atomic.
- On failure, remove the landing file. Do not leave it behind.
- Echo the final path as `findings/INDEX.md`, not the landing name. Callers
  and docs should never see the transient name.

The `.landing` suffix matches the vocabulary used elsewhere in the wider
protocol family for in-flight artifacts. Using it here keeps the convention
consistent.

## Constraints

- Do not change the output format of `INDEX.md`.
- Do not change the command's stdout contract — it still echoes the final
  path on success.
- `find` inside `cmd_index` already filters by `*.md` and excludes `INDEX.md`
  by name. Confirm that the landing file (`INDEX.md.landing`) is also
  excluded by that filter — if not, fix the filter so a landing file briefly
  on disk cannot be picked up as a finding.
- No new dependencies. Plain `mv` and `rm` only.

## Verification

1. Run `./glean.sh index` in a populated `.glean/`. Confirm `INDEX.md` is
   regenerated and no `INDEX.md.landing` remains on disk.
2. Simulate a failure mid-write (e.g. point the script at a non-writable
   path inside the landing step). Confirm no `INDEX.md.landing` is left
   behind and the previous `INDEX.md` is untouched.
3. Run two `./glean.sh index` invocations in parallel against the same
   `.glean/`. Confirm the resulting `INDEX.md` is a complete, valid catalog
   from one of the two runs, never a mixture.
4. Confirm a transient `INDEX.md.landing` cannot be picked up by `fetch` or
   appear as a bullet in a subsequent `INDEX.md`.
