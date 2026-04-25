#!/usr/bin/env bash

FL_DRY_RUN="${FL_DRY_RUN:-0}"
FL_LAST_COMMAND=""

fl_require_cmd() {
  local cmd="$1" hint="${2:-}"
  command -v "$cmd" >/dev/null 2>&1 || fl_die "Required command '$cmd' not found." "${hint:-Install it and re-run.}"
}

fl_run() {
  FL_LAST_COMMAND="$*"
  if [[ "$FL_DRY_RUN" == "1" ]]; then
    fl_info "dry-run: $*"
    return 0
  fi
  "$@"
}

fl_capture() {
  FL_LAST_COMMAND="$*"
  "$@"
}

fl_retry() {
  local attempts="$1" delay="$2"; shift 2
  local i=1
  while true; do
    "$@" && return 0
    [[ "$i" -ge "$attempts" ]] && return 1
    fl_warn "command failed; retry ${i}/${attempts}: $*"
    sleep "$delay"
    i=$((i + 1))
  done
}

fl_on_error() {
  local code="$?"
  [[ "$code" -eq 0 ]] && return 0
  fl_fail "Last command failed with exit code ${code}: ${FL_LAST_COMMAND:-unknown}"
  fl_info "Re-run with --verbose for more detail once verbose mode is added."
  exit "$code"
}
