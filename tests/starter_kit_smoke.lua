-- tests/starter_kit_smoke.lua
-- Runs the starter-kit control.lua against a stubbed Factorio runtime and
-- asserts that: (a) the kit is inserted with the right counts, (b) it is given
-- exactly once per player (the storage guard works), and (c) a missing item
-- prototype is skipped instead of crashing.
--
-- Usage (from project root):  lua tests/starter_kit_smoke.lua

-- ---- Fake Factorio runtime ------------------------------------------------
local handlers = {}
script = {
  on_init  = function(fn) handlers.on_init = fn end,
  on_event = function(ev, fn) handlers[ev] = fn end,
}
defines = { events = { on_player_created = "on_player_created" } }
storage = {}   -- Factorio provides this persistent table automatically
log = function(_) end

-- Toggle which items "exist". Start with everything present.
local existing_items = setmetatable({}, { __index = function() return true end })
prototypes = { item = existing_items }

local function make_player(index)
  local inv = {}
  return {
    index = index,
    valid = true,
    position = { x = 0, y = 0 },
    force = "player",
    surface = { spill_item_stack = function(_) end },
    -- player.insert{name=,count=} -> accept everything, record totals
    insert = function(stack)
      inv[stack.name] = (inv[stack.name] or 0) + stack.count
      return stack.count
    end,
    _inv = inv,
  }
end

local p1 = make_player(1)
game = {
  players = {},  -- empty at on_init (new-game path); player created via event
  get_player = function(i) return (i == 1) and p1 or nil end,
}

-- ---- Load the mod ---------------------------------------------------------
dofile("avi-starter-kit_0.1.0/control.lua")

-- ---- Drive the events -----------------------------------------------------
handlers.on_init()                                   -- mod added
handlers[defines.events.on_player_created]({ player_index = 1 })  -- player spawns

-- ---- Assertions -----------------------------------------------------------
local expected = {
  ["solar-panel"] = 16, ["accumulator"] = 4, ["medium-electric-pole"] = 50,
  ["electric-furnace"] = 10, ["electric-mining-drill"] = 10, ["fast-inserter"] = 50,
  ["assembling-machine-3"] = 10, ["express-transport-belt"] = 500,
}
for name, count in pairs(expected) do
  assert(p1._inv[name] == count,
    string.format("expected %d %s, got %s", count, name, tostring(p1._inv[name])))
end

-- Fire creation again: storage guard must prevent a second handout.
handlers[defines.events.on_player_created]({ player_index = 1 })
assert(p1._inv["solar-panel"] == 16, "kit given twice — storage guard failed")

-- Defensive path: a brand new player missing an item prototype should not crash.
existing_items["express-transport-belt"] = nil
setmetatable(existing_items, { __index = function(_, k)
  return k ~= "express-transport-belt"
end })
local p2 = make_player(2)
game.get_player = function(i) return (i == 2) and p2 or nil end
local ok = pcall(function()
  handlers[defines.events.on_player_created]({ player_index = 2 })
end)
assert(ok, "missing item prototype crashed the handler")
assert(p2._inv["express-transport-belt"] == nil, "missing item should be skipped")
assert(p2._inv["solar-panel"] == 16, "other items should still be given")

io.write("STARTER KIT SMOKE TEST: all assertions passed\n")
