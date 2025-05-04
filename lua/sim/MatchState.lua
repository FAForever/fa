--**************************************************************************************************
--** Shared under the MIT license
--**************************************************************************************************

function Setup()
    -- retrieve the correct instance of the victory condition
    local victoryCondition = ScenarioInfo.Options.Victory
    local victoryConditionInstance = import("/lua/sim/Matchstate/VictoryConditionFactory.lua").GetVictoryConditionInstance(victoryCondition)

    -- start checking the game state
    victoryConditionInstance:Setup()
end
