simplicity, clarity, extensibility

## Working in this repo

- The protocol is plain markdown. No frontmatter, no YAML, no JSON. The
  finding contract is two parsing rules (title + description); everything
  else is free prose.
- Glean is **unaware of any consumer**. No "for gremlin" branches, files,
  comments, or assumed directory layouts beyond `.glean/`. Downstream
  concerns are downstream concerns.
- Findings stay small and few. Editable in place. `drop` is retirement.
- The filesystem is the API. Suffix conventions (e.g. `.landing` for
  in-flight ingests) come from the family — mirror them rather than invent
  protocol-specific ones.
- Run `./test.sh` before committing. 32 tests, mktemp-isolated.
