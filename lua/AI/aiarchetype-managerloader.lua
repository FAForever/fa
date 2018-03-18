#****************************************************************************
#**
#**  File     :  /lua/AI/aiarchetype-rushland.lua
#**
#**  Summary  : Rush AI
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AIBuildUnits = import('/lua/ai/aibuildunits.lua')
local AIUtils = import('/lua/ai/aiutilities.lua')

local AIAddBuilderTable = import('/lua/ai/AIAddBuilderTable.lua')

function GetHighestBuilder(aiBrain)
    local returnVal = -1
    local base = false

    local returnVal = 0
    local aiType = false

    for k,v in BaseBuilderTemplates do
        if v.FirstBaseFunction then
            local baseVal, baseType = v.FirstBaseFunction(aiBrain)
            #LOG('*DEBUG: testing ' .. k .. ' - Val ' .. baseVal)
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

function EvaluatePlan(aiBrain)
    local base, returnVal = GetHighestBuilder(aiBrain)

    return returnVal
end


function ExecutePlan(aiBrain)
    aiBrain:SetConstantEvaluate(false)
    local behaviors = import('/lua/ai/AIBehaviors.lua')
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

        # Get units out of pool and assign them to the managers
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
            ForkThread(UnitCapWatchThreadSorian, aiBrain)
            ForkThread(behaviors.NukeCheck, aiBrain)
        elseif aiBrain.Uveso then
            ForkThread(LocationRangeManagerThread, aiBrain)
        else
            ForkThread(UnitCapWatchThread, aiBrain)
        end
    end
    if aiBrain.PBM then
        aiBrain:PBMSetEnabled(false)
    end
end

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

#Modeled after GPGs LowMass and LowEnergy functions.
#Runs the whole game and kills off units when the AI hits unit cap.

function UnitCapWatchThread(aiBrain)
    #DUNCAN - Added T1 kill and check every 30 seconds and within 10 of the unit cap
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
                #DUNCAN - dont kill power, it kills the econ, will now be reclaimed
                #local units = aiBrain:GetListOfUnits(categories.TECH1 * categories.ENERGYPRODUCTION * categories.STRUCTURE, true)
                #for k, v in units do
                #    v:Kill()
                #end
                KillPD = false
                KillT1 = false
            end
        end
    end
end

function UnitCapWatchThreadSorian(aiBrain)
    #LOG('*AI DEBUG: UnitCapWatchThreadSorian started')
    while true do
        WaitSeconds(30)
        if GetArmyUnitCostTotal(aiBrain:GetArmyIndex()) > (GetArmyUnitCap(aiBrain:GetArmyIndex()) - 20) then
            local underCap = false

            # More than 1 T3 Power	  ##(aiBrain, number of units to check for, category of units to check for, category of units to kill off)
            underCap = GetAIUnderUnitCap(aiBrain, 1, categories.TECH3 * categories.ENERGYPRODUCTION * categories.STRUCTURE, categories.TECH1 * categories.ENERGYPRODUCTION * categories.STRUCTURE * categories.DRAGBUILD)

            # More than 9 T2/T3 Defense - shields
            if underCap ~= true then
                underCap = GetAIUnderUnitCap(aiBrain, 9, (categories.TECH2 + categories.TECH3) * categories.DEFENSE * categories.STRUCTURE - categories.SHIELD, categories.TECH1 * categories.DEFENSE * categories.STRUCTURE)
            end

            # More than 6 T2/T3 Engineers
            if underCap ~= true then
                underCap = GetAIUnderUnitCap(aiBrain, 6, categories.ENGINEER * (categories.TECH2 + categories.TECH3), categories.TECH1 * categories.ENGINEER - categories.POD)
            end

            # More than 9 T3 Engineers/SCUs
            if underCap ~= true then
                underCap = GetAIUnderUnitCap(aiBrain, 9, categories.ENGINEER * categories.TECH3 + categories.SUBCOMMANDER, categories.TECH2 * categories.ENGINEER - categories.ENGINEERSTATION)
            end

            # More than 24 T3 Land Units minus Engineers
            if underCap ~= true then
                underCap = GetAIUnderUnitCap(aiBrain, 24, categories.TECH3 * categories.MOBILE * categories.LAND - categories.ENGINEER, categories.TECH1 * categories.MOBILE * categories.LAND)
            end

            # More than 9 T3 Air Units minus Scouts
            if underCap ~= true then
                underCap = GetAIUnderUnitCap(aiBrain, 9, categories.TECH3 * categories.MOBILE * categories.AIR - categories.INTELLIGENCE, categories.TECH1 * categories.MOBILE * categories.AIR - categories.SCOUT - categories.POD)
            end

            # More than 9 T3 AntiAir
            if underCap ~= true then
                underCap = GetAIUnderUnitCap(aiBrain, 9, categories.TECH3 * categories.DEFENSE * categories.ANTIAIR, categories.TECH2 * categories.DEFENSE * categories.ANTIAIR)
            end
        end
    end
