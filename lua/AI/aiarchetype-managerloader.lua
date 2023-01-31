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
            --LOG('*DEBUG: testing ' .. k .. ' - Val ' .. baseVal)
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

        if aiBrain.Sorian then
            aiBrain:SetupUnderEnergyStatTriggerSorian(0.1)
            aiBrain:SetupUnderMassStatTriggerSorian(0.1)
        else
            aiBrain:SetupUnderEnergyStatTrigger(0.1)
            aiBrain:SetupUnderMassStatTrigger(0.1)
        end

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

        if aiBrain.Sorian then
            aiBrain:ForkThread(UnitCapWatchThreadSorian)
            aiBrain:ForkThread(behaviors.NukeCheck)
        else
            aiBrain:ForkThread(UnitCapWatchThread)
        end
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
function UnitCapWatchThreadSorian(aiBrain)
    --LOG('*AI DEBUG: UnitCapWatchThreadSorian started')
    while true do
        WaitTicks(301)
        if GetArmyUnitCostTotal(aiBrain:GetArmyIndex()) > (GetArmyUnitCap(aiBrain:GetArmyIndex()) - 20) then
            local underCap = false

            -- More than 1 T3 Power	  ----(aiBrain, number of units to check for, category of units to check for, category of units to kill off)
            underCap = GetAIUnderUnitCap(aiBrain, 1, categories.TECH3 * categories.ENERGYPRODUCTION * categories.STRUCTURE, categories.TECH1 * categories.ENERGYPRODUCTION * categories.STRUCTURE * categories.DRAGBUILD)

            -- More than 9 T2/T3 Defense - shields
            if underCap ~= true then
                underCap = GetAIUnderUnitCap(aiBrain, 9, (categories.TECH2 + categories.TECH3) * categories.DEFENSE * categories.STRUCTURE - categories.SHIELD, categories.TECH1 * categories.DEFENSE * categories.STRUCTURE)
            end

            -- More than 6 T2/T3 Engineers
            if underCap ~= true then
                underCap = GetAIUnderUnitCap(aiBrain, 6, categories.ENGINEER * (categories.TECH2 + categories.TECH3), categories.TECH1 * categories.ENGINEER - categories.POD)
            end

            -- More than 9 T3 Engineers/SCUs
            if underCap ~= true then
                underCap = GetAIUnderUnitCap(aiBrain, 9, categories.ENGINEER * categories.TECH3 + categories.SUBCOMMANDER, categories.TECH2 * categories.ENGINEER - categories.ENGINEERSTATION)
            end

            -- More than 24 T3 Land Units minus Engineers
            if underCap ~= true then
                underCap = GetAIUnderUnitCap(aiBrain, 24, categories.TECH3 * categories.MOBILE * categories.LAND - categories.ENGINEER, categories.TECH1 * categories.MOBILE * categories.LAND)
            end

            -- More than 9 T3 Air Units minus Scouts
            if underCap ~= true then
                underCap = GetAIUnderUnitCap(aiBrain, 9, categories.TECH3 * categories.MOBILE * categories.AIR - categories.INTELLIGENCE, categories.TECH1 * categories.MOBILE * categories.AIR - categories.SCOUT - categories.POD)
            end

            -- More than 9 T3 AntiAir
            if underCap ~= true then
                underCap = GetAIUnderUnitCap(aiBrain, 9, categories.TECH3 * categories.DEFENSE * categories.ANTIAIR, categories.TECH2 * categories.DEFENSE * categories.ANTIAIR)
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