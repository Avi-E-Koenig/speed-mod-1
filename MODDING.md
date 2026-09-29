# Factorio Modding — Reference & Context

Initial context for working on the mods in this repo, plus the good sources to
reach for. Targets **Factorio 2.0**.

## The two mods here

| Mod | Stage | Entry file | What it does |
|-----|-------|-----------|--------------|
| `avi-speed-test` | **data** | `data.lua` | Edits prototype values: hand-craft / mining / assembler / drill / furnace / lab speeds |
| `avi-starter-kit` | **control** | `control.lua` | Drops a one-time item kit into the player's inventory |

## The mental model: stages

A mod can hook into different load stages. The two that matter here:

- **Data stage** (`data.lua`) — runs *before the game world exists*. You read
  and mutate prototype definitions in the global `data.raw` table. Changes are
  global and permanent (e.g. "every electric furnace now smelts 4× as fast").
  No `game`, no players, no inventories exist yet. Requires a **restart** to
  reload.
- **Control stage** (`control.lua`) — runs *at runtime*, reacting to events
  (`script.on_event`, `script.on_init`). Here you touch live objects: `game`,
  players, surfaces, inventories, and the persistent `storage` table. This is
  the only place you can, say, put items in someone's inventory.

Rule of thumb: **changing what a thing *is*** → data stage. **Reacting to what
*happens*** → control stage.

## `data.raw` — editing prototypes (data stage)

`data.raw` is a table keyed by **prototype category**, then by **prototype
name**:

```lua
data.raw[category][name].property = value
```

Categories and properties used in this repo (all verified against the API):

| Category key | Example name | Speed property | Notes |
|--------------|--------------|----------------|-------|
| `character` | `character` | `crafting_speed`, `mining_speed` | Player hand-craft / manual mining |
| `assembling-machine` | `assembling-machine-3` | `crafting_speed` | |
| `mining-drill` | `electric-mining-drill` | `mining_speed` | |
| `furnace` | `electric-furnace` | `crafting_speed` | Furnaces use crafting_speed, **not** a "smelting" field |
| `lab` | `lab` | `researching_speed` | Labs use researching_speed, **not** crafting_speed |

> **Source:** the canonical list of every category key (the top-level keys of
> `data.raw`) is the wiki **Data.raw** page below. The per-prototype property
> names live in the official Prototype API docs (also linked).

**Defensive editing.** Other mods may rename or remove a prototype, so always
guard the lookup instead of indexing blindly (a `nil` index aborts startup):

```lua
local group = data.raw[category]
local proto = group and group[name]
if proto then proto.crafting_speed = speed else log("SKIP "..name) end
```

**Load order.** Whichever mod writes a prototype *last* wins. To apply on top of
another mod, add an **optional** dependency in `info.json` so you load after it:

```json
"dependencies": ["base >= 2.0", "? Electric Furnaces"]
```

`?` = optional (load after if present). `!` = incompatible. `>=` = version
requirement.

## Console — runtime tweaks & testing (control stage territory)

The in-game console (`~` / `/`) runs Lua against the live game with `/c`, `/sc`,
`/silent-command`, etc. Useful for quick experiments and for testing this repo's
mods without a full restart.

Player-speed equivalents of our data-stage values (note: console modifiers are
**additive on top of base 1**, so use `desired - 1`):

```
/c game.player.force.manual_crafting_speed_modifier = 4   -- => 5x total
/c game.player.force.manual_mining_speed_modifier   = 1   -- => 2x total
```

Reset the starter-kit "already gifted" guard during testing:

```
/c storage.gifted = {}
```

> ⚠️ **Achievements are permanently disabled for a save the moment you run any
> script command** (`/c`, `/sc`, …). Installing any mod also disables them. See
> the wiki **Console** page below.

## Building & shipping (this repo)

- `./validate.sh` — JSON check + `luac -p` syntax parse on every `.lua` + the
  behavioral tests in `tests/`.
- `./validate.sh --ship` — all of the above, then zip each mod and copy it into
  the Factorio mods folder.
- `sudo ./install-lua-tools.sh` — installs `lua` / `luac` for local validation.

A local mod is just a folder `name_version/` (with `info.json` + entry `.lua`)
either unzipped in the mods folder or zipped with that folder as the single top
level. Restart Factorio to pick up changes.

## Sources

### Primary (start here)

- **Data.raw** — every prototype category key (the top-level keys of
  `data.raw`), grouped by type. The map you need before writing any
  `data.raw[...]` edit.
  <https://wiki.factorio.com/Data.raw>
- **Console** — every console command, the `/c` `/sc` script commands, runtime
  `LuaForce` / `LuaPlayer` modifiers, and the achievements caveat. The go-to for
  runtime tweaks and testing.
  <https://wiki.factorio.com/Console>

### Official API docs (property-level detail)

- **Prototype API** — exact property names, types, defaults, and inheritance for
  every prototype (e.g. `CraftingMachinePrototype.crafting_speed`,
  `LabPrototype.researching_speed`).
  <https://lua-api.factorio.com/latest/index-prototype.html>
- **Runtime API** — `LuaPlayer`, `LuaForce`, `LuaSurface`, events, the `storage`
  table — everything available in `control.lua`.
  <https://lua-api.factorio.com/latest/index-runtime.html>

### Background

- **Modding tutorials / portal** on the wiki — getting-started guides and the
  `info.json` schema.
  <https://wiki.factorio.com/Modding>
- **Tutorial:Scripting** — control-stage events and the data/control split.
  <https://wiki.factorio.com/Tutorial:Scripting>
