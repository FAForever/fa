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
        aiBrain:ForkThread(UnitCapWatchThread)
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

    LOG('*AI DEBUG: ARMY ', repr(aiBrain:GetArmyIndex()), ': Initiating Archetype using ' .. base)
    AIAddBuilderTable.AddGlobalBaseTemplate(aiBrain, 'MAIN', base)
    aiBrain:ForceManagerSort()
end

--- Modeled after GPGs LowMass and LowEnergy functions.
--- Runs the whole game and kills off units when the AI hits unit cap.
---@param aiBrain AIBrain
function UnitCapWatchThread(aiBrain)
    --DUNCAN - Added T1 kill and check every 30 seconds and within 10 of the unit cap
    KillPD = false
    KillT1 = false
    while true do
        WaitSeconds(30)
        if GetArmyUnitCostTotal(aiBrain:GetArmyIndex()) > (GetArmyUnitCap(aiBrain:GetArmyIndex()) - 10) then
            if not KillT1 then
                local units = aiBrain:GetListOfUnits(categories.TECH1 * categories.MOBILE * categories.LAND, true)
                local count = 0
                for k, v in units do
                    v:Kill()
                    count = count + 1
                    if count >= 20 then break end
                end
                KillT1 = true
            elseif not KillPD then
                local units = aiBrain:GetListOfUnits(categories.TECH1 * categories.DEFENSE * categories.DIRECTFIRE * categories.STRUCTURE, true)

                for k, v in units do
                    v:Kill()
                end
                KillPD = true
            else
                --DUNCAN - dont kill power, it kills the econ, will now be reclaimed
                --local units = aiBrain:GetListOfUnits(categories.TECH1 * categories.ENERGYPRODUCTION * categories.STRUCTURE, true)
                --for k, v in units do
                --    v:Kill()
                --end
                KillPD = false
                KillT1 = false
            end
        end
    end
end

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