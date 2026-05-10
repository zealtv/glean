#!/usr/bin/env bash
set -euo pipefail

GLEAN="$(cd "$(dirname "$0")" && pwd)/glean.sh"
[[ -x "$GLEAN" ]] || { echo "glean.sh not executable at $GLEAN" >&2; exit 1; }

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  [[ -n "${2:-}" ]] && printf '  %s\n' "$2" >&2
  exit 1
}

ok() { printf 'ok: %s\n' "$1"; }

assert_eq() {
  local actual="$1" expected="$2" msg="$3"
  [[ "$actual" == "$expected" ]] || fail "$msg" "expected: $expected | actual: $actual"
}

assert_file_exists() {
  [[ -e "$1" ]] || fail "expected file: $1"
}

assert_file_absent() {
  [[ ! -e "$1" ]] || fail "unexpected file: $1"
}

assert_contains_file() {
  local file="$1" needle="$2"
  grep -qF -- "$needle" "$file" || fail "$file should contain: $needle"
}

assert_contains_str() {
  local haystack="$1" needle="$2" msg="$3"
  echo "$haystack" | grep -qF -- "$needle" || fail "$msg" "missing: $needle | got: $haystack"
}

assert_empty_str() {
  local s="$1" msg="$2"
  [[ -z "$s" ]] || fail "$msg" "expected empty, got: $s"
}

# Run a test function in a fresh scratch glean.
# Usage: run_test <name> <fn>
run_test() {
  local name="$1" fn="$2"
  local d
  d="$(mktemp -d)"
  ( cd "$d" && "$GLEAN" init >/dev/null && "$fn" "$d" )
  rm -rf "$d"
  ok "$name"
}

# ---- init ------------------------------------------------------------------

t_init() {
  local d="$1"
  assert_file_exists "$d/.glean/in"
  assert_file_exists "$d/.glean/findings"
  assert_file_exists "$d/.glean/dropped"
  assert_file_exists "$d/.glean/distil.md"
  assert_contains_file "$d/.glean/distil.md" "Distil"
}

# ---- ingest ----------------------------------------------------------------

t_ingest_file() {
  local d="$1"
  echo "hello" > "$d/src.md"
  ( cd "$d" && "$GLEAN" ingest src.md >/dev/null )
  assert_file_exists "$d/.glean/in/src.md"
  assert_file_absent "$d/.glean/in/src.md.landing"
  assert_contains_file "$d/.glean/in/src.md" "hello"
}

t_ingest_dir() {
  local d="$1"
  mkdir "$d/srcdir"
  echo "a" > "$d/srcdir/a.txt"
  ( cd "$d" && "$GLEAN" ingest srcdir >/dev/null )
  assert_file_exists "$d/.glean/in/srcdir"
  assert_file_exists "$d/.glean/in/srcdir/a.txt"
  assert_file_absent "$d/.glean/in/srcdir.landing"
}

t_ingest_stdin() {
  local d="$1"
  ( cd "$d" && echo "rough thought" | "$GLEAN" ingest - rough >/dev/null )
  assert_file_exists "$d/.glean/in/rough.md"
  assert_contains_file "$d/.glean/in/rough.md" "rough thought"
}

t_ingest_custom_name() {
  local d="$1"
  echo "x" > "$d/source.md"
  ( cd "$d" && "$GLEAN" ingest source.md mynote >/dev/null )
  assert_file_exists "$d/.glean/in/mynote"
}

t_ingest_conflict() {
  local d="$1"
  ( cd "$d" && echo "first" | "$GLEAN" ingest - dup >/dev/null )
  if ( cd "$d" && echo "second" | "$GLEAN" ingest - dup ) >/dev/null 2>&1; then
    fail "ingest should refuse on existing in/<name>"
  fi
}

t_ingest_stdin_no_name() {
  local d="$1"
  if ( cd "$d" && echo "x" | "$GLEAN" ingest - ) >/dev/null 2>&1; then
    fail "ingest from stdin without name should fail"
  fi
}

t_ingest_no_source() {
  local d="$1"
  if ( cd "$d" && "$GLEAN" ingest /no/such/path ) >/dev/null 2>&1; then
    fail "ingest of nonexistent source should fail"
  fi
}

# ---- capture ---------------------------------------------------------------

t_capture_pipe() {
  local d="$1"
  ( cd "$d" && printf '# Title\n\nA description.\n' | "$GLEAN" capture foo >/dev/null )
  assert_file_exists "$d/.glean/findings/foo.md"
  assert_contains_file "$d/.glean/findings/foo.md" "A description."
}

