#!/usr/bin/env bash
#
# validate.sh — one entry point to validate every mod and (optionally) ship.
#
# For each mod it runs:
#   1. info.json is valid JSON
#   2. luac -p : real Lua syntax parse of every .lua in the mod
# Plus the project-wide behavioral tests under tests/.
# With --ship it then builds each mod's zip and copies it to the mods folder.
#
# Usage:
#   ./validate.sh          # validate only
#   ./validate.sh --ship   # validate, then build zips + copy to mods folder
#
# Run from the project root.

set -euo pipefail
cd "$(dirname "$0")"

# Mods to validate/ship (folder names = "<name>_<version>").
MODS=( "avi-speed-test_0.1.0" "avi-starter-kit_0.1.0" )

# Behavioral tests (need a Lua interpreter). Each must print and exit 0 on pass.
TESTS=( "tests/smoke.lua" "tests/defensive.lua" "tests/starter_kit_smoke.lua" )

MODS_FOLDER="/mnt/c/Users/darkm/AppData/Roaming/Factorio/mods"

# Pick whichever Lua binaries exist (plain names or versioned).
LUAC="$(command -v luac || command -v luac5.4 || true)"
LUA="$(command -v lua  || command -v lua5.4  || true)"

pass() { printf '  \033[32mOK\033[0m   %s\n' "$*"; }
skip() { printf '  \033[33mSKIP\033[0m %s\n' "$*"; }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$*"; exit 1; }

# ---- Per-mod static checks ------------------------------------------------
for MOD in "${MODS[@]}"; do
  echo "== Validating ${MOD} =="
  [[ -f "${MOD}/info.json" ]] || fail "${MOD}/info.json missing"
  python3 -c "import json; json.load(open('${MOD}/info.json'))" \
    && pass "info.json is valid JSON" || fail "${MOD}/info.json is not valid JSON"

  if [[ -n "$LUAC" ]]; then
    while IFS= read -r -d '' luafile; do
      "$LUAC" -p "$luafile" && pass "luac -p: $(basename "$luafile") parses" \
        || fail "luac -p: syntax error in $luafile"
    done < <(find "$MOD" -name '*.lua' -print0)
  else
    skip "luac not found (run: sudo ./install-lua-tools.sh)"
  fi
done

# ---- Project-wide behavioral tests ----------------------------------------
echo "== Behavioral tests =="
if [[ -n "$LUA" ]]; then
  for t in "${TESTS[@]}"; do
    "$LUA" "$t" >/dev/null && pass "$(basename "$t")" || fail "$t"
  done
else
  skip "lua not found (run: sudo ./install-lua-tools.sh)"
fi

echo "All validation checks passed."

# ---- Optional ship --------------------------------------------------------
if [[ "${1:-}" == "--ship" ]]; then
  echo
  echo "== Building + shipping =="
  [[ -d "$MODS_FOLDER" ]] || fail "mods folder not found: $MODS_FOLDER"
  for MOD in "${MODS[@]}"; do
    ZIP="${MOD}.zip"
    rm -f "$ZIP"
    python3 - "$MOD" "$ZIP" <<'PY'
import sys, os, zipfile
mod_dir, zip_name = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(zip_name, "w", zipfile.ZIP_DEFLATED) as z:
    for dp, _, files in os.walk(mod_dir):
        for f in files:
            p = os.path.join(dp, f); z.write(p, p)   # keep top-level folder
with zipfile.ZipFile(zip_name) as z:
    assert z.testzip() is None, "zip integrity check failed"
PY
    cp "$ZIP" "${MODS_FOLDER}/${ZIP}"
    pass "shipped ${ZIP}"
  done
  echo "Restart Factorio to load the changes."
fi
