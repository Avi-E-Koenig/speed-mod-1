-- avi-starter-kit / control.lua
--
-- Runs in Factorio's CONTROL (runtime) stage: it reacts to game events and
-- manipulates live entities — here, it drops a kit of items into the player's
-- inventory once, the first time they exist in a save.
--
-- This is a different stage from the speed mod (which edits prototypes in
-- data.lua). Inventories only exist at runtime, so this MUST be control.lua.

-- The kit. Item names are base-game internal prototype names (Factorio 2.0).
-- NOTE: the handoff listed "10 drills" twice; that's deduped to a single
-- entry of 10 electric-mining-drill.
local KIT = {
  { name = "solar-panel",           count = 16  },
  { name = "accumulator",           count = 4   },
  { name = "medium-electric-pole",  count = 50  },
  { name = "electric-furnace",      count = 10  },
  { name = "electric-mining-drill", count = 10  },
  { name = "fast-inserter",         count = 50  },
  { name = "assembling-machine-3",  count = 10  },
  { name = "express-transport-belt", count = 500 },
}

local function notify(msg)
  log("[avi-starter-kit] " .. msg)
end

--- Insert the kit into one player's inventory.
-- Defensive: skips any item whose prototype doesn't exist (renamed/removed by
-- another mod or a version change) instead of erroring. Any items that don't
-- fit in the inventory are spilled onto the ground next to the player.
local function give_kit(player)
  if not (player and player.valid) then return end
  for _, entry in pairs(KIT) do
    if prototypes.item[entry.name] then
      local inserted = player.insert{ name = entry.name, count = entry.count }
      local leftover = entry.count - inserted
      if leftover > 0 then
        -- Inventory full: drop the remainder so nothing is lost.
        player.surface.spill_item_stack{
          position = player.position,
          stack = { name = entry.name, count = leftover },
          enable_looted = true,
          force = player.force,
        }
        notify(string.format("%s: inserted %d, spilled %d (inventory full)",
          entry.name, inserted, leftover))
      else
        notify(string.format("%s: gave %d", entry.name, inserted))
      end
    else
      notify(string.format("SKIP: item '%s' not found (another mod or version?)", entry.name))
    end
  end
end

--- Give the kit at most once per player, tracked in persistent `storage`.
local function give_once(player)
  if not (player and player.valid) then return end
  storage.gifted = storage.gifted or {}
  if storage.gifted[player.index] then return end
  storage.gifted[player.index] = true
  give_kit(player)
end

-- Fires once, when this mod is first added to a save. Covers EXISTING saves:
-- any players already present get the kit immediately.
script.on_init(function()
  storage.gifted = {}
  for _, player in pairs(game.players) do
    give_once(player)
  end
end)

-- Fires for each newly created player. Covers NEW saves and new multiplayer
-- joiners. The `give_once` guard prevents double-gifting.
script.on_event(defines.events.on_player_created, function(event)
  give_once(game.get_player(event.player_index))
end)