end

function GetAIUnderUnitCap(aiBrain, num, checkCat, killCat)
    if aiBrain:GetCurrentUnits(checkCat) > num then
        local units = aiBrain:GetListOfUnits(killCat, true)
        for k, v in units do
            v:Kill()
        end
    end
    #If AI under 90% of units cap, return true
    if GetArmyUnitCostTotal(aiBrain:GetArmyIndex()) <= (GetArmyUnitCap(aiBrain:GetArmyIndex()) * .10) then
        return true
    end
    #If not, wait a tick to prevent lag and return false
    WaitTicks(1)
    return false
end

-- Check the distance between locations and set location radius half the distance.
function LocationRangeManagerThread(aiBrain)
    while true do
        -- Check and set the location radius of our main base and expansions
        local BasePositions = BaseRanger(aiBrain)
        -- Check if we have units outside the range of any BaseManager
        -- Get all units from our ArmyPool. These are units without a special platoon or task. They have nothing to do.
        local ArmyPool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
        local ArmyPoolUnits = ArmyPool:GetPlatoonUnits()
        -- Loop over every unit that has no platton and is idle
        for _, unit in ArmyPoolUnits do
            local WeAreInRange = false
            local nearestbase
            if not unit.Dead and EntityCategoryContains(categories.MOBILE - categories.COMMAND, unit) and unit:GetFractionComplete() == 1 and unit:IsIdleState() and not unit:IsMoving() then
                local UnitPos = unit:GetPosition()
                local NeedNavalBase = EntityCategoryContains(categories.NAVAL, unit)
                -- loop over every location and check the distance between the unit and the location
                for location, base in BasePositions do
                    -- If we need a naval base then skip all non naval areas
                    if NeedNavalBase and base.Type ~= 'Naval Area' then
                        continue
                    end
                    -- If we need a land base then skip all naval areas
                    if not NeedNavalBase and base.Type == 'Naval Area' then
                        continue
                    end
                    local dist = VDist2( UnitPos[1], UnitPos[3], base.Pos[1], base.Pos[3] )
                    -- if we are in range of a base, continue. We don't need to move the unit. It's in range of a basemanager
                    if dist < base.Rad then
                        WeAreInRange = true
                        continue
                    end
                    -- remember the nearest base. We will move to it.
                    if not nearestbase or nearestbase.dist > dist then
                        nearestbase = {}
                        nearestbase.Pos = base.Pos
                        nearestbase.dist = dist
                    end
                end
                -- if we are not in range of an base, then move to a base.
                if WeAreInRange == false and not unit.Dead then
                    if nearestbase then
                        if unit.PlatoonHandle and aiBrain:PlatoonExists(unit.PlatoonHandle) then
                            --LOG('* AIDEBUG: LocationRangeManagerThread: Found idle Unit outside Basemanager range! Removing platoonhandle.')
                            unit.PlatoonHandle:Stop()
                            unit.PlatoonHandle:PlatoonDisbandNoAssign()
                        end
                        --LOG('* AIDEBUG: LocationRangeManagerThread: Moving idle unit inside next basemanager range: '..unit:GetBlueprint().BlueprintId..'  ')
                        IssueClearCommands({unit})
                        IssueMove({unit}, nearestbase.Pos)
                    end
                end
            end
        end
        -- watching the unit Cap for AI balance.
        local MaxCap = GetArmyUnitCap(aiBrain:GetArmyIndex())
        LOG('  ')
        LOG(' 00.0 '..(100 / MaxCap * table.getn(aiBrain:GetListOfUnits(categories.MOBILE * categories.ENGINEER, true) ) )..' -  Engineers   - ' )
        LOG(' 50.0 '..(100 / MaxCap * table.getn(aiBrain:GetListOfUnits(categories.MOBILE - categories.ENGINEER - categories.SCOUT, true) ) )..' -  Attack Force  - ' )
        LOG(' 14.0 '..(100 / MaxCap * table.getn(aiBrain:GetListOfUnits(categories.STRUCTURE * categories.MASSEXTRACTION, true) ) )..' -  Extractors    - ' )
        LOG(' 02.0 '..(100 / MaxCap * table.getn(aiBrain:GetListOfUnits(categories.STRUCTURE * categories.MASSSTORAGE, true) ) )..' -  MASSSTORAGE   - ' )
        LOG(' 35.0 '..(100 / MaxCap * table.getn(aiBrain:GetListOfUnits(categories.STRUCTURE - categories.MASSEXTRACTION, true) ) )..' -  Structures    - ' )
        LOG(' 02.4 '..(100 / MaxCap * table.getn(aiBrain:GetListOfUnits(categories.STRUCTURE * categories.FACTORY * categories.LAND, true) ) )..' -  Factory Land  - ' )
        LOG(' 02.4 '..(100 / MaxCap * table.getn(aiBrain:GetListOfUnits(categories.STRUCTURE * categories.FACTORY * categories.AIR, true) ) )..' -  Factory Air   - ' )
        LOG(' 02.4 '..(100 / MaxCap * table.getn(aiBrain:GetListOfUnits(categories.STRUCTURE * categories.FACTORY * categories.NAVAL, true) ) )..' -  Factory Sea   - ' )
        WaitSeconds(10)
    end
