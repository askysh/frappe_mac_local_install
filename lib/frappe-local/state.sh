#!/usr/bin/env bash

FL_STATE_DIR="${SCRIPT_DIR}/.frappe-local"
FL_STATE_FILE="${FL_STATE_DIR}/state.env"

fl_state_init() {
  [[ "${FL_DRY_RUN:-0}" == "1" ]] && return 0
  mkdir -p "$FL_STATE_DIR"
  touch "$FL_STATE_FILE"
}

fl_state_set() {
  local key="$1" value="$2"
  [[ "${FL_DRY_RUN:-0}" == "1" ]] && return 0
  grep -v "^${key}=" "$FL_STATE_FILE" >"${FL_STATE_FILE}.tmp" 2>/dev/null || true
  printf '%s=%q\n' "$key" "$value" >>"${FL_STATE_FILE}.tmp"
  mv "${FL_STATE_FILE}.tmp" "$FL_STATE_FILE"
}

fl_state_get() {
  local key="$1"
  sed -n "s/^${key}=//p" "$FL_STATE_FILE" | tail -n1
}
