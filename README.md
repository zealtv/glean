# 🖍️ scribble

A tiny, file-based protocol for memory and distillation.

A finding is one small unit of current guidance.

When you open `.scribble/findings/`, you are looking at the guidance worth carrying now.

```text
.scribble/
  in/
  findings/
  dropped/
```

## How scribble works

Incoming material lands in `in/`.

Dreaming works across `in/`, `findings/`, and `dropped/`.

A finding is a flat directory with a `finding.md` file.

```text
.scribble/
  findings/
    preserve-claim-kind/
      finding.md
      context.md
```

- root entries in `findings/` are current findings
- findings stay flat
- `context.md` is optional
- associations are plain bullet links

## Rules

1. One item, one place.
2. Ingest by suffix: `note.scribbling/` becomes `note/` when ready.
3. Dream consumes `in/`: acted-on items leave `in/`.
4. Successful digestion changes `findings/`.
5. Drop by move: move an item to `dropped/` and write `name.reason.md`.
6. Keep findings small and few.
7. Let associations carry discoverability.

The file system is the protocol.

## Agent loop

1. Look at `.scribble/in/`
2. Read what has arrived
3. Read `dream.md`
4. Read nearby findings
5. Dream
6. Either:
   - revise or create a finding
   - drop the item with a reason
   - or leave it in `in/` if it still needs digestion

Keep findings small. Split or revise before adding more.

## finding.md

`finding.md` is the conventional file that tells a human or agent what the finding is for.

Keep it short. Keep it clear.

Suggested headings:

- `Claim`
- `Why`
- `Scope`
- `Associations`

A finding is a small, titled unit of current guidance. Its core lives in `finding.md`. Any supporting context lives beside it, not above it.

## dream.md

`dream.md` is the local dreaming brief for this Scribble instance.

It is allowed to vary from host to host.

The protocol lives in the surrounding structure.

## Commands

```text
./scribble.sh init
./scribble.sh ingest <item-id>
./scribble.sh ready <item-id>
./scribble.sh finding <finding-id>
./scribble.sh context <finding-id>
./scribble.sh drop <id> [reason...]
./scribble.sh status
```