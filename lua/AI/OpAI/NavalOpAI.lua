--***************************************************************************
--**  File     :  /lua/ai/OpAI/NavalOpAI.lua
--**
--**  Summary  : OpAI that reacts to certain defaulted events
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local OpAI = import("/lua/ai/opai/baseopai.lua").OpAI
local GenerateNavalOSB = import("/lua/ai/opai/generatenaval.lua")

---@class NavalOpAI : OpAI
NavalOpAI = Class(OpAI) {
    ---@param self AIBrain
    ---@param brain AIBrain
    ---@param location string
    ---@param name string
    ---@param data number
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

---@param brain AIBrain
---@param location string
---@param name string
---@param data number
---@return unknown
function CreateNavalAI(brain, location, name, data)
    local navalAI = NavalOpAI()
    navalAI:Create(brain, location, name, data)
    return navalAI
end

-- Kept for Mod Support
local AIUtils = import("/lua/ai/aiutilities.lua")
local ScenarioFramework = import("/lua/scenarioframework.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local ScenarioPlatoonAI = import("/lua/scenarioplatoonai.lua")

local UCBC = '/lua/editor/unitcountbuildconditions.lua'
local BMBC = '/lua/editor/basemanagerbuildconditions.lua'
local MIBC = '/lua/editor/miscbuildconditions.lua'
local BMPT = '/lua/ai/opai/basemanagerplatoonthreads.lua'