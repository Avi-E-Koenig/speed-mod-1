# Factorio Mods in Lua

Two small mods for **Factorio 2.0**, written in Lua. I built them to learn how
Factorio's modding API works. They cover both of the game's main modding
stages and include offline tests that fake the game engine, so the tests run
without launching Factorio.

| Mod | Stage | What it does |
|-----|-------|--------------|
| [`avi-speed-test`](avi-speed-test_0.1.0/data.lua) | Data | Makes hand-crafting, mining, assemblers, furnaces, drills and labs faster |
| [`avi-starter-kit`](avi-starter-kit_0.1.0/control.lua) | Control | Gives each player a one-time kit of mid-game items (solar, belts, assemblers, …) |

## What's in here

- **Prototype editing (data stage).** `avi-speed-test` changes values in
  `data.raw` before the game world loads. For example, hand-crafting becomes
  10×, assembler 3 goes to 9.0 and electric furnaces to 9.
- **Event-driven scripting (control stage).** `avi-starter-kit` uses
  `script.on_init` and `on_player_created` so the kit works in both new and
  existing saves. It stores a per-player record in the save's `storage` table
  so nobody gets the kit twice. If the inventory is full, the extra items are
  dropped on the ground so nothing is lost.
- **Defensive code.** Every prototype or item lookup is checked first. If
  another mod renamed or removed something, the mod writes a log entry and
  skips it instead of crashing when the game starts.
- **Tests without the game.** The files in `tests/` fake just enough of
  Factorio's `data`, `game` and `storage` globals to run each mod with plain
  Lua and check what it did. That includes the case where a prototype is
  missing.

```lua
local function set_crafting_speed(category, name, speed)
  local group = data.raw[category]
  local proto = group and group[name]
  if proto then
    proto.crafting_speed = speed
  else
    log("SKIP: " .. category .. "/" .. name .. " not found")
  end
end
```

## Running it

```bash
sudo ./install-lua-tools.sh   # installs lua + luac (one-time)
./validate.sh                 # JSON check, luac syntax parse, behavioral tests
./validate.sh --ship          # ...then zip each mod and copy it to the Factorio mods folder
```

> `--ship` copies to a Windows mods folder under WSL. Edit `MODS_FOLDER` in
> `validate.sh` for your setup.

To install by hand, zip a mod folder (e.g. `avi-speed-test_0.1.0/`), put the
zip in your Factorio `mods` directory and restart the game.

## Learn more

[`MODDING.md`](MODDING.md) is my reference notes. It explains the data and
control stages, how `data.raw` is laid out, load order and dependencies,
console commands for testing, and links to the official API docs.