end

function BaseRanger(aiBrain)
    local BaseRanger = {}
    if aiBrain.BuilderManagers then
        local BaseLocations = {
            [1] = 'MAIN',
            [2] = 'Naval Area',
            [3] = 'Blank Marker',
            [4] = 'Large Expansion Area',
            [5] = 'Expansion Area',
        }
        -- Check BaseLocations
        for Index, BaseType in BaseLocations do
            -- loop over BuilderManagers and check every location
            for k,v in aiBrain.BuilderManagers do
                -- Check baselocations sorted by BaseLocations Index
                if k ~= BaseType and Scenario.MasterChain._MASTERCHAIN_.Markers[v.FactoryManager.LocationType].type ~= BaseType then
                    -- No BaseLocation. Continue with the next array-key 
                    continue
                end
                -- We found a BaseLocation
                local StartPos = v.FactoryManager.Location
                local StartRad = v.FactoryManager.Radius
                -- This is the maximum base radius.
                local NewMax = 120
                -- Now check against every other baseLocation, and see if we need to reduce our base radius.
                for k2,v2 in aiBrain.BuilderManagers do
                    -- Only check, if start and end marker are not the same.
                    if v ~= v2 then
                        local EndPos = v2.FactoryManager.Location
                        local EndRad = v2.FactoryManager.Radius
                        local dist = VDist2( StartPos[1], StartPos[3], EndPos[1], EndPos[3] )
                        -- This is true, then we compare MAIN base versus expansion location
                        if k == 'MAIN' then
                            -- Mainbase can use 66% of the distance to the next location. But only if we have enough space for the second base (>=30)
                            if NewMax > dist/3*2 and dist/3 >= 30 then
                                NewMax = dist/3*2
                                --LOG('Distance from mainbase['..k..']->['..k2..']='..dist..' Mainbase radius='..StartRad..' Set Radius to '..dist/3*2)
                            -- If we have not enough spacee for the second base, then use half the distance as location radius
                            elseif NewMax > dist/2 and dist/2 >= 30 then
                                NewMax = dist/2
                                --LOG('Distance to location['..k..']->['..k2..']='..dist..' location radius='..StartRad..' Set Radius to '..dist/2)
                            end
                        -- This is true, then we compare expansion location versus MAIN base
                        elseif k2 == 'MAIN' then
                            -- Expansion can use 33% of the distance to the Mainbase.
                            if NewMax > dist - EndRad and dist - EndRad >= 30 then
                                NewMax = dist - EndRad
                                --LOG('Distance to mainbase['..k..']->['..k2..']='..dist..' Mainbase radius='..EndRad..' Set Radius to '..dist - EndRad) 
                            end
                        -- Use as base radius half the way to the next marker
                        else
                            -- if we dont compare against the mainbase then use 50% of the distance to the next location
                            if NewMax > dist/2 and dist/2 >= 30 then
                                NewMax = dist/2
                                --LOG('Distance to location['..k..']->['..k2..']='..dist..' location radius='..StartRad..' Set Radius to '..dist/2) 
                            end
                        end
                    end
                end
                -- Now check for existing managers and set the new value to it
                if v.FactoryManager then
                    v.FactoryManager.Radius = NewMax
                end
                if v.EngineerManager then
                    v.EngineerManager.Radius = NewMax
                end
                if v.PlatoonFormManager then
                    v.PlatoonFormManager.Radius = NewMax
                end
                if v.StrategyManager then
                    v.StrategyManager.Radius = NewMax
                end
                -- Check if we have a terranhigh (or we can't draw the debug baseRanger)
                if StartPos[2] == 0 then
                    StartPos[2] = GetTerrainHeight(StartPos[1], StartPos[3])
                    -- store the TerranHeight inside Factorymanager
                    v.FactoryManager.Location = StartPos
                end
                BaseRanger[k] = {Pos = StartPos, Rad = math.floor(NewMax), Type = BaseType}
            end
        end
        Scenario.MasterChain._MASTERCHAIN_.BaseRanger = Scenario.MasterChain._MASTERCHAIN_.BaseRanger or {}
        Scenario.MasterChain._MASTERCHAIN_.BaseRanger[aiBrain:GetArmyIndex()] = BaseRanger
    end
    return BaseRanger
end











