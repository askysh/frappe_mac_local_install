#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n "$ROOT"/00-mac-system-deps.sh "$ROOT"/01-install-bench-and-site.sh "$ROOT"/lib/frappe-local/*.sh
bash "$ROOT"/tests/test-platform.sh
bash "$ROOT"/tests/test-version-policy.sh
bash "$ROOT"/tests/test-bench-flow.sh

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$ROOT"/00-mac-system-deps.sh "$ROOT"/01-install-bench-and-site.sh "$ROOT"/lib/frappe-local/*.sh
else
  printf 'shellcheck not installed; skipped lint\n'
fi
