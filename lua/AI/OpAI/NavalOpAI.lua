--***************************************************************************
--*
--**  File     :  /lua/ai/OpAI/NavalOpAI.lua
--**
--**  Summary  : OpAI that reacts to certain defaulted events
--#**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local AIUtils = import('/lua/ai/aiutilities.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')
local OpAI = import('/lua/ai/OpAI/BaseOpAI.lua').OpAI

local GenerateNavalOSB = import('/lua/ai/OpAI/GenerateNaval.lua')

local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local BMBC = '/lua/editor/BaseManagerBuildConditions.lua'
local MIBC = '/lua/editor/MiscBuildConditions.lua'
local BMPT = '/lua/ai/opai/BaseManagerPlatoonThreads.lua'

NavalOpAI = Class(OpAI) {
    Create = function(self, brain, location, name, data)
        local bManager = brain.BaseManagers[location]
        
        local numLevels = data.NumLevels or 1
        
        local maxMultiplier = data.MaxMultiplier or 1
        local minMultiplier = data.MinMultiplier or maxMultiplier
        
        local maxFrigates = data.MaxFrigates or ( (table.getn(bManager:GetAllBaseFactories(categories.NAVAL)) or 1) * maxMultiplier )
        if maxFrigates == 0 then maxFrigates = 1 end
        local minFrigates = data.MinFrigates or ( (table.getn(bManager:GetAllBaseFactories(categories.NAVAL)) or 1) * minMultiplier )
        if minFrigates == 0 then minFrigates = 1 end
        
        local faction = 'S'
        local brainFaction = brain:GetFactionIndex()
        if brainFaction == 1 then faction = 'U'
        elseif brainFaction == 2 then faction = 'A'
        elseif brainFaction == 3 then faction = 'C'
        end
    
        local navalTable = GenerateNavalOSB.GenerateNavalOSB(name, numLevels, minFrigates, maxFrigates, faction, data)
        
        -- Create the actual OpAI thing here passing in the rebuilt data
        OpAI.Create(self, brain, location, navalTable, name .. '_' .. location .. '_NavalAI', data)

    end,
}

function CreateNavalAI(brain, location, name, data)
    local navalAI = NavalOpAI()
    navalAI:Create(brain, location, name, data)
    return navalAI
end