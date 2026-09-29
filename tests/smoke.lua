-- tests/smoke.lua
-- Runs data.lua against a stubbed Factorio data stage and asserts that each
-- directive actually wrote the intended value to its prototype.
--
-- Usage (from project root):  lua tests/smoke.lua

log = function(msg) io.write(msg, "\n") end

local function mk(field, val) local t = {} t[field] = val return t end

-- Fake just enough of data.raw to cover every prototype the mod touches,
-- each starting at the base-game default of 1.
data = { raw = {
  character = { character = { crafting_speed = 1, mining_speed = 1 } },
  ["assembling-machine"] = {
    ["assembling-machine-1"] = mk("crafting_speed", 1),
    ["assembling-machine-2"] = mk("crafting_speed", 1),
    ["assembling-machine-3"] = mk("crafting_speed", 1),
  },
  ["mining-drill"] = { ["electric-mining-drill"] = mk("mining_speed", 1) },
  furnace = {
    ["stone-furnace"]    = mk("crafting_speed", 1),
    ["steel-furnace"]    = mk("crafting_speed", 1),
    ["electric-furnace"] = mk("crafting_speed", 1),
  },
  lab = { lab = mk("researching_speed", 1) },
} }

dofile("avi-speed-test_0.1.0/data.lua")

-- These mirror the current values in data.lua. If you change a value there,
-- update the matching assertion here so the test stays meaningful.
local function check(cond, msg) assert(cond, "assertion failed: " .. msg) end
check(data.raw.character.character.crafting_speed == 10, "player hand-craft = 10")
check(data.raw.character.character.mining_speed   == 10, "player mining = 10")
check(data.raw["assembling-machine"]["assembling-machine-1"].crafting_speed == 5.0, "asm1 = 5")
check(data.raw["assembling-machine"]["assembling-machine-2"].crafting_speed == 7.0, "asm2 = 7")
check(data.raw["assembling-machine"]["assembling-machine-3"].crafting_speed == 9.0, "asm3 = 9")
check(data.raw["mining-drill"]["electric-mining-drill"].mining_speed == 1.0, "drill = 1")
check(data.raw.furnace["stone-furnace"].crafting_speed    == 5, "stone furnace = 5")
check(data.raw.furnace["steel-furnace"].crafting_speed    == 7, "steel furnace = 7")
check(data.raw.furnace["electric-furnace"].crafting_speed == 9, "electric furnace = 9")
check(data.raw.lab.lab.researching_speed == 5, "lab = 5")

io.write("\nSMOKE TEST: all assertions passed\n")