t_capture_conflict() {
  local d="$1"
  ( cd "$d" && printf '# A\n\nx\n' | "$GLEAN" capture foo >/dev/null )
  if ( cd "$d" && printf '# B\n\ny\n' | "$GLEAN" capture foo ) >/dev/null 2>&1; then
    fail "capture should refuse on existing finding"
  fi
}

t_capture_empty() {
  local d="$1"
  ( cd "$d" && printf '' | "$GLEAN" capture stub >/dev/null )
  assert_file_exists "$d/.glean/findings/stub.md"
  [[ ! -s "$d/.glean/findings/stub.md" ]] || fail "stub.md should be empty"
}

t_capture_invalid_id() {
  local d="$1"
  if ( cd "$d" && echo "x" | "$GLEAN" capture "bad/id" ) >/dev/null 2>&1; then
    fail "capture should reject invalid id"
  fi
}

# ---- index -----------------------------------------------------------------

t_index_basic() {
  local d="$1"
  ( cd "$d" && \
    printf '# Foo\n\nFoo desc.\n' | "$GLEAN" capture foo >/dev/null && \
    printf '# Bar\n\nBar desc.\n' | "$GLEAN" capture bar >/dev/null && \
    "$GLEAN" index >/dev/null )
  assert_file_exists "$d/.glean/findings/INDEX.md"
  assert_contains_file "$d/.glean/findings/INDEX.md" "[[bar]] — Bar — Bar desc."
  assert_contains_file "$d/.glean/findings/INDEX.md" "[[foo]] — Foo — Foo desc."
}

t_index_no_description() {
  local d="$1"
  ( cd "$d" && \
    printf '# Just a title\n\n## Why\nbody\n' | "$GLEAN" capture title-only >/dev/null && \
    "$GLEAN" index >/dev/null )
  assert_contains_file "$d/.glean/findings/INDEX.md" "[[title-only]] — Just a title — (no description)"
}

t_index_no_title() {
  local d="$1"
  ( cd "$d" && \
    printf 'just prose\n\nmore\n' | "$GLEAN" capture untitled >/dev/null && \
    "$GLEAN" index >/dev/null )
  assert_contains_file "$d/.glean/findings/INDEX.md" "[[untitled]] — untitled —"
}

t_index_idempotent() {
  local d="$1"
  ( cd "$d" && \
    printf '# A\n\nx\n' | "$GLEAN" capture a >/dev/null && \
    "$GLEAN" index >/dev/null )
  local h1 h2
  h1="$(shasum "$d/.glean/findings/INDEX.md" | cut -d' ' -f1)"
  ( cd "$d" && "$GLEAN" index >/dev/null )
  h2="$(shasum "$d/.glean/findings/INDEX.md" | cut -d' ' -f1)"
  assert_eq "$h2" "$h1" "INDEX.md changed on re-index"
}

t_index_excludes_self() {
  local d="$1"
  ( cd "$d" && "$GLEAN" index >/dev/null )
  if grep -q '\[\[INDEX\]\]' "$d/.glean/findings/INDEX.md"; then
    fail "INDEX.md should not list itself"
  fi
}

# ---- fetch -----------------------------------------------------------------

t_fetch_strict() {
  local d="$1"
  ( cd "$d" && printf '# Preserve claim kind\n\nDownstream parsers depend on claim_kind.\n\n## Triggers\nclaim_kind, normalize\n\n## Body\nbody-only-word: zebra\n' \
      | "$GLEAN" capture preserve-claim-kind >/dev/null )
  local out
  out="$( cd "$d" && "$GLEAN" fetch claim_kind )"
  assert_contains_str "$out" "preserve-claim-kind.md" "fetch claim_kind (Triggers)"
  out="$( cd "$d" && "$GLEAN" fetch PRESERVE )"
  assert_contains_str "$out" "preserve-claim-kind.md" "fetch PRESERVE (case-insensitive title)"
  out="$( cd "$d" && "$GLEAN" fetch parsers )"
  assert_contains_str "$out" "preserve-claim-kind.md" "fetch parsers (description)"
  out="$( cd "$d" && "$GLEAN" fetch preserve-claim-kind )"
  assert_contains_str "$out" "preserve-claim-kind.md" "fetch by id"
  out="$( cd "$d" && "$GLEAN" fetch zebra )"
  assert_empty_str "$out" "strict mode shouldn't match body-only zebra"
}

t_fetch_all() {
  local d="$1"
  ( cd "$d" && printf '# Foo\n\ndesc.\n\n## Body\nbody-only-word: zebra\n' \
      | "$GLEAN" capture foo >/dev/null )
  local out
  out="$( cd "$d" && "$GLEAN" fetch --all zebra )"
  assert_contains_str "$out" "foo.md" "fetch --all should match body content"
}

t_fetch_multi_term_union() {
  local d="$1"
  ( cd "$d" && \
    printf '# A\n\ndesc-a\n\n## Triggers\nalpha\n' | "$GLEAN" capture a >/dev/null && \
    printf '# B\n\ndesc-b\n\n## Triggers\nbeta\n' | "$GLEAN" capture b >/dev/null )
  local out
  out="$( cd "$d" && "$GLEAN" fetch alpha beta )"
  assert_contains_str "$out" "a.md" "multi-term should match a"
  assert_contains_str "$out" "b.md" "multi-term should match b"
}

t_fetch_no_match() {
  local d="$1"
  ( cd "$d" && printf '# X\n\ny\n' | "$GLEAN" capture x >/dev/null )
  local out
  out="$( cd "$d" && "$GLEAN" fetch xyzzy )"
  assert_empty_str "$out" "no-match should produce empty stdout"
}

t_fetch_no_query() {
  local d="$1"
  if ( cd "$d" && "$GLEAN" fetch ) >/dev/null 2>&1; then
    fail "fetch with no query should fail"
  fi
  if ( cd "$d" && "$GLEAN" fetch --all ) >/dev/null 2>&1; then
    fail "fetch --all with no query should fail"
  fi
}

# ---- drop ------------------------------------------------------------------

t_drop_finding() {
  local d="$1"
  ( cd "$d" && \
    printf '# Foo\n\ndesc.\n' | "$GLEAN" capture foo >/dev/null && \
    "$GLEAN" drop foo "outdated" >/dev/null )
  assert_file_exists "$d/.glean/dropped/foo.md"
  assert_file_exists "$d/.glean/dropped/foo.reason.md"
  assert_contains_file "$d/.glean/dropped/foo.reason.md" "outdated"
  assert_file_absent "$d/.glean/findings/foo.md"
}

t_drop_inbox_file() {
  local d="$1"
  ( cd "$d" && echo "raw" | "$GLEAN" ingest - rough >/dev/null && \
    "$GLEAN" drop rough >/dev/null )
  assert_file_exists "$d/.glean/dropped/rough.md"
  assert_file_exists "$d/.glean/dropped/rough.reason.md"
  assert_file_absent "$d/.glean/in/rough.md"
}

t_drop_inbox_dir() {
  local d="$1"
  mkdir "$d/srcdir"
  echo "x" > "$d/srcdir/a.txt"
  ( cd "$d" && "$GLEAN" ingest srcdir mydir >/dev/null && \
    "$GLEAN" drop mydir >/dev/null )
  assert_file_exists "$d/.glean/dropped/mydir"
  assert_file_exists "$d/.glean/dropped/mydir.reason.md"
  assert_file_absent "$d/.glean/in/mydir"
}

t_drop_already_dropped() {
  local d="$1"
  ( cd "$d" && printf '# A\n\nx\n' | "$GLEAN" capture a >/dev/null && \
    "$GLEAN" drop a "first" >/dev/null )
  local out
  out="$( cd "$d" && "$GLEAN" drop a "second" )"
  assert_contains_str "$out" "already dropped" "drop on already-dropped should print friendly note"
  assert_contains_file "$d/.glean/dropped/a.reason.md" "first"
}

t_drop_unknown() {
  local d="$1"
  if ( cd "$d" && "$GLEAN" drop nope ) >/dev/null 2>&1; then
    fail "drop on unknown id should fail"
  fi
}

# ---- status ----------------------------------------------------------------

t_status_empty() {
  local d="$1"
  local out
  out="$( cd "$d" && "$GLEAN" status )"
  assert_contains_str "$out" "(empty)" "status of fresh glean should show (empty)"
}

