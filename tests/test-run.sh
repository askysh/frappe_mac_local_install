#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/frappe-local-run-test.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

. "$ROOT/lib/frappe-local/ui.sh"
. "$ROOT/lib/frappe-local/run.sh"

assert_status() {
  local expected="$1"
  shift
  set +e
  "$@" >/dev/null 2>&1
  actual="$?"
  set -e
  if [[ "$actual" != "$expected" ]]; then
    printf 'Expected exit %s, got %s: %s\n' "$expected" "$actual" "$*"
    exit 1
  fi
}

printf '#!/usr/bin/env bash\nsleep 2\n' >"$TMP_DIR/slow"
chmod +x "$TMP_DIR/slow"

fl_run_with_timeout 0 "true command" true
assert_status 124 fl_run_with_timeout 1 "slow command" "$TMP_DIR/slow"

ps() {
  printf 'T\n'
}
assert_status 125 fl_run_with_timeout 5 "stopped command" "$TMP_DIR/slow"

printf 'test-run: ok\n'
