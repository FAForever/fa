--****************************************************************************
--**  File     :  /lua/AI/aiarchetype-rushland.lua
--**
--**  Summary  : Rush AI
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AIAddBuilderTable = import("/lua/ai/aiaddbuildertable.lua")

---@param aiBrain AIBrain
---@return any
---@return integer
---@return boolean
function GetHighestBuilder(aiBrain)
    local base = false
    local returnVal = 0
    local aiType = false

    for k,v in BaseBuilderTemplates do
        if v.FirstBaseFunction then
            local baseVal, baseType = v.FirstBaseFunction(aiBrain)
            -- LOG('*DEBUG: testing ' .. k .. ' - Val ' .. baseVal)
            if baseVal > returnVal then
                returnVal = baseVal
                base = k
                aiType = baseType
            end
        end
    end

    if base then
        return base, returnVal, aiType
    end

    return false
end

---@param aiBrain AIBrain
---@return integer
function EvaluatePlan(aiBrain)
    local base, returnVal = GetHighestBuilder(aiBrain)
    return returnVal
end

---@param aiBrain AIBrain
function ExecutePlan(aiBrain)
    aiBrain:SetConstantEvaluate(false)
    local behaviors = import("/lua/ai/aibehaviors.lua")
    WaitSeconds(1)
    if not aiBrain.BuilderManagers.MAIN.FactoryManager:HasBuilderList() then
        aiBrain:SetResourceSharing(true)
        SetupMainBase(aiBrain)

        -- Get units out of pool and assign them to the managers
        local mainManagers = aiBrain.BuilderManagers.MAIN
        local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
        for k,v in pool:GetPlatoonUnits() do
            if EntityCategoryContains(categories.ENGINEER, v) then
                mainManagers.EngineerManager:AddUnit(v)
            elseif EntityCategoryContains(categories.FACTORY * categories.STRUCTURE, v) then
                mainManagers.FactoryManager:AddFactory(v)
            end
        end
        aiBrain:ForkThread(UnitCapWatchThread, 0.9, 30)
    end
    if aiBrain.PBM then
        aiBrain:PBMSetEnabled(false)
    end
end

---@param aiBrain AIBrain
function SetupMainBase(aiBrain)
    local base, returnVal, baseType = GetHighestBuilder(aiBrain)

    local per = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
    ScenarioInfo.ArmySetup[aiBrain.Name].AIBase = base
    if per != 'adaptive' and per != 'sorianadaptive' then
        ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality = baseType
    end

    LOG('*AI DEBUG: ARMY ', tostring(aiBrain:GetArmyIndex()), ': Initiating Archetype using ' .. base)
    AIAddBuilderTable.AddGlobalBaseTemplate(aiBrain, 'MAIN', base)
    aiBrain:ForceManagerSort()
end

---@class UnitCapCullEntry
---@field Label string -- Identifier for the cull group (e.g., 'Walls')
---@field categories any -- Typically a category expression used by the AI
---@field compareTo any? -- The category to compare against. If nil, culls based on cullRatio alone.
---@field cullRatio number -- The ratio (0.0 to 1.0) of units to cull under pressure
---@field checkAttached boolean -- Whether attached units should be considered

---@type UnitCapCullEntry[]
local UnitCapCullTable = {
    {
        Label = 'Walls',
        categories = categories.WALL * categories.STRUCTURE * categories.DEFENSE - categories.CIVILIAN,
        cullRatio = 0.4,
        checkAttached = false
    },
    {
        Label = 'T1DefensiveUnits',
        categories = categories.TECH1 * categories.DEFENSE * categories.STRUCTURE * (categories.DIRECTFIRE + categories.INDIRECTFIRE),
        cullRatio = 0.3,
        checkAttached = true
    },
    {
        Label = 'T1AirUnits',
        categories = categories.MOBILE * categories.TECH1 * categories.AIR - categories.TRANSPORTFOCUS - categories.ENGINEER,
        cullRatio = 0.2,
        checkAttached = true
    },
    {
        Label = 'T1NavalUnits',
        categories = categories.MOBILE * categories.TECH1 * categories.NAVAL - categories.ENGINEER,
        cullRatio = 0.2,
        checkAttached = true
    },
    {
        Label = 'T1LandUnits',
        categories = categories.MOBILE * categories.TECH1 * categories.LAND - categories.ENGINEER,
        cullRatio = 0.2,
        checkAttached = true
    },
    {
        Label = 'T1LandEngineer',
        categories = categories.MOBILE * categories.TECH1 * categories.LAND * categories.ENGINEER - categories.COMMAND,
        compareTo = categories.MOBILE * categories.LAND * categories.ENGINEER * (categories.TECH2 + categories.TECH3)- categories.COMMAND - categories.SUBCOMMANDER - categories.POD - categories.FIELDENGINEER,
        cullRatio = 0.2,
        checkAttached = true,
    },
}