t_status_populated() {
  local d="$1"
  ( cd "$d" && \
    echo "raw" | "$GLEAN" ingest - rough >/dev/null && \
    printf '# Foo\n\ndesc.\n' | "$GLEAN" capture foo >/dev/null && \
    printf '# Bar\n\ndesc.\n' | "$GLEAN" capture bar >/dev/null && \
    "$GLEAN" drop bar "test" >/dev/null )
  local out
  out="$( cd "$d" && "$GLEAN" status )"
  assert_contains_str "$out" "- rough.md" "status: rough.md in in/"
  assert_contains_str "$out" "- foo" "status: foo in findings/"
  assert_contains_str "$out" "- bar.md" "status: bar.md in dropped/"
}

# ---- sweep -----------------------------------------------------------------

t_sweep_zero_purges_all() {
  local d="$1"
  ( cd "$d" && \
    printf '# A\n\nx\n' | "$GLEAN" capture a >/dev/null && \
    "$GLEAN" drop a "test" >/dev/null && \
    "$GLEAN" sweep 0 >/dev/null )
  assert_file_absent "$d/.glean/dropped/a.md"
  assert_file_absent "$d/.glean/dropped/a.reason.md"
}

t_sweep_default_keeps_recent() {
  local d="$1"
  ( cd "$d" && \
    printf '# A\n\nx\n' | "$GLEAN" capture a >/dev/null && \
    "$GLEAN" drop a "test" >/dev/null && \
    "$GLEAN" sweep >/dev/null )
  assert_file_exists "$d/.glean/dropped/a.md"
  assert_file_exists "$d/.glean/dropped/a.reason.md"
}

# ---- end-to-end ------------------------------------------------------------

t_e2e() {
  local d="$1"
  ( cd "$d" && \
    echo "rough" | "$GLEAN" ingest - rough >/dev/null && \
    printf '# Test finding\n\nA test description.\n\n## Triggers\nfoo\n' \
      | "$GLEAN" capture test-finding >/dev/null && \
    "$GLEAN" index >/dev/null )
  assert_contains_file "$d/.glean/findings/INDEX.md" "[[test-finding]] — Test finding — A test description."
  local out
  out="$( cd "$d" && "$GLEAN" fetch foo )"
  assert_contains_str "$out" "test-finding.md" "e2e fetch should find by trigger"
  ( cd "$d" && "$GLEAN" drop test-finding "obsolete" >/dev/null )
  assert_file_exists "$d/.glean/dropped/test-finding.md"
  ( cd "$d" && "$GLEAN" sweep 0 >/dev/null )
  assert_file_absent "$d/.glean/dropped/test-finding.md"
}

# ---- runner ----------------------------------------------------------------

run_test "init creates skeleton + distil.md" t_init
run_test "ingest <file> lands in in/" t_ingest_file
run_test "ingest <dir> lands as directory" t_ingest_dir
run_test "ingest - <name> reads stdin" t_ingest_stdin
run_test "ingest <src> <name> uses custom name" t_ingest_custom_name
run_test "ingest refuses on conflict" t_ingest_conflict
run_test "ingest from stdin requires a name" t_ingest_stdin_no_name
run_test "ingest of nonexistent source fails" t_ingest_no_source
run_test "capture writes piped stdin verbatim" t_capture_pipe
run_test "capture refuses on existing finding" t_capture_conflict
run_test "capture allows empty piped stdin" t_capture_empty
run_test "capture rejects invalid id" t_capture_invalid_id
run_test "index lists findings" t_index_basic
run_test "index falls back to (no description)" t_index_no_description
run_test "index falls back title to id" t_index_no_title
run_test "index is idempotent" t_index_idempotent
run_test "index excludes itself" t_index_excludes_self
run_test "fetch strict matches id/title/description/triggers" t_fetch_strict
run_test "fetch --all widens to body" t_fetch_all
run_test "fetch multi-term is union" t_fetch_multi_term_union
run_test "fetch with no match is empty exit 0" t_fetch_no_match
run_test "fetch with no query fails" t_fetch_no_query
run_test "drop a finding" t_drop_finding
run_test "drop an in/ file" t_drop_inbox_file
run_test "drop an in/ dir" t_drop_inbox_dir
run_test "drop on already-dropped is friendly" t_drop_already_dropped
run_test "drop on unknown id fails" t_drop_unknown
run_test "status shows (empty) on fresh glean" t_status_empty
run_test "status shows entries across trays" t_status_populated
run_test "sweep 0 purges all" t_sweep_zero_purges_all
run_test "sweep default keeps recent" t_sweep_default_keeps_recent
run_test "end-to-end: ingest → capture → index → fetch → drop → sweep" t_e2e

echo
echo "all tests passed"
