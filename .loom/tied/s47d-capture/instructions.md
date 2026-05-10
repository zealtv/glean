# s47d-capture

**Outcome.** `glean.sh capture <id>` reads stdin and lands a polished finding in one shot at `findings/<id>.md`. Replaces the old `finding <id>` template-creation command.

## Spec

- `glean.sh capture <id>` reads stdin until EOF.
- Validates `<id>` via existing `validate_id`.
- Refuses if `findings/<id>.md` already exists. Use `drop` first.
- **TTY-template fallback**: if stdin is a terminal (no pipe), seed a template with title placeholder, description line, and suggested H2s (`## Why`, `## Triggers`, `## Associations`, `## Context`). If stdin has piped content, write verbatim — no validation, no munging.
- Prints the resulting path on stdout.

## Template (TTY mode)

```markdown
# <title>

<single-line description>

## Why

## Triggers

## Associations

## Context
```

## Verify

- `printf "# Title\n\nA description.\n\n## Why\nbecause.\n" | glean.sh capture foo` → `findings/foo.md` contains exactly that body. Path printed. Exit 0.
- `glean.sh capture foo` (TTY, no pipe) → file contains the template. Exit 0.
- Re-capture with same id → stderr error, exit 1, original untouched.
- Empty piped stdin → empty file. Allowed (lets the user write a stub and fill in later).
- Invalid id → validation error.

## Touchpoints

- `glean.sh` — new `cmd_capture`. Replace old `cmd_finding` (which created a directory + templated `finding.md`, old shape).
- `usage` — replace `finding <finding-id>` with `capture <id>`.
- TTY detection: `[[ -t 0 ]]`.
- `test.sh` (`s47h`) — add capture tests including TTY template path (use `printf '' |` to force non-TTY where needed).

## Consistency / staleness

- Old `cmd_finding` and `cmd_context` (the latter created `context.md` siblings — superseded by inline `## Context` section) get retired in `s47g` if not here.
- README/AGENTS rewrite in `s47i`.

Waits on `s47b-finding-contract`.
