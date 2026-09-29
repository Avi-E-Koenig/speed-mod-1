#!/usr/bin/env bash
#
# install-lua-tools.sh
# Installs a Lua interpreter + compiler so the mod's data.lua can be
# syntax-checked with `luac -p` before zipping/shipping.
#
# Usage:
#   sudo ./install-lua-tools.sh
#
# Installs (via apt): lua5.4 and luac (the bytecode compiler / syntax checker).
# Falls back to building Lua 5.4 from source if the apt packages are missing.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "This script needs root. Re-run with: sudo $0" >&2
  exit 1
fi

log() { printf '\n==> %s\n' "$*"; }

# Who to leave any source-build artifacts owned by (the invoking user).
REAL_USER="${SUDO_USER:-root}"

if command -v apt-get >/dev/null 2>&1; then
  log "Updating apt package lists"
  apt-get update -y

  log "Installing lua5.4 + luarocks (luac ships with lua5.4)"
  # lua5.4 provides /usr/bin/lua5.4 and /usr/bin/luac5.4
  if apt-get install -y lua5.4; then
    # Convenience symlinks so plain `lua` / `luac` work.
    [[ -e /usr/local/bin/lua  ]] || ln -sf "$(command -v lua5.4)"  /usr/local/bin/lua
    [[ -e /usr/local/bin/luac ]] || ln -sf "$(command -v luac5.4)" /usr/local/bin/luac
    echo "apt install succeeded."
  else
    echo "apt package unavailable; will build from source." >&2
    NEED_SOURCE_BUILD=1
  fi
else
  echo "apt-get not found; will build from source." >&2
  NEED_SOURCE_BUILD=1
fi

if [[ "${NEED_SOURCE_BUILD:-0}" == "1" ]]; then
  log "Building Lua 5.4 from source"
  apt-get install -y build-essential libreadline-dev curl ca-certificates || true

  LUA_VER="5.4.7"
  WORK="$(mktemp -d)"
  cd "$WORK"
  curl -fSL "https://www.lua.org/ftp/lua-${LUA_VER}.tar.gz" -o lua.tar.gz
  tar xzf lua.tar.gz
  cd "lua-${LUA_VER}"
  make linux        # builds src/lua and src/luac
  make install      # installs to /usr/local/bin
  cd /
  rm -rf "$WORK"
fi

log "Verifying installation"
command -v lua  || command -v lua5.4
command -v luac || command -v luac5.4
echo
( lua -v 2>/dev/null || lua5.4 -v )
echo
echo "Done. You can now syntax-check Lua with:  luac -p path/to/data.lua"
