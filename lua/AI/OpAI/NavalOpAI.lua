--***************************************************************************
--**  File     :  /lua/ai/OpAI/NavalOpAI.lua
--**
--**  Summary  : OpAI that reacts to certain defaulted events
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local OpAI = import("/lua/ai/opai/baseopai.lua").OpAI
local GenerateNavalOSB = import("/lua/ai/opai/generatenaval.lua")

local mathMax = math.max
local tableGetn = table.getn
local categoriesNaval = categories.NAVAL

---@class NavalOpAIData: AddOpAIData, NavalOpAIGeneratorData

---@class NavalOpAI : OpAI
---@overload fun(): NavalOpAI
local NavalAI = {}
---@param brain CampaignAIBrain
---@param location string
---@param name string
---@param data NavalOpAIData
function NavalAI:Create(brain, location, name, data)
    local bManager = brain.BaseManagers[location]

    local numLevels = data.NumLevels or 1

    local maxMultiplier = data.MaxMultiplier or 1
    local minMultiplier = data.MinMultiplier or maxMultiplier

    local numFactories = tableGetn(bManager:GetAllBaseFactories(categoriesNaval))
    local base = mathMax(numFactories, 1)

    local maxFrigates = data.MaxFrigates or (base * maxMultiplier)
    if maxFrigates == 0 then maxFrigates = 1 end
    local minFrigates = data.MinFrigates or (base * minMultiplier)
    if minFrigates == 0 then minFrigates = 1 end

    local faction = brain:GetFactionIndex()

    local navalTable = GenerateNavalOSB.GenerateNavalOSB(name, numLevels, minFrigates, maxFrigates, faction, data)

    -- Create the actual OpAI thing here passing in the rebuilt data
    OpAI.Create(self, brain, location, navalTable, name .. '_' .. location .. '_NavalAI', data)
end

NavalOpAI = Class(OpAI--[[@as fa-class]])(NavalAI)

---@param brain CampaignAIBrain
---@param location string
---@param name string
---@param data table
---@return NavalOpAI
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