--===================================================================================
-- This module (scenarioEnvironment.lua) is used during sim init to load the
-- save file and script file. It is accessible as the global "ScenarioInfo.Env",
-- or just by importing it.
--
-- The save and script files are loaded directly into this module's environment,
-- so by defining functions like "OnPopulate" and "OnStart" they can override
-- the default behavior.
--
-- Typically the save file defines a single table, 'Scenario', containing all of
-- the save data; the script file uses that table to actually populate the world
-- with stuff.
--===================================================================================

---@param scen UIScenarioInfo
function OnPopulate(scen)
    --import("/lua/sim/scenarioutilities.lua").InitializeArmies()
end

---@param scen UIScenarioInfo
function OnStart(scen)
end