--- Runs the whole game and kills off units when the AI hits get close to unit cap.
---@param aiBrain AIBrain
---@param unitCapDesiredRatio number
---@param maxCullNumber number
function UnitCapWatchThread(aiBrain, unitCapDesiredRatio, maxCullNumber)
    -- Remember that this table will run in order, so we want the most deisred to cull first
    -- There is also two configurable settings
    -- cullPressure - Indicates how many units we want to cull per pass. The closer we are to the unit cap the more units we will cull.
    --                0.8 is the percentage towards the cap we want to aim for.
    -- dynamicRatioThreshold - What sort of ratio we want when performing compares. So that we dont instantly cull lots of units just because 
    -- one of the next tier is available. 9 is the multiplier for aggresive unit culling.

    while true do
        WaitSeconds(30)
        local brainIndex = aiBrain:GetArmyIndex()
        local currentCount = GetArmyUnitCostTotal(brainIndex)
        local cap = GetArmyUnitCap(brainIndex)
        local capRatio = currentCount / cap
        LOG('Current cap ratio '..tostring(capRatio))
        if capRatio > unitCapDesiredRatio then
            LOG('Cull initialized current cap ratio is '..tostring(capRatio))
            local cullPressure = math.max(0, math.min((capRatio - 0.80) / 0.2, 1))
            local dynamicRatioThreshold = math.max(0.1, 2.0 - (capRatio - 0.80) * 9)
            local culledUnitCount = 0
            for _, cullType in UnitCapCullTable do
                local currentUnits = aiBrain:GetCurrentUnits(cullType.categories)
                local targetRatio = 1.0 -- Default for non-comparison types
                if cullType.compareTo then
                    local higherTierUnits = aiBrain:GetCurrentUnits(cullType.compareTo)
                    targetRatio = (higherTierUnits > 0) and (currentUnits / higherTierUnits) or 0
                end

                if currentUnits > 0 and targetRatio > (cullType.compareTo and dynamicRatioThreshold or 0) then
                    local toCull = math.min(currentUnits, math.ceil(currentUnits * cullType.cullRatio * cullPressure))
                    culledUnitCount = culledUnitCount + CullUnitsOfCategory(aiBrain, cullType.categories, toCull, cullType.checkAttached)
                end
                if culledUnitCount >= maxCullNumber then break end
            end
        end
    end
end

function CullUnitsOfCategory(aiBrain, category, toCull, checkAttached)
    -- Culls units based on the categories passed in
    local units = aiBrain:GetListOfUnits(category, true)
    local culledUnitCount = 0
    for k, v in units do
        if not v.Dead then
            if checkAttached and v:IsUnitState('Attached') then
                continue
            end
            LOG('Culling init '..tostring(v.UnitId))
            culledUnitCount = culledUnitCount + 1
            v:Kill()
            if culledUnitCount >= toCull then
                return culledUnitCount
            end
        end
    end
    return culledUnitCount
end

---@deprecated Kept for mod support
---@param aiBrain AIBrain
---@param num number
---@param checkCat any
---@param killCat any
---@return boolean
function GetAIUnderUnitCap(aiBrain, num, checkCat, killCat)
    if aiBrain:GetCurrentUnits(checkCat) > num then
        local units = aiBrain:GetListOfUnits(killCat, true)
        for k, v in units do
            v:Kill()
        end
    end
    --If AI under 90% of units cap, return true
    if GetArmyUnitCostTotal(aiBrain:GetArmyIndex()) <= (GetArmyUnitCap(aiBrain:GetArmyIndex()) * .10) then
        return true
    end
    --If not, wait a tick to prevent lag and return false
    WaitTicks(1)
    return false
end

-- Kept For Mod Support
local AIBuildUnits = import("/lua/ai/aibuildunits.lua")
local AIUtils = import("/lua/ai/aiutilities.lua")