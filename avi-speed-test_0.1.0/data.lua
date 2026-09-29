-- avi-speed-test / data.lua
--
-- Runs in Factorio's DATA stage: it edits prototype definitions before the
-- game world exists. Changing values here rescales how fast things craft/mine.
--
-- Everything is wrapped in defensive helpers so that if another mod removed a
-- prototype, or a name changed between versions, we just log a message and skip
-- it instead of crashing the whole load (a nil-index error would abort startup).

-- log() output ends up in Factorio's log file (factorio-current.log) and the
-- in-game log, which is handy for confirming what this mod did or skipped.
local function notify(msg)
  log("[avi-speed-test] " .. msg)
end

--- Set `crafting_speed` on a prototype, if it exists.
-- @param category string  data.raw category, e.g. "assembling-machine"
-- @param name     string  prototype name, e.g. "assembling-machine-1"
-- @param speed    number  new crafting speed multiplier
local function set_crafting_speed(category, name, speed)
  local group = data.raw[category]
  local proto = group and group[name]
  if proto then
    proto.crafting_speed = speed
    notify(string.format("crafting_speed of %s/%s -> %s", category, name, tostring(speed)))
  else
    notify(string.format("SKIP: %s/%s not found (another mod or version?)", category, name))
  end
end

--- Set `mining_speed` on a prototype, if it exists.
-- @param category string  data.raw category, e.g. "mining-drill" or "character"
-- @param name     string  prototype name, e.g. "electric-mining-drill"
-- @param speed    number  new mining speed multiplier
local function set_mining_speed(category, name, speed)
  local group = data.raw[category]
  local proto = group and group[name]
  if proto then
    proto.mining_speed = speed
    notify(string.format("mining_speed of %s/%s -> %s", category, name, tostring(speed)))
  else
    notify(string.format("SKIP: %s/%s not found (another mod or version?)", category, name))
  end
end

--- Set `researching_speed` on a prototype, if it exists.
-- Labs do NOT use crafting_speed; their throughput field is researching_speed.
-- @param category string  data.raw category, e.g. "lab"
-- @param name     string  prototype name, e.g. "lab"
-- @param speed    number  new research speed multiplier
local function set_researching_speed(category, name, speed)
  local group = data.raw[category]
  local proto = group and group[name]
  if proto then
    proto.researching_speed = speed
    notify(string.format("researching_speed of %s/%s -> %s", category, name, tostring(speed)))
  else
    notify(string.format("SKIP: %s/%s not found (another mod or version?)", category, name))
  end
end

-- =========================================================================
-- Player (character)
-- =========================================================================

-- How fast the player hand-crafts items in their personal crafting queue.
-- Base game default is 1; higher = faster hand-crafting.
set_crafting_speed("character", "character", 10)

-- How fast the player mines ore/trees/rocks by hand.
-- Base game default is 1 (yields ~0.5 mining "power"); higher = faster mining.
set_mining_speed("character", "character", 10)

-- =========================================================================
-- Assembling machines
-- =========================================================================

-- Crafting speed of each assembler tier. These multiply recipe craft time.
set_crafting_speed("assembling-machine", "assembling-machine-1", 5.0)
set_crafting_speed("assembling-machine", "assembling-machine-2", 7.0)
set_crafting_speed("assembling-machine", "assembling-machine-3", 9.0)

-- =========================================================================
-- Mining drills
-- =========================================================================

-- Speed of the electric mining drill (ore extracted per second scales with this).
set_mining_speed("mining-drill", "electric-mining-drill", 1.0)

-- =========================================================================
-- Furnaces
-- =========================================================================

-- Furnaces use `crafting_speed` for how fast they smelt.
set_crafting_speed("furnace", "stone-furnace", 5)
set_crafting_speed("furnace", "steel-furnace", 7)
set_crafting_speed("furnace", "electric-furnace", 9)

-- =========================================================================
-- Science labs
-- =========================================================================

-- How fast a lab consumes science packs / completes research.
-- Base game default is 1; higher = faster research.
set_researching_speed("lab", "lab", 5)
