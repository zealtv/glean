# s47h-tests

**Outcome.** A real, runnable `test.sh` at the repo root. Each prior stitch's verify section feeds in. `test.sh` runs green from a fresh checkout.

## Why

Family precedent: this is the gap. Building `test.sh` from the start means each command lands behind a green check. Note from the (deleted) `BRIEFING.md`: gremlin recently deleted a broken `test.sh` stub. This one ships runnable from day one or it doesn't ship.

## Spec

- Bash, `set -euo pipefail` at the top.
- One function per command (`test_init`, `test_ingest`, `test_capture`, `test_index`, `test_fetch`, `test_drop`, `test_status`, `test_sweep`) plus integration tests (`test_e2e`).
- Each test:
  - Sets up a `mktemp -d` scratch host.
  - `cd`s into it, runs `glean.sh init`.
  - Exercises the verb, asserts outcomes (file existence, content matches, exit codes).
  - Cleans up the scratch dir.
- One line per test on success: `ok: <test name>`. Failures abort and dump context.
- Exit 0 on all-pass, 1 on first failure.
- No external test framework — plain bash assertions.

## Lands incrementally

`test.sh` doesn't need to ship complete in one stitch. It can grow alongside `s47c`–`s47g`:
- When `s47c` (ingest) ties, ingest tests are added.
- When `s47d` (capture) ties, capture tests are added.
- ...and so on.

This stitch is the **structure** stitch: lay out the test harness (helpers, assert helpers, runner skeleton) and add the first tests (init, ingest). Subsequent stitches contribute their own tests.

## Helpers needed

- `assert_eq <actual> <expected> <message>` — fails loudly if not equal.
- `assert_file_exists <path>` / `assert_file_absent <path>`.
- `assert_contains <file> <substring>`.
- `assert_exit <expected_code> <command...>` — runs command, checks exit.
- `with_scratch_glean <test_fn>` — sets up scratch + init, runs `<test_fn>`, cleans up.

## Verify

- `./test.sh` from `~/repos/glean/` exits 0 with a clean output of `ok:` lines.
- A deliberate break (e.g. comment out a line in `cmd_init`) makes the relevant test fail loudly with a clear message.

## Touchpoints

- `~/repos/glean/test.sh` — new file.
- README mentions running tests (in `s47i`).

## Consistency / staleness

- Don't ship `test.sh` if any test is failing. The whole point is that this one runs.
- Family alignment: nestlings/loom/groundhog don't ship test suites; this is a deliberate addition for glean.

Waits on `s47b-finding-contract` (for the assertions to make sense). Co-evolves with `s47c`–`s47g`.
