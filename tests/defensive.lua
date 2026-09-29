-- tests/defensive.lua
-- Runs data.lua against an EMPTY data.raw so every targeted prototype is
-- missing. The defensive helpers must log SKIP lines and NOT crash, proving
-- the mod won't abort Factorio's startup if another mod/version removed a
-- prototype.
--
-- Usage (from project root):  lua tests/defensive.lua

log = function(msg) io.write(msg, "\n") end
data = { raw = {} }   -- nothing exists

local ok, err = pcall(dofile, "avi-speed-test_0.1.0/data.lua")
if ok then
  io.write("\nDEFENSIVE TEST: survived missing prototypes (no crash)\n")
else
  io.write("\nDEFENSIVE TEST FAILED: " .. tostring(err) .. "\n")
  os.exit(1)
end
