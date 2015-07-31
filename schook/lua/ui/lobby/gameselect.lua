--- A noop for the purpose of the FAF binary not containing this definition
--
InternalStartSteamDiscoveryService = function() end

local oldCreateUI = CreateUI
--- Overridden so that useSteam == false rather than nil
--  since the steam implementation contains a direct comparison
-- @param over
-- @param exitBehavior
-- @param useSteam always false
--
function CreateUI(over, exitBehavior, useSteam)
    oldCreateUI(over, exitBehavior, false)
end
