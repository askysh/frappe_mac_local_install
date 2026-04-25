#!/usr/bin/env bash

if [[ -t 1 && "${NO_COLOR:-0}" != "1" ]]; then
  FL_BOLD=$'\033[1m'; FL_DIM=$'\033[2m'; FL_RED=$'\033[31m'; FL_GREEN=$'\033[32m'
  FL_YELLOW=$'\033[33m'; FL_BLUE=$'\033[34m'; FL_RESET=$'\033[0m'
else
  FL_BOLD=""; FL_DIM=""; FL_RED=""; FL_GREEN=""; FL_YELLOW=""; FL_BLUE=""; FL_RESET=""
fi

fl_section() { printf '\n%s========== %s ==========%s\n' "$FL_BOLD$FL_BLUE" "$1" "$FL_RESET"; }
fl_ok()      { printf '  %sOK%s %s\n' "$FL_GREEN" "$FL_RESET" "$1"; }
fl_warn()    { printf '  %sWARN%s %s\n' "$FL_YELLOW" "$FL_RESET" "$1"; }
fl_fail()    { printf '  %sFAIL%s %s\n' "$FL_RED" "$FL_RESET" "$1"; }
fl_info()    { printf '  %s..%s %s\n' "$FL_DIM" "$FL_RESET" "$1"; }

fl_die() {
  fl_fail "$1"
  printf '\n%sAborting.%s %s\n' "$FL_RED$FL_BOLD" "$FL_RESET" "${2:-Fix the above and re-run.}"
  exit "${3:-1}"
}

fl_confirm() {
  local prompt="$1" answer
  read -r -p "  ${prompt} [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

fl_ask() {
  local __varname="$1" __prompt="$2" __default="${3:-}" __answer
  if [[ -n "${!__varname:-}" ]]; then
    fl_info "using env-provided ${__varname}=${!__varname}"
    return 0
  fi
  if [[ -n "$__default" ]]; then
    read -r -p "  ${__prompt} [${__default}]: " __answer
    printf -v "$__varname" '%s' "${__answer:-$__default}"
  else
    read -r -p "  ${__prompt}: " __answer
    printf -v "$__varname" '%s' "$__answer"
  fi
}

fl_ask_secret() {
  local __varname="$1" __prompt="$2" __answer __confirm
  if [[ -n "${!__varname:-}" ]]; then
    fl_info "using env-provided ${__varname} (hidden)"
    return 0
  fi
  while true; do
    read -r -s -p "  ${__prompt}: " __answer; printf '\n'
    [[ -n "$__answer" ]] || { fl_warn "empty value; retry"; continue; }
    read -r -s -p "  confirm ${__prompt}: " __confirm; printf '\n'
    [[ "$__answer" == "$__confirm" ]] && { printf -v "$__varname" '%s' "$__answer"; return 0; }
    fl_warn "values do not match; retry"
  done
}
