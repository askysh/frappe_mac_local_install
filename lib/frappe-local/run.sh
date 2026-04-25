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

fl_run_with_timeout() {
  local timeout_seconds="$1" label="$2" log pid start elapsed code state
  shift 2
  FL_LAST_COMMAND="$*"
  if [[ "$FL_DRY_RUN" == "1" ]]; then
    fl_info "dry-run: $*"
    return 0
  fi
  if [[ "$timeout_seconds" -le 0 ]]; then
    "$@"
    return $?
  fi

  log="$(mktemp "${TMPDIR:-/tmp}/frappe-local-command.XXXXXX")"
  "$@" </dev/null >"$log" 2>&1 &
  pid="$!"
  start="$SECONDS"

  while kill -0 "$pid" >/dev/null 2>&1; do
    state="$(ps -o state= -p "$pid" 2>/dev/null | awk '{print $1}')"
    if [[ "$state" == T* ]]; then
      kill -TERM "$pid" 2>/dev/null || true
      sleep 1
      kill -KILL "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      fl_fail "${label} stopped while waiting for input."
      fl_info "Run the command manually if it needs an interactive answer: ${FL_LAST_COMMAND}"
      rm -f "$log"
      return 125
    fi

    elapsed=$((SECONDS - start))
    if [[ "$elapsed" -ge "$timeout_seconds" ]]; then
      kill -TERM "$pid" 2>/dev/null || true
      sleep 1
      kill -KILL "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      fl_fail "${label} timed out after ${timeout_seconds}s."
      if [[ -s "$log" ]]; then
        fl_info "Last output:"
        tail -n 80 "$log" || true
      fi
      rm -f "$log"
      return 124
    fi
    sleep 1
  done

  code=0
  wait "$pid" || code="$?"
  if [[ "$code" -ne 0 && -s "$log" ]]; then
    cat "$log"
  fi
  rm -f "$log"
  return "$code"
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
