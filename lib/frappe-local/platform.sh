#!/usr/bin/env bash

FL_BREW_PREFIX="${FL_BREW_PREFIX:-}"
FL_ARCH="${FL_ARCH:-}"

fl_platform_init() {
  [[ "$(uname -s)" == "Darwin" ]] || fl_die "Not running on macOS." "This installer targets macOS."
  fl_require_cmd brew "Install Homebrew from https://brew.sh"
  FL_BREW_PREFIX="$(brew --prefix)"
  FL_ARCH="$(uname -m)"
}

fl_brew_ensure() {
  local formula="$1"
  if brew list --formula --versions "$formula" >/dev/null 2>&1; then
    fl_info "$formula already installed ($(brew list --versions "$formula" | head -n1))"
  else
    fl_run brew install "$formula"
  fi
}

fl_brew_formula_available() {
  local formula="$1"
  brew list --formula --versions "$formula" >/dev/null 2>&1 || brew info "$formula" >/dev/null 2>&1
}

fl_process_running() {
  pgrep -qf "$1" 2>/dev/null
}

fl_brew_service_running() {
  local svc="$1"
  brew services list 2>/dev/null | awk -v s="$svc" '$1==s {print $2}' | grep -q '^started$'
}

fl_ensure_service_started() {
  local formula="$1" proc_pattern="$2" tmpfile
  tmpfile="$(mktemp "${TMPDIR:-/tmp}/frappe-local-brew.XXXXXX")"
  if fl_process_running "$proc_pattern" || fl_brew_service_running "$formula"; then
    fl_ok "${formula} is running"
    rm -f "$tmpfile"
    return 0
  fi
  fl_warn "${formula} is not running; starting now"
  if ! brew services start "$formula" >"$tmpfile" 2>&1; then
    if ! grep -q -E 'already (loaded|bootstrapped)|exited with 5' "$tmpfile"; then
      cat "$tmpfile"
      rm -f "$tmpfile"
      fl_die "brew services start ${formula} failed."
    fi
  fi
  rm -f "$tmpfile"
  sleep 2
  fl_process_running "$proc_pattern" || fl_brew_service_running "$formula" || fl_die "${formula} did not come up."
  fl_ok "${formula} is running"
}

fl_parse_mariadb_version() {
  sed -n -e 's/.*[^0-9]\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)-MariaDB.*/\1/p' \
         -e 's/.*Distrib \([0-9][0-9.]*\).*/\1/p'
}

fl_formula_prefix() {
  local formula="$1"
  printf '%s/opt/%s\n' "$FL_BREW_PREFIX" "$formula"
}

fl_python_bin() {
  printf '%s/bin/%s\n' "$(fl_formula_prefix "$FL_PYTHON_FORMULA")" "$FL_PYTHON_BIN_NAME"
}

fl_node_bin() {
  printf '%s/bin/node\n' "$(fl_formula_prefix "$FL_NODE_FORMULA")"
}

fl_npm_bin() {
  printf '%s/bin/npm\n' "$(fl_formula_prefix "$FL_NODE_FORMULA")"
}

fl_mariadb_bin() {
  printf '%s/bin/mariadb\n' "$(fl_formula_prefix "$FL_MARIADB_FORMULA")"
}

fl_profile_path_exports() {
  cat <<EOF
export PATH="${FL_BREW_PREFIX}/opt/${FL_PYTHON_FORMULA}/bin:\$PATH"
export PATH="${FL_BREW_PREFIX}/opt/${FL_NODE_FORMULA}/bin:\$PATH"
export PATH="${FL_BREW_PREFIX}/opt/${FL_MARIADB_FORMULA}/bin:\$PATH"
export LDFLAGS="-L${FL_BREW_PREFIX}/opt/openssl@3/lib -L${FL_BREW_PREFIX}/opt/libffi/lib -L${FL_BREW_PREFIX}/opt/zlib/lib"
export CPPFLAGS="-I${FL_BREW_PREFIX}/opt/openssl@3/include -I${FL_BREW_PREFIX}/opt/libffi/include -I${FL_BREW_PREFIX}/opt/zlib/include"
export PKG_CONFIG_PATH="${FL_BREW_PREFIX}/opt/openssl@3/lib/pkgconfig:${FL_BREW_PREFIX}/opt/libffi/lib/pkgconfig:${FL_BREW_PREFIX}/opt/zlib/lib/pkgconfig"
EOF
}
