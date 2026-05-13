# index-resilience

**Goal.** `findings/INDEX.md` stays trustworthy without callers having to
remember to refresh it.

The catalog today is rebuilt by `glean.sh index` on demand. That is the right
shape — full rebuild from disk, no cache, no incremental state — but three
gaps make it possible for the always-loaded surface to drift from the actual
`findings/` tree:

1. `cmd_index` writes `INDEX.md` in place. Two concurrent indexers race.
2. Nothing tells a reader the catalog is stale; agents trust the bullets they
   see in the always-loaded surface.
3. Humans running `glean.sh status` get a snapshot of trays but no guarantee
   that `INDEX.md` reflects what `status` just listed.

This thread closes those three gaps with cheap, local changes. None of them
should change the protocol's contract with hosts. Hosts must continue to be
able to call `glean.sh index` and get a deterministic rebuild; everything
added here is additive on top of that.

## Children

- `landing-atomic-index/` — write the catalog through `INDEX.md.landing` and
  rename, so concurrent indexers cannot produce a torn file.
- `fetch-staleness-warning/` — `fetch` cheaply detects when `findings/` has
  newer entries than `INDEX.md` and warns to stderr. No rebuild; reads stay
  read-only.
- `status-refreshes-index/` — `status` rebuilds the index as part of its
  "tell me about the state of the world" job, so humans running `status`
  always leave with a fresh catalog.

## Constraints

- The protocol stays "the filesystem is the protocol." No new state files, no
  caches, no hidden indexes.
- `fetch` must remain side-effect-free on `findings/` and `INDEX.md`.
- `INDEX.md` is the only catalog. Do not introduce a second one.
- Keep `cmd_index`'s output contract — it currently echoes the final path of
  `INDEX.md`. That stays unchanged regardless of any landing-file mechanics.
