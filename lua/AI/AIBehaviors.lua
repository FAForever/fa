-----------------------------------------------------------------
-- File     :  /lua/AIBehaviors.lua
-- Author(s): Robert Oates, Gautam Vasudevan, ...?
-- Summary  :
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local AIUtils = import('/lua/ai/aiutilities.lua')
local Utilities = import('/lua/utilities.lua')
local AIBuildStructures = import('/lua/ai/aibuildstructures.lua')
local UnitUpgradeTemplates = import('/lua/upgradetemplates.lua').UnitUpgradeTemplates
local StructureUpgradeTemplates = import('/lua/upgradetemplates.lua').StructureUpgradeTemplates
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local AIAttackUtils = import('/lua/ai/aiattackutilities.lua')
local TriggerFile = import('/lua/scenariotriggers.lua')
local UCBC = import('/lua/editor/UnitCountBuildConditions.lua')
local SBC = import('/lua/editor/SorianBuildConditions.lua')
local SUtils = import('/lua/AI/sorianutilities.lua')

-- CDR ADD BEHAVIORS
function CDRRunAway(aiBrain, cdr)
    if cdr:GetHealthPercent() < 0.7 then
        AIUtils.AIFindDefensiveArea(aiBrain, cdr, categories.DEFENSE * categories.ANTIAIR, 10000)
        local cdrPos = cdr:GetPosition()
        local nmeAir = aiBrain:GetUnitsAroundPoint(categories.AIR, cdrPos, 25, 'Enemy')
        local nmeLand = aiBrain:GetUnitsAroundPoint(categories.LAND, cdrPos, 25, 'Enemy')
        local nmeHardcore = aiBrain:GetUnitsAroundPoint(categories.EXPERIMENTAL, cdrPos, 25, 'Enemy')
        if nmeAir > 3 or nmeLand > 3 or nmeHardcore > 0 then
            if cdr:IsUnitState('Building') then
                cdr.UnitBeingBuiltBehavior = cdr.UnitBeingBuilt
            end

            CDRRevertPriorityChange(aiBrain, cdr)
            local category
            if nmeAir > 3 then
                category = categories.DEFENSE * categories.ANTIAIR
            else
                category = categories.DEFENSE * categories.DIRECTFIRE
            end

            local canTeleport = cdr:HasEnhancement('Teleporter')
            local runSpot, prevSpot
            local plat = aiBrain:MakePlatoon('', '')
            aiBrain:AssignUnitsToPlatoon(plat, {cdr}, 'support', 'None')
            repeat
                if canTeleport then
                    runSpot = AIUtils.AIFindDefensiveArea(aiBrain, cdr, category, 10000)
                else
                    runSpot = AIUtils.AIFindDefensiveArea(aiBrain, cdr, category, 50)
                end

                if not prevSpot or runSpot[1] ~= prevSpot[1] or runSpot[3] ~= prevSpot[3] then
                    plat:Stop()
                    if VDist2(cdrPos[1], cdrPos[3], runSpot[1], runSpot[3]) >= 10 then
                        if canTeleport then
                            IssueTeleport({cdr}, runSpot)
                        else
                            cmd = plat:MoveToLocation(runSpot, false)
                        end
                    end
                end
                WaitSeconds(3)

                if not cdr.Dead then
                    cdrPos = cdr:GetPosition()
                    nmeAir = aiBrain:GetUnitsAroundPoint(categories.AIR, cdrPos, 25, 'Enemy')
                    nmeLand = aiBrain:GetUnitsAroundPoint(categories.LAND, cdrPos, 25, 'Enemy')
                    nmeHardcore = aiBrain:GetUnitsAroundPoint(categories.EXPERIMENTAL, cdrPos, 25, 'Enemy')
                end
            until cdr.Dead or (nmeAir < 2 and nmeLand < 2 and nmeHardcore == 0) or cdr:GetHealthPercent() > 0.7

            IssueClearCommands({cdr})
        end
    end
end

function CDROverCharge(aiBrain, cdr)
    local weapBPs = cdr:GetBlueprint().Weapon
    local weapon

    for k, v in weapBPs do
        if v.Label == 'OverCharge' then
            weapon = v
            break
        end
    end

    cdr.UnitBeingBuiltBehavior = false

    -- Added for ACUs starting near each other
    if GetGameTimeSeconds() < 60 then
        return
    end

    -- Increase distress on non-water maps
    local distressRange = 60
    if cdr:GetHealthPercent() > 0.8 and aiBrain:GetMapWaterRatio() < 0.4 then
        distressRange = 100
    end

    -- Increase attack range for a few mins on small maps
    local maxRadius = weapon.MaxRadius + 10
    local mapSizeX, mapSizeZ = GetMapSize()
    if cdr:GetHealthPercent() > 0.8
        and GetGameTimeSeconds() < 660
        and GetGameTimeSeconds() > 243
        and mapSizeX <= 512 and mapSizeZ <= 512
        and ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality ~= 'turtle'
        and ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality ~= 'defense'
        and ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality ~= 'rushnaval'
        then
        maxRadius = 256
    end

    -- Take away engineers too
    local cdrPos = cdr.CDRHome
    local numUnits = aiBrain:GetNumUnitsAroundPoint(categories.LAND - categories.SCOUT, cdrPos, (maxRadius), 'Enemy')
    local distressLoc = aiBrain:BaseMonitorDistressLocation(cdrPos)
    local overCharging = false

    -- Don't move if upgrading
    if cdr:IsUnitState("Upgrading") or cdr:IsUnitState("Enhancing") then
        return
    end

    if Utilities.XZDistanceTwoVectors(cdrPos, cdr:GetPosition()) > maxRadius then
        return
    end

    if numUnits > 0 or (not cdr.DistressCall and distressLoc and Utilities.XZDistanceTwoVectors(distressLoc, cdrPos) < distressRange) then
        if cdr.UnitBeingBuilt then
            cdr.UnitBeingBuiltBehavior = cdr.UnitBeingBuilt
        end
        local plat = aiBrain:MakePlatoon('', '')
        aiBrain:AssignUnitsToPlatoon(plat, {cdr}, 'support', 'None')
        plat:Stop()
        local priList = {
            categories.EXPERIMENTAL,
            categories.TECH3 * categories.INDIRECTFIRE,
            categories.TECH3 * categories.MOBILE,
            categories.TECH2 * categories.INDIRECTFIRE,
            categories.MOBILE * categories.TECH2,
            categories.TECH1 * categories.INDIRECTFIRE,
            categories.TECH1 * categories.MOBILE,
            categories.ALLUNITS
        }

        local target
        local continueFighting = true
        local counter = 0
        local cdrThreat = cdr:GetBlueprint().Defense.SurfaceThreatLevel or 75
        local enemyThreat
        repeat
            overCharging = false
            if counter >= 5 or not target or target.Dead or Utilities.XZDistanceTwoVectors(cdrPos, target:GetPosition()) > maxRadius then
                counter = 0
                searchRadius = 30
                repeat
                    searchRadius = searchRadius + 30
                    for k, v in priList do
                        target = plat:FindClosestUnit('Support', 'Enemy', true, v)
                        if target and Utilities.XZDistanceTwoVectors(cdrPos, target:GetPosition()) <= searchRadius then
                            local cdrLayer = cdr:GetCurrentLayer()
                            local targetLayer = target:GetCurrentLayer()
                            if not (cdrLayer == 'Land' and (targetLayer == 'Air' or targetLayer == 'Sub' or targetLayer == 'Seabed')) and
                               not (cdrLayer == 'Seabed' and (targetLayer == 'Air' or targetLayer == 'Water')) then
                                break
                            end
                        end
                        target = false
                    end
                until target or searchRadius >= maxRadius

                if target then
                    local targetPos = target:GetPosition()

                    -- If inside base dont check threat, just shoot!
                    if Utilities.XZDistanceTwoVectors(cdr.CDRHome, cdr:GetPosition()) > 45 then
                        enemyThreat = aiBrain:GetThreatAtPosition(targetPos, 1, true, 'AntiSurface')
                        enemyCdrThreat = aiBrain:GetThreatAtPosition(targetPos, 1, true, 'Commander')
                        friendlyThreat = aiBrain:GetThreatAtPosition(targetPos, 1, true, 'AntiSurface', aiBrain:GetArmyIndex())
                        if enemyThreat - enemyCdrThreat >= friendlyThreat + (cdrThreat / 1.5) then
                            break
                        end
                    end

                    if aiBrain:GetEconomyStored('ENERGY') >= weapon.EnergyRequired and target and not target.Dead then
                        overCharging = true
                        IssueClearCommands({cdr})
                        IssueOverCharge({cdr}, target)
                    elseif target and not target.Dead then -- Commander attacks even if not enough energy for overcharge
                        IssueClearCommands({cdr})
                        IssueMove({cdr}, targetPos)
                        IssueMove({cdr}, cdr.CDRHome)
                    end
                elseif distressLoc then
                    enemyThreat = aiBrain:GetThreatAtPosition(distressLoc, 1, true, 'AntiSurface')
                    enemyCdrThreat = aiBrain:GetThreatAtPosition(distressLoc, 1, true, 'Commander')
                    friendlyThreat = aiBrain:GetThreatAtPosition(distressLoc, 1, true, 'AntiSurface', aiBrain:GetArmyIndex())
                    if enemyThreat - enemyCdrThreat >= friendlyThreat + (cdrThreat / 3) then
                        break
                    end
                    if distressLoc and (Utilities.XZDistanceTwoVectors(distressLoc, cdrPos) < distressRange) then
                        IssueClearCommands({cdr})
                        IssueMove({cdr}, distressLoc)
                        IssueMove({cdr}, cdr.CDRHome)
                    end
                end
            end

            if overCharging then
                while target and not target.Dead and not cdr.Dead and counter <= 5 do
                    WaitSeconds(0.5)
                    counter = counter + 0.5
                end
            else
                WaitSeconds(5)
                counter = counter + 5
            end

            distressLoc = aiBrain:BaseMonitorDistressLocation(cdrPos)
            if cdr.Dead then
                return
            end

            if aiBrain:GetNumUnitsAroundPoint(categories.LAND - categories.SCOUT, cdrPos, maxRadius, 'Enemy') <= 0
                and (not distressLoc or Utilities.XZDistanceTwoVectors(distressLoc, cdrPos) > distressRange) then
                continueFighting = false
            end
            -- If com is down to yellow then dont keep fighting
            if (cdr:GetHealthPercent() < 0.75) and Utilities.XZDistanceTwoVectors(cdr.CDRHome, cdr:GetPosition()) > 30 then
                continueFighting = false
            end
        until not continueFighting or not aiBrain:PlatoonExists(plat)

        IssueClearCommands({cdr})

        -- Finish the unit
        if cdr.UnitBeingBuiltBehavior and not cdr.UnitBeingBuiltBehavior:BeenDestroyed() and cdr.UnitBeingBuiltBehavior:GetFractionComplete() < 1 then
            IssueRepair({cdr}, cdr.UnitBeingBuiltBehavior)
        end
        cdr.UnitBeingBuiltBehavior = false
    end
end

function CDRRevertPriorityChange(aiBrain, cdr)
    if cdr.PreviousPriority and cdr.Platoon and aiBrain:PlatoonExists(cdr.Platoon) then
        aiBrain:PBMSetPriority(cdr.Platoon, cdr.PreviousPriority)
    end
end

function CDRReturnHome(aiBrain, cdr)
    -- This is a reference... so it will autoupdate
    local cdrPos = cdr:GetPosition()
    local distSqAway = 1600
    local loc = cdr.CDRHome
    if not cdr.Dead and VDist2Sq(cdrPos[1], cdrPos[3], loc[1], loc[3]) > distSqAway then
        local plat = aiBrain:MakePlatoon('', '')
        aiBrain:AssignUnitsToPlatoon(plat, {cdr}, 'support', 'None')
        repeat
            CDRRevertPriorityChange(aiBrain, cdr)
            if not aiBrain:PlatoonExists(plat) then
                return
            end
            IssueStop({cdr})
            IssueMove({cdr}, loc)
            cdr.GoingHome = true
            WaitSeconds(7)
        until cdr.Dead or VDist2Sq(cdrPos[1], cdrPos[3], loc[1], loc[3]) <= distSqAway

        cdr.GoingHome = false
        IssueClearCommands({cdr})
    end
end

function SetCDRHome(cdr, plat)
    cdr.CDRHome = table.copy(cdr:GetPosition())
end

function CommanderBehavior(platoon)
    for _, v in platoon:GetPlatoonUnits() do
        if not v.Dead and not v.CommanderThread then
            v.CommanderThread = v:ForkThread(CommanderThread, platoon)
        end
    end
end

function CommanderBehaviorImproved(platoon)
    for _, v in platoon:GetPlatoonUnits() do
        if not v.Dead and not v.CommanderThread then
            v.CommanderThread = v:ForkThread(CommanderThreadImproved, platoon)
        end
    end
end

function CommanderThread(cdr, platoon)
    SetCDRHome(cdr, platoon)

    local aiBrain = cdr:GetAIBrain()
    aiBrain:BuildScoutLocations()
    while not cdr.Dead do
        WaitTicks(1)
        -- Overcharge
        if not cdr.Dead then CDROverCharge(aiBrain, cdr) end
        WaitTicks(1)

        -- Go back to base
        if not cdr.Dead then CDRReturnHome(aiBrain, cdr) end
        WaitTicks(1)

        -- Call platoon resume building deal...
        if not cdr.Dead and cdr:IsIdleState() and not cdr.GoingHome and not cdr:IsUnitState("Building")
        and not cdr:IsUnitState("Attacking") and not cdr:IsUnitState("Repairing") and not cdr:IsUnitState("Upgrading") then
            if not cdr.EngineerBuildQueue or table.getn(cdr.EngineerBuildQueue) == 0 then
                local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
                aiBrain:AssignUnitsToPlatoon(pool, {cdr}, 'Unassigned', 'None')
            elseif cdr.EngineerBuildQueue and table.getn(cdr.EngineerBuildQueue) ~= 0 then
                if not cdr.NotBuildingThread then
                    cdr.NotBuildingThread = cdr:ForkThread(platoon.WatchForNotBuilding)
                end
            end
        end
    end
end

function CommanderThreadImproved(cdr, platoon)
    local aiBrain = cdr:GetAIBrain()
    aiBrain:BuildScoutLocations()
    -- Added to ensure we know the start locations (thanks to Sorian).
    SetCDRHome(cdr, platoon)

    while not cdr.Dead do
        -- Overcharge
        if not cdr.Dead then CDROverCharge(aiBrain, cdr) end
        WaitTicks(1)

        -- Go back to base
        if not cdr.Dead then CDRReturnHome(aiBrain, cdr) end
        WaitTicks(1)

        -- Call platoon resume building deal...
        if not cdr.Dead and cdr:IsIdleState() and not cdr.GoingHome and not cdr:IsUnitState("Moving")
        and not cdr:IsUnitState("Building") and not cdr:IsUnitState("Guarding")
        and not cdr:IsUnitState("Attacking") and not cdr:IsUnitState("Repairing")
        and not cdr:IsUnitState("Upgrading") and not cdr:IsUnitState("Enhancing") then
            -- if we have nothing to build...
            if not cdr.EngineerBuildQueue or table.getn(cdr.EngineerBuildQueue) == 0 then
                -- check if the we have still a platton assigned to the CDR
                if cdr.PlatoonHandle then
                    local platoonUnits = cdr.PlatoonHandle:GetPlatoonUnits() or 1
                    -- only disband the platton if we have 1 unit, plan and buildername. (NEVER disband the armypool platoon!!!)
                    if table.getn(platoonUnits) == 1 and cdr.PlatoonHandle.PlanName and cdr.PlatoonHandle.BuilderName then
                        --SPEW('ACU PlatoonHandle found. Plan: '..cdr.PlatoonHandle.PlanName..' - Builder '..cdr.PlatoonHandle.BuilderName..'. Disbanding CDR platoon!')
                        cdr.PlatoonHandle:PlatoonDisband()
                    end
                end
                -- get the global armypool platoon
                local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
                -- assing the CDR to the armypool
                aiBrain:AssignUnitsToPlatoon(pool, {cdr}, 'Unassigned', 'None')
            -- if we have a BuildQueue then continue building
            elseif cdr.EngineerBuildQueue and table.getn(cdr.EngineerBuildQueue) ~= 0 then
                if not cdr.NotBuildingThread then
                    cdr.NotBuildingThread = cdr:ForkThread(platoon.WatchForNotBuilding)
                end
            end
        end
        WaitTicks(1)
    end
end

-- Generic Unit Behaviors
function BuildOnceAI(platoon)
    platoon:BuildOnceAI()
end

function AirUnitRefit(self)
    for k, v in self:GetPlatoonUnits() do
        if not v.Dead and not v.RefitThread then
            v.RefitThreat = v:ForkThread(AirUnitRefitThread, self:GetPlan(), self.PlatoonData)
        end
    end
end

function AirUnitRefitThread(unit, plan, data)
    unit.PlanName = plan
    if data then
        unit.PlatoonData = data
    end

    local aiBrain = unit:GetAIBrain()
    while not unit.Dead do
        local fuel = unit:GetFuelRatio()
        local health = unit:GetHealthPercent()
        if not unit.Loading and (fuel < 0.2 or health < 0.4) then
            -- Find air stage
            if aiBrain:GetCurrentUnits(categories.AIRSTAGINGPLATFORM) > 0 then
                local unitPos = unit:GetPosition()
                local plats = AIUtils.GetOwnUnitsAroundPoint(aiBrain, categories.AIRSTAGINGPLATFORM, unitPos, 400)
                if table.getn(plats) > 0 then
                    local closest, distance
                    for _, v in plats do
                        if not v.Dead then
                            local roomAvailable = false
                            if not EntityCategoryContains(categories.CARRIER, v) then
                                roomAvailable = v:TransportHasSpaceFor(unit)
                            end
                            if roomAvailable then
                                local platPos = v:GetPosition()
                                local tempDist = VDist2(unitPos[1], unitPos[3], platPos[1], platPos[3])
                                if not closest or tempDist < distance then
                                    closest = v
                                    distance = tempDist
                                end
                            end
                        end
                    end
                    if closest then
                        local plat = aiBrain:MakePlatoon('', '')
                        aiBrain:AssignUnitsToPlatoon(plat, {unit}, 'Attack', 'None')
                        IssueStop({unit})
                        IssueClearCommands({unit})
                        IssueTransportLoad({unit}, closest)
                        if EntityCategoryContains(categories.AIRSTAGINGPLATFORM, closest) and not closest.AirStaging then
                            closest.AirStaging = closest:ForkThread(AirStagingThread)
                            closest.Refueling = {}
                        elseif EntityCategoryContains(categories.CARRIER, closest) and not closest.CarrierStaging then
                            closest.CarrierStaging = closest:ForkThread(CarrierStagingThread)
                            closest.Refueling = {}
                        end
                        table.insert(closest.Refueling, unit)
                        unit.Loading = true
                    end
                end
            end
        end
        WaitSeconds(1)
    end
end

function AirStagingThread(unit)
    local aiBrain = unit:GetAIBrain()
    while not unit.Dead do
        local ready = true
        local numUnits = 0
        for _, v in unit.Refueling do
            if not v.Dead and (v:GetFuelRatio() < 0.9 or v:GetHealthPercent() < 0.9) then
                ready = false
            elseif not v.Dead then
                numUnits = numUnits + 1
            end
        end
        if ready and numUnits > 0 then
            local pos = unit:GetPosition()
            IssueClearCommands({unit})
            IssueTransportUnload({unit}, {pos[1] + 5, pos[2], pos[3] + 5})
            WaitSeconds(2)
            for _, v in unit.Refueling do
                if not v.Dead then
                    v.Loading = false
                    local plat
                    if not v.PlanName then
                        plat = aiBrain:MakePlatoon('', 'HuntAI')
                    else
                        plat = aiBrain:MakePlatoon('', v.PlanName)
                    end
                    if v.PlatoonData then
                        plat.PlatoonData = {}
                        plat.PlatoonData = v.PlatoonData
                    end
                    aiBrain:AssignUnitsToPlatoon(plat, {v}, 'Attack', 'GrowthFormation')
                end
            end
        end
        WaitSeconds(10)
    end
end

function AirLandToggle(platoon)
    for _, v in platoon:GetPlatoonUnits() do
        if not v.Dead and not v.AirLandToggleThread then
            v.AirLandToggleThread = v:ForkThread(AirLandToggleThread)
        end
    end
end

function AirLandToggleThread(unit)
    local bp = unit:GetBlueprint()
    local weapons = bp.Weapon
    local antiAirRange
    local landRange
    for _, v in weapons do
        if v.ToggleWeapon then
            local weaponType = 'Land'
            for n, wType in v.FireTargetLayerCapsTable do
                if string.find(wType, 'Air') then
                    weaponType = 'Air'
                    break
                end
            end
            if weaponType == 'Land' then
                landRange = v.MaxRadius
            else
                antiAirRange = v.MaxRadius
            end
        end
    end

    if not landRange or not antiAirRange then
        return
    end

    while not unit.Dead and unit:IsUnitState('Busy') do
        WaitSeconds(2)
    end

    local unitCat = ParseEntityCategory(unit.UnitId)
    local aiBrain = unit:GetAIBrain()
    while not unit.Dead do
        local position = unit:GetPosition()
        local numAir = aiBrain:GetNumUnitsAroundPoint((categories.MOBILE * categories.AIR) - unitCat , position, antiAirRange, 'Enemy')
        local numGround = aiBrain:GetNumUnitsAroundPoint((categories.LAND + categories.NAVAL + categories.STRUCTURE) - unitCat, position, landRange, 'Enemy')
        local frndAir = aiBrain:GetNumUnitsAroundPoint((categories.MOBILE * categories.AIR) - unitCat, position, antiAirRange, 'Ally')
        local frndGround = aiBrain:GetNumUnitsAroundPoint((categories.LAND + categories.NAVAL + categories.STRUCTURE) - unitCat, position, landRange, 'Ally')
        if numAir > 5 and frndAir < 3 then
            unit:SetScriptBit('RULEUTC_WeaponToggle', false)
        elseif numGround > (numAir * 1.5) then
            unit:SetScriptBit('RULEUTC_WeaponToggle', true)
        elseif frndAir > frndGround then
            unit:SetScriptBit('RULEUTC_WeaponToggle', true)
        else
            unit:SetScriptBit('RULEUTC_WeaponToggle', false)
        end
        WaitSeconds(10)
    end
end

-------------------------------------------------------
-- Table: SurfacePriorities AKA "Your stuff just got wrecked" priority list.
-- Description:
-- Provides a list of target priorities an experimental should use when
-- wrecking stuff or deciding what stuff should be wrecked next.
-------------------------------------------------------
local SurfacePriorities = {
    'COMMAND',
    'EXPERIMENTAL ENERGYPRODUCTION STRUCTURE',
    'TECH3 ENERGYPRODUCTION STRUCTURE',
    'TECH2 ENERGYPRODUCTION STRUCTURE',
    'TECH3 MASSEXTRACTION STRUCTURE',
    'TECH3 INTELLIGENCE STRUCTURE',
    'TECH2 INTELLIGENCE STRUCTURE',
    'TECH1 INTELLIGENCE STRUCTURE',
    'TECH3 SHIELD STRUCTURE',
    'TECH2 SHIELD STRUCTURE',
    'TECH2 MASSEXTRACTION STRUCTURE',
    'TECH3 FACTORY LAND STRUCTURE',
    'TECH3 FACTORY AIR STRUCTURE',
    'TECH3 FACTORY NAVAL STRUCTURE',
    'TECH2 FACTORY LAND STRUCTURE',
    'TECH2 FACTORY AIR STRUCTURE',
    'TECH2 FACTORY NAVAL STRUCTURE',
    'TECH1 FACTORY LAND STRUCTURE',
    'TECH1 FACTORY AIR STRUCTURE',
    'TECH1 FACTORY NAVAL STRUCTURE',
    'TECH1 MASSEXTRACTION STRUCTURE',
    'TECH3 STRUCTURE',
    'TECH2 STRUCTURE',
    'TECH1 STRUCTURE',
    'TECH3 MOBILE LAND',
    'TECH2 MOBILE LAND',
    'TECH1 MOBILE LAND',
    'EXPERIMENTAL LAND',
}

-------------------------------------------------------
-- Function: CommanderOverrideCheck
-- Args:
-- platoon - the single-experimental platoon to run the behavior on
-- Description:
-- Checks if an enemy commander is within range of the unit's main weapon but not currently targeted.
-- If true, forces weapons to reacquire targets
-- Returns:
-- the commander that was found, else nil
-------------------------------------------------------
CommanderOverrideCheck = function(self)
    local aiBrain = self:GetBrain()
    local experimental = self:GetPlatoonUnits()[1]

    local mainWeapon = experimental:GetWeapon(1)
    local weaponRange = mainWeapon:GetBlueprint().MaxRadius + 50 -- Look outside range.

    local commanders = aiBrain:GetUnitsAroundPoint(categories.COMMAND, self:GetPlatoonPosition(), weaponRange, 'Enemy')
    if table.getn(commanders) == 0 or commanders[1].Dead then
        return false
    end

    local currentTarget = mainWeapon:GetCurrentTarget()
    if commanders[1] ~= currentTarget then
        -- Commander in range who isn't our current target. Force weapons to reacquire targets so they'll grab him.
        for i=1, experimental:GetWeaponCount() do
            experimental:GetWeapon(i):ResetTarget()
        end
    end

    -- Return the commander so an attack order can be issued or something
    return commanders[1]
end

-------------------------------------------------------
-- Function: GetExperimentalUnit
-- Args:
-- platoon - the platoon
-- Description:
-- Finds the experiemental unit in the platoon (assumes platoons are only experimentals)
-- Returns:
-- experimental or nil
-------------------------------------------------------
GetExperimentalUnit = function(platoon)
    local unit = nil
    for k, v in platoon:GetPlatoonUnits() do
        if not v.Dead then
            unit = v
            break
        end
    end

    return unit
end

-------------------------------------------------------
-- Function: AssignExperimentalPriorities
-- Args:
-- platoon - the single-experimental platoon to run the behavior on
-- Description:
-- Sets the experimental's land weapon target priorities to the SurfacePriorities table.
-- Returns:
-- nil
-------------------------------------------------------
AssignExperimentalPriorities = function(platoon)
    local experimental = GetExperimentalUnit(platoon)
    if experimental then
        experimental:SetLandTargetPriorities(SurfacePriorities)
    end
end

-------------------------------------------------------
-- Function: WreckBase
-- Args:
-- platoon - the single-experimental platoon to run the behavior on
-- scoutLocation - the base to wreck
-- Description:
-- Finds a unit in the base we're currently wrecking.
-- Returns:
-- Unit to wreck, base. Else nil.
-------------------------------------------------------
WreckBase = function(self, base)
    for _, priority in SurfacePriorities do
        local numUnitsAtBase = 0
        local notDeadUnit = false
        local unitsAtBase = self:GetBrain():GetUnitsAroundPoint(ParseEntityCategory(priority), base.Position, 100, 'Enemy')
        for _, unit in unitsAtBase do
            if not unit.Dead then
                notDeadUnit = unit
                numUnitsAtBase = numUnitsAtBase + 1
            end
        end

        if numUnitsAtBase > 0 then
            return notDeadUnit, base
        end
    end
end

-------------------------------------------------------
-- Function: FindExperimentalTarget
-- Args:
-- platoon - the single-experimental platoon to run the behavior on
-- Description:
-- Goes through the SurfacePriorities table looking for the enemy base (high priority scouting location. See ScoutingAI in platoon.lua)
-- with the most number of the highest priority targets.
-- Returns:
-- target unit, target base, else nil
-------------------------------------------------------
FindExperimentalTarget = function(self)
    local aiBrain = self:GetBrain()
    if not aiBrain.InterestList or not aiBrain.InterestList.HighPriority then
        -- No target
        return
    end

    -- For each priority in SurfacePriorities list, check against each enemy base we're aware of (through scouting/intel),
    -- The base with the most number of the highest-priority targets gets selected. If there's a tie, pick closer
    local enemyBases = aiBrain.InterestList.HighPriority
    for _, priority in SurfacePriorities do
        local bestBase = false
        local mostUnits = 0
        local bestUnit = false
        for _, base in enemyBases do
            local unitsAtBase = aiBrain:GetUnitsAroundPoint(ParseEntityCategory(priority), base.Position, 100, 'Enemy')
            local numUnitsAtBase = 0
            local notDeadUnit = false

            for _, unit in unitsAtBase do
                if not unit.Dead then
                    notDeadUnit = unit
                    numUnitsAtBase = numUnitsAtBase + 1
                end
            end

            if numUnitsAtBase > 0 then
                if numUnitsAtBase > mostUnits then
                    bestBase = base
                    mostUnits = numUnitsAtBase
                    bestUnit = notDeadUnit
                elseif numUnitsAtBase == mostUnits then
                    local myPos = self:GetPlatoonPosition()
                    local dist1 = VDist2(myPos[1], myPos[3], base.Position[1], base.Position[3])
                    local dist2 = VDist2(myPos[1], myPos[3], bestBase.Position[1], bestBase.Position[3])

                    if dist1 < dist2 then
                        bestBase = base
                        bestUnit = notDeadUnit
                    end
                end
            end
        end
        if bestBase and bestUnit then
            return bestUnit, bestBase
        end
    end

    return false, false
end

-- Indivitual Unit Behaviors
-------------------------------------------------------
-- Function: BehemothBehavior
-- Args:
-- self - the single-experimental platoon to run the behavior on
-- Description:
-- Generic experimental AI. Find a base with good stuff to destroy, and go attack it.
-- If an enemy commander comes within range of the main weapon, attack it.
-- Returns:
-- nil (function loops until experimental dies)
-------------------------------------------------------
function BehemothBehavior(self)
    AssignExperimentalPriorities(self)

    local experimental = GetExperimentalUnit(self)
    local targetUnit = false
    local lastBase = false
    local airUnit = EntityCategoryContains(categories.AIR, experimental)
    -- Find target loop
    while experimental and not experimental.Dead do
        if lastBase then
            targetUnit, lastBase = WreckBase(self, lastBase)
        elseif not lastBase then
            targetUnit, lastBase = FindExperimentalTarget(self)
        end

        if targetUnit then
            IssueClearCommands({experimental})
            IssueAttack({experimental}, targetUnit)
        end

        -- Walk to and kill target loop
        while not experimental.Dead and not experimental:IsIdleState() do
            local nearCommander = CommanderOverrideCheck(self)
            if nearCommander and nearCommander ~= targetUnit then
                IssueClearCommands({experimental})
                IssueAttack({experimental}, nearCommander)
                targetUnit = nearCommander
            end

            -- If no target jump out
            if not targetUnit then break end

            -- Check if we or the target are under a shield
            local closestBlockingShield = false
            if not airUnit then
                closestBlockingShield = GetClosestShieldProtectingTarget(experimental, experimental)
            end
            closestBlockingShield = closestBlockingShield or GetClosestShieldProtectingTarget(experimental, targetUnit)

            -- Kill shields loop
            while closestBlockingShield do
                IssueClearCommands({experimental})
                IssueAttack({experimental}, closestBlockingShield)

                -- Wait for shield to die loop
                while not closestBlockingShield.Dead and not experimental.Dead do
                    WaitSeconds(1)
                end

                closestBlockingShield = false
                if not airUnit then
                    closestBlockingShield = GetClosestShieldProtectingTarget(experimental, experimental)
                end
                closestBlockingShield = closestBlockingShield or GetClosestShieldProtectingTarget(experimental, targetUnit)
                WaitTicks(1)
            end
            WaitSeconds(1)
        end
        WaitSeconds(1)
    end
end

-------------------------------------------------------
-- Function: GetShieldRadiusAboveGroundSquared
-- Args:
-- unit - the shield to check the radius of
-- Description:
-- Since a shield can be vertically offset, its blueprint radius is not truly indicative of its
-- protective coverage at ground level. This function gets the square of the actual protective radius of the shield
-- Returns:
-- The square of the shield's radius at the surface.
-------------------------------------------------------
function GetShieldRadiusAboveGroundSquared(shield)
    local BP = shield:GetBlueprint().Defense.Shield
    local width = BP.ShieldSize
    local height = BP.ShieldVerticalOffset

    return width * width - height * height
end

-------------------------------------------------------
-- Function: GetClosestShieldProtectingTarget
-- Args:
-- unit - the attacking unit
-- unit - the unit being attacked
-- Description:
-- Gets the closest shield protecting the target unit
-- Returns:
-- The shield, else false
-------------------------------------------------------
function GetClosestShieldProtectingTarget(attackingUnit, targetUnit)
    local aiBrain = attackingUnit:GetAIBrain()
    local tPos = targetUnit:GetPosition()
    local aPos = attackingUnit:GetPosition()

    local blockingList = {}

    -- If targetUnit is within the radius of any shields, the shields need to be destroyed.
    local shields = aiBrain:GetUnitsAroundPoint(categories.SHIELD * categories.STRUCTURE, targetUnit:GetPosition(), 50, 'Enemy')
    for _, shield in shields do
        if not shield.Dead then
            local shieldPos = shield:GetPosition()
            local shieldSizeSq = GetShieldRadiusAboveGroundSquared(shield)

            if VDist2Sq(tPos[1], tPos[3], shieldPos[1], shieldPos[3]) < shieldSizeSq then
                table.insert(blockingList, shield)
            end
        end
    end

    -- Return the closest blocking shield
    local closest = false
    local closestDistSq = 999999
    for _, shield in blockingList do
        local shieldPos = shield:GetPosition()
        local distSq = VDist2Sq(aPos[1], aPos[3], shieldPos[1], shieldPos[3])
        if distSq < closestDistSq then
            closest = shield
            closestDistSq = distSq
        end
    end

    return closest
end

-------------------------------------------------------
-- Function: FatBoyBehavior
-- Args:
-- self - the single-experimental platoon to run the behavior on
-- Description:
-- Find a base to attack. Sit outside of the base in weapon range and build units.
-- Returns:
-- nil (function loops until experimental dies)
-------------------------------------------------------
function InWaterCheck(platoon)
    local t4Pos = platoon:GetPlatoonPosition()
    local inWater = GetTerrainHeight(t4Pos[1], t4Pos[3]) < GetSurfaceHeight(t4Pos[1], t4Pos[3])
    return inWater
end

function FatBoyBehavior(self)
    local aiBrain = self:GetBrain()
    AssignExperimentalPriorities(self)

    local experimental = GetExperimentalUnit(self)
    local targetUnit = false
    local lastBase = false

    local mainWeapon = experimental:GetWeapon(1)
    local weaponRange = mainWeapon:GetBlueprint().MaxRadius

    experimental.Platoons = experimental.Platoons or {}

    -- Find target loop
    while experimental and not experimental.Dead do
        targetUnit, lastBase = FindExperimentalTarget(self)
        if targetUnit then
            IssueClearCommands({experimental})

            local useMove = InWaterCheck(self)
            if useMove then
                IssueMove({experimental}, targetUnit:GetPosition())
            else
                IssueAttack({experimental}, targetUnit)
            end

            -- Wait to get in range
            local pos = experimental:GetPosition()
            while VDist2(pos[1], pos[3], lastBase.Position[1], lastBase.Position[3]) > weaponRange + 10
                and not experimental.Dead and not experimental:IsIdleState() do
                    WaitSeconds(5)
            end

            IssueClearCommands({experimental})

            -- Send our homies to wreck this base
            local goodList = {}
            for _, platoon in experimental.Platoons do
                local platoonUnits = false

                if aiBrain:PlatoonExists(platoon) then
                    platoonUnits = platoon:GetPlatoonUnits()
                end

                if platoonUnits and table.getn(platoonUnits) > 0 then
                    table.insert(goodList, platoon)
                end
            end

            experimental.Platoons = goodList
            for _, platoon in goodList do
                platoon:ForkAIThread(FatboyChildBehavior, experimental, lastBase)
            end

            -- Setup shop outside this guy's base
            while not experimental.Dead and WreckBase(self, lastBase) do
                -- Build stuff if we haven't hit the unit cap.
                FatBoyBuildCheck(self)

                -- Once we have 20 units, form them into a platoon and send them to attack the base we're attacking!
                if experimental.NewPlatoon and table.getn(experimental.NewPlatoon:GetPlatoonUnits()) >= 20 then
                    experimental.NewPlatoon:ForkAIThread(FatboyChildBehavior, experimental, lastBase)

                    table.insert(experimental.Platoons, experimental.NewPlatoon)
                    experimental.NewPlatoon = nil
                end
                WaitSeconds(1)
            end
        end
        WaitSeconds(1)
    end
end

-------------------------------------------------------
-- Function: FatBoyBuildCheck
-- Args:
-- self - single-fatboy platoon to build a unit with
-- Description:
-- Builds a random T3 land unit
-- Returns:
-- nil
-------------------------------------------------------
function FatBoyBuildCheck(self)
    local aiBrain = self:GetBrain()
    local experimental = GetExperimentalUnit(self)

    -- Randomly build T3 MMLs, siege bots, and percivals.
    local buildUnits = {'uel0303', 'xel0305', 'xel0306', }
    local unitToBuild = buildUnits[Random(1, table.getn(buildUnits))]

    aiBrain:BuildUnit(experimental, unitToBuild, 1)
    WaitTicks(1)

    local unitBeingBuilt = false
    repeat
        unitBeingBuilt = unitBeingBuilt or experimental.UnitBeingBuilt
        WaitSeconds(1)
    until experimental.Dead or unitBeingBuilt or aiBrain:GetArmyStat("UnitCap_MaxCap", 0.0).Value - aiBrain:GetArmyStat("UnitCap_Current", 0.0).Value < 10

    repeat
        WaitSeconds(3)
    until experimental.Dead or experimental:IsIdleState() or aiBrain:GetArmyStat("UnitCap_MaxCap", 0.0).Value - aiBrain:GetArmyStat("UnitCap_Current", 0.0).Value < 10

    if not experimental.NewPlatoon or not aiBrain:PlatoonExists(experimental.NewPlatoon) then
        experimental.NewPlatoon = aiBrain:MakePlatoon('', '')
    end

    if unitBeingBuilt and not unitBeingBuilt.Dead then
        aiBrain:AssignUnitsToPlatoon(experimental.NewPlatoon, {unitBeingBuilt}, 'Attack', 'NoFormation')
        IssueClearCommands({unitBeingBuilt})
        IssueGuard({unitBeingBuilt}, experimental)
    end
end

-------------------------------------------------------
-- Function: FatboyChildBehavior
-- Args:
-- self - the platoon of fatboy children to run the behavior on
-- parent - the parent fatboy that the child platoon belongs to
-- base - the base to be attacked
-- Description:
-- AI for fatboy child platoons. Wrecks the base that the fatboy has selected.
-- Once the base is wrecked, the units will return to guard the fatboy until a new
-- target base is reached, at which point they will attack it.
-- Returns:
-- nil
-------------------------------------------------------
function FatboyChildBehavior(self, parent, base)
    local aiBrain = self:GetBrain()
    local targetUnit = false

    -- Find target loop
    while aiBrain:PlatoonExists(self) and table.getn(self:GetPlatoonUnits()) > 0 do
        targetUnit, base = WreckBase(self, base)

        local units = self:GetPlatoonUnits()
        if not base then
            -- Wrecked base. Kill AI thread
            IssueClearCommands(units)
            IssueGuard(units, parent)
            return
        end

        if targetUnit then
            IssueClearCommands(units)
            IssueAggressiveMove(units, targetUnit)
        end

        -- Walk to and kill target loop
        while aiBrain:PlatoonExists(self) and table.getn(self:GetPlatoonUnits()) > 0 and not targetUnit.Dead do
            WaitSeconds(3)
        end

        WaitSeconds(1)
    end
end

TempestBehavior = function(self)
    local aiBrain = self:GetBrain()
    local unit
    for k, v in self:GetPlatoonUnits() do
        if not v.Dead then
            unit = v
            break
        end
    end

    if not unit then
        return
    end

    if not EntityCategoryContains(categories.uas0401, unit) then
        return
    end

    unit.BuiltUnitCount = 0
    self.Patrolling = false
    while aiBrain:PlatoonExists(self) and not unit.Dead do
        local position = unit:GetPosition()
        local numStrucs = aiBrain:GetNumUnitsAroundPoint(categories.STRUCTURE - (categories.MASSEXTRACTION + categories.WALL), position, 65, 'Enemy')
        local numNaval = aiBrain:GetNumUnitsAroundPoint((categories.MOBILE * categories.NAVAL) * (categories.EXPERIMENTAL + categories.TECH3 + categories.TECH2), position, 65, 'Enemy')
        while unit.BuiltUnitCount < 8 and (numStrucs > 5 or numNaval > 10) do
            self.Patrolling = false
            self.BreakOff = true
            local numAir = aiBrain:GetNumUnitsAroundPoint((categories.MOBILE * categories.AIR) * (categories.EXPERIMENTAL + categories.TECH3), position, 65, 'Enemy')
            local numDef = aiBrain:GetNumUnitsAroundPoint(categories.STRUCTURE * (categories.DEFENSE + categories.STRATEGIC), position, 75, 'Enemy')
            local unitToBuild = false
            if numDef > numNaval and numDef > numAir then
                if Random(1, 2) == 1 then
                    unitToBuild = 'uas0201'
                else
                    unitToBuild = 'uas0201'
                end
            elseif numNaval > numStrucs and numNaval > numAir then
                unitToBuild = 'uas0203'
            elseif numStrucs > numAir and numStrucs > numLand then
                unitToBuild = 'uas0201'
            else
                unitToBuild = 'uas0202'
            end

            if unitToBuild then
                IssueStop({unit})
                IssueClearCommands({unit})
                aiBrain:BuildUnit(unit, unitToBuild, 1)
            end

            local unitBeingBuilt = false
            local building
            repeat
                WaitSeconds(5)
                unitBeingBuilt = unit.UnitBeingBuilt
                building = false
                for k, v in self:GetPlatoonUnits() do
                    if not v.Dead and v:IsUnitState('Building') then
                        building = true
                        break
                    end
                end
            until not building

            if unitBeingBuilt and not unitBeingBuilt.Dead then
                local testHeading = false
                testHeading = unit:GetHeading()
                unit.BuiltUnitCount = unit.BuiltUnitCount + 1
                ScenarioFramework.CreateUnitDestroyedTrigger(TempestUnitDeath, unitBeingBuilt)
                aiBrain:AssignUnitsToPlatoon(self, {unitBeingBuilt}, 'Attack', 'GrowthFormation')
                IssueClearCommands({unitBeingBuilt})
                unitBeingBuilt:ForkThread(TempestBuiltUnitMoveOut, position, testHeading)
            end
            self.BreakOff = false
            numStrucs = aiBrain:GetNumUnitsAroundPoint(categories.STRUCTURE - (categories.MASSEXTRACTION + categories.WALL), position, 65, 'Enemy')
            numNaval = aiBrain:GetNumUnitsAroundPoint((categories.MOBILE * categories.NAVAL) * (categories.EXPERIMENTAL + categories.TECH3 + categories.TECH2), position, 65, 'Enemy')
        end

        if aiBrain:PlatoonExists(self) and not self.Patrolling then
            self:Stop()
            self.Patrolling = true
            scoutPath = AIUtils.AIGetSortedNavalLocations(self:GetBrain())
            for k, v in scoutPath do
                self:Patrol(v)
            end
        end
        WaitSeconds(5)
    end
end

function TempestUnitDeath(unit)
    if unit.Tempest and not unit.Tempest.Dead and unit.Tempest.BuiltUnitCount then
        unit.Tempest.BuildUnitCount = unit.Tempest.BuildUnitCount - 1
    end
end

function TempestBuiltUnitMoveOut(unit, platoon, position, heading)
    if heading >= 270 or heading <= 90 then
        position =  {position[1], position[2], position[3] + 20}
    else
        position = {position[1], position[2], position[3] - 20}
    end

    local counter = 0
    repeat
        IssueClearCommands({unit})
        IssueMove({unit}, position)
        WaitSeconds(5)
        if unit.Dead then
            return
        end
        counter = counter + 1
    until counter == 4 or platoon.Patrolling
end

-------------------------------------------------------
-- Function: CzarBehavior
-- Args:
-- self - the single-experimental platoon to run the behavior on
-- Description:
-- Finds a good base to attack and attacks it.  Prefers to find a commander to kill.
-- Is unique in that it will issue a ground attack and then a move to keep the beam
-- on while moving, instead of attacking specific targets
-- Returns:
-- nil (function loops until experimental dies)
-------------------------------------------------------
CzarBehavior = function(self)
    local experimental = GetExperimentalUnit(self)
    if not experimental then
        return
    end

    if not EntityCategoryContains(categories.uaa0310, experimental) then
        return
    end

    AssignExperimentalPriorities(self)

    local targetUnit, targetBase = FindExperimentalTarget(self)
    local oldTargetUnit = nil
    while not experimental.Dead do
        if targetUnit and targetUnit ~= oldTargetUnit then
            IssueClearCommands({experimental})
            WaitTicks(5)

            -- Move to the target without attacking. This will get it out of your base without the beam on.
            if targetUnit and VDist3(targetUnit:GetPosition(), experimental:GetPosition()) > 50 then
                IssueMove({experimental}, targetUnit:GetPosition())
            else
                IssueAttack({experimental}, experimental:GetPosition())
                WaitTicks(5)

                IssueMove({experimental}, targetUnit:GetPosition())
            end
        end

        local nearCommander = CommanderOverrideCheck(self)
        local oldCommander = nil
        while nearCommander and not experimental.Dead and not experimental:IsIdleState() do
            if nearCommander and nearCommander ~= oldCommander and nearCommander ~= targetUnit then
                IssueClearCommands({experimental})
                WaitTicks(5)

                IssueAttack({experimental}, experimental:GetPosition())
                WaitTicks(5)

                IssueMove({experimental}, nearCommander:GetPosition())
                targetUnit = nearCommander
            end
            WaitSeconds(1)

            oldCommander = nearCommander
            nearCommander = CommanderOverrideCheck(self)
        end
        WaitSeconds(1)

        oldTargetUnit = targetUnit
        targetUnit, targetBase = FindExperimentalTarget(self)
    end
end

-------------------------------------------------------
-- Function: AhwassaBehavior
-- Args:
-- self - the single-experimental platoon to run the behavior on
-- Description:
-- Finds a good base to attack and attacks it.
-- Is unique in that it will look for a cluster of units to hit with its large AOE bomb.
-- Returns:
-- nil (function loops until experimental dies)
-------------------------------------------------------
AhwassaBehavior = function(self)
    local aiBrain = self:GetBrain()
    local experimental = GetExperimentalUnit(self)
    if not experimental then
        return
    end

    if not EntityCategoryContains(categories.xsa0402, experimental) then
        return
    end

    AssignExperimentalPriorities(self)

    local targetLocation = GetHighestThreatClusterLocation(aiBrain, experimental)
    local oldTargetLocation = nil
    while not experimental.Dead do
        if targetLocation and targetLocation ~= oldTargetLocation then
            IssueClearCommands({experimental})
            IssueAttack({experimental}, targetLocation)
            WaitSeconds(25)
        end
        WaitSeconds(1)

        oldTargetLocation = targetLocation
        targetLocation = GetHighestThreatClusterLocation(aiBrain, experimental)
    end
end

-------------------------------------------------------
-- Function: TickBehavior
-- Args:
-- self - the single-experimental platoon to run the behavior on
-- Description:
-- Finds a good base to attack and attacks it.
-- Is unique in that it will look for a cluster of units to hit with its gunshipness.
-- Returns:
-- nil (function loops until experimental dies)
-------------------------------------------------------
TickBehavior = function(self)
    local aiBrain = self:GetBrain()
    local experimental = GetExperimentalUnit(self)
    if not experimental then
        return
    end

    if not EntityCategoryContains(categories.ura0401, experimental) then
        return
    end

    AssignExperimentalPriorities(self)

    local targetLocation = GetHighestThreatClusterLocation(aiBrain, experimental)
    local oldTargetLocation = nil
    while not experimental.Dead do
        if targetLocation and targetLocation ~= oldTargetLocation then
            IssueClearCommands({experimental})
            IssueAggressiveMove({experimental}, targetLocation)
            WaitSeconds(25)
        end
        WaitSeconds(1)

        oldTargetLocation = targetLocation
        targetLocation = GetHighestThreatClusterLocation(aiBrain, experimental)
    end
end

-------------------------------------------------------
-- Function: GetHighestThreatClusterLocation
-- Args:
-- aiBrain - aiBrain for experimental
-- experimental - the unit itself
-- Description:
-- Finds the commander first, or a high economic threat that has a lot of units
-- Good for AoE type attacks
-- Returns:
-- position of best place to attack, nil if nothing found
-------------------------------------------------------
GetHighestThreatClusterLocation = function(aiBrain, experimental)
    if not aiBrain or not experimental then
        return nil
    end

    -- Look for commander first
    local position = experimental:GetPosition()
    local threatTable = aiBrain:GetThreatsAroundPosition(position, 16, true, 'Commander')
    for _, threat in threatTable do
        if threat[3] > 0 then
            local unitsAtLocation = aiBrain:GetUnitsAroundPoint(ParseEntityCategory('COMMAND'), {threat[1], 0, threat[2]}, ScenarioInfo.size[1] / 16, 'Enemy')
            local validUnit = false
            for _, unit in unitsAtLocation do
                if not unit.Dead then
                    validUnit = unit
                    break
                end
            end
            if validUnit then
                return table.copy(validUnit:GetPosition())
            end
        end
    end

    if not aiBrain.InterestList or not aiBrain.InterestList.HighPriority then
        -- No target
        return aiBrain:GetHighestThreatPosition(0, true, 'Economy')
    end

    -- Now look through the bases for the highest economic threat and largest cluster of units
    local enemyBases = aiBrain.InterestList.HighPriority
    local bestBaseThreat = nil
    local maxBaseThreat = 0
    for _, base in enemyBases do
        local threatTable = aiBrain:GetThreatsAroundPosition(base.Position, 1, true, 'Economy')
        if table.getn(threatTable) ~= 0 then
            if threatTable[1][3] > maxBaseThreat then
                maxBaseThreat = threatTable[1][3]
                bestBaseThreat = threatTable
            end
        end
    end

    if not bestBaseThreat then
        -- No threat
        return
    end

    -- Look for a cluster of structures
    local maxUnits = -1
    local bestThreat = 1
    for idx, threat in bestBaseThreat do
        if threat[3] > 0 then
            local unitsAtLocation = aiBrain:GetUnitsAroundPoint(ParseEntityCategory('STRUCTURE'), {threat[1], 0, threat[2]}, ScenarioInfo.size[1] / 16, 'Enemy')
            local numunits = table.getn(unitsAtLocation)

            if numunits > maxUnits then
                maxUnits = numunits
                bestThreat = idx
            end
        end
    end

    if bestBaseThreat[bestThreat] then
        local bestPos = {0, 0, 0}
        local maxUnits = 0
        local lookAroundTable = {-2, -1, 0, 1, 2}
        local squareRadius = (ScenarioInfo.size[1] / 16) / table.getn(lookAroundTable)
        for ix, offsetX in lookAroundTable do
            for iz, offsetZ in lookAroundTable do
                local unitsAtLocation = aiBrain:GetUnitsAroundPoint(ParseEntityCategory('STRUCTURE'), {bestBaseThreat[bestThreat][1] + offsetX*squareRadius, 0, bestBaseThreat[bestThreat][2]+offsetZ*squareRadius}, squareRadius, 'Enemy')
                local numUnits = table.getn(unitsAtLocation)
                if numUnits > maxUnits then
                    maxUnits = numUnits
                    bestPos = table.copy(unitsAtLocation[1]:GetPosition())
                end
            end
        end
        if bestPos[1] ~= 0 and bestPos[3] ~= 0 then
            return bestPos
        end
    end

    return nil
end

-- Sorian AI Functions
function NukeCheck(aiBrain)
    local Nukes
    local lastNukes = 0
    local waitcount = 0
    local rollcount = 0
    local nukeCount = 0
    local mapSizeX, mapSizeZ = GetMapSize()
    local size = mapSizeX

    if mapSizeZ > mapSizeX then
        size = mapSizeZ
    end

    local sizeDiag = math.sqrt((size * size) * 2)
    local nukeWait = math.max((sizeDiag / 40), 10)
    local numNukes = aiBrain:GetCurrentUnits(categories.NUKE * categories.SILO * categories.STRUCTURE * categories.TECH3)

    while true do
        lastNukes = numNukes
        repeat
            WaitSeconds(nukeWait)
            waitcount = 0
            nukeCount = 0
            numNukes = aiBrain:GetCurrentUnits(categories.NUKE * categories.SILO * categories.STRUCTURE * categories.TECH3)
            Nukes = aiBrain:GetListOfUnits(categories.NUKE * categories.SILO * categories.STRUCTURE * categories.TECH3, true)
            for _, v in Nukes do
                if v:GetWorkProgress() * 100 > waitcount then
                    waitcount = v:GetWorkProgress() * 100
                end
                if v:GetNukeSiloAmmoCount() > 0 then
                    nukeCount = nukeCount + 1
                end
            end
            if nukeCount > 0 and lastNukes > 0 then
                WaitSeconds(5)

                SUtils.Nuke(aiBrain)
                rollcount = 0
                WaitSeconds(30)
            end
        until numNukes > lastNukes and waitcount < 65 and rollcount < 2

        Nukes = aiBrain:GetListOfUnits(categories.NUKE * categories.SILO * categories.STRUCTURE * categories.TECH3, true)
        rollcount = rollcount + (numNukes - lastNukes)

        for _, v in Nukes do
            IssueStop({v})
        end
        WaitSeconds(5)

        for _, v in Nukes do
            v:SetAutoMode(true)
        end
    end
end

function AirLandToggleSorian(platoon)
    for _, v in platoon:GetPlatoonUnits() do
        if not v.Dead and not v.AirLandToggleThreadSorian then
            v.AirLandToggleThreadSorian = v:ForkThread(AirLandToggleThreadSorian)
        end
    end
end

function AirLandToggleThreadSorian(unit)

    local bp = unit:GetBlueprint()
    local weapons = bp.Weapon
    local antiAirRange
    local landRange
    local unitCat = ParseEntityCategory(unit.UnitId)
    for _, v in weapons do
        if v.ToggleWeapon then
            local weaponType = 'Land'
            for n, wType in v.FireTargetLayerCapsTable do
                if string.find(wType, 'Air') then
                    weaponType = 'Air'
                    break
                end
            end
            if weaponType == 'Land' then
                landRange = v.MaxRadius
            else
                antiAirRange = v.MaxRadius
            end
        end
    end

    if not landRange or not antiAirRange then
        return
    end

    local aiBrain = unit:GetAIBrain()
    while not unit.Dead do
        local position = unit:GetPosition()
        local numAir = aiBrain:GetNumUnitsAroundPoint((categories.MOBILE * categories.AIR) - unitCat , position, antiAirRange, 'Enemy')
        local numGround = aiBrain:GetNumUnitsAroundPoint((categories.LAND + categories.NAVAL + categories.STRUCTURE) - unitCat, position, landRange, 'Enemy')
        local frndAir = aiBrain:GetNumUnitsAroundPoint((categories.MOBILE * categories.AIR) - unitCat, position, antiAirRange, 'Ally')
        local frndGround = aiBrain:GetNumUnitsAroundPoint((categories.LAND + categories.NAVAL + categories.STRUCTURE) - unitCat, position, landRange, 'Ally')
        if numAir > 5 and frndAir < 3 then
            unit:SetScriptBit('RULEUTC_WeaponToggle', false)
        elseif numGround > (numAir * 1.5) then
            unit:SetScriptBit('RULEUTC_WeaponToggle', true)
        elseif frndAir > frndGround then
            unit:SetScriptBit('RULEUTC_WeaponToggle', true)
        else
            unit:SetScriptBit('RULEUTC_WeaponToggle', false)
        end
        WaitSeconds(10)
    end
end

local SurfacePrioritiesSorian = {
    'EXPERIMENTAL ENERGYPRODUCTION STRUCTURE',
    'EXPERIMENTAL STRATEGIC STRUCTURE',
    'EXPERIMENTAL ARTILLERY OVERLAYINDIRECTFIRE',
    'EXPERIMENTAL ORBITALSYSTEM',
    'TECH3 STRATEGIC STRUCTURE',
    'EXPERIMENTAL LAND',
    'TECH2 STRATEGIC STRUCTURE',
    'TECH3 DEFENSE STRUCTURE',
    'TECH2 DEFENSE STRUCTURE',
    'TECH3 ENERGYPRODUCTION STRUCTURE',
    'TECH3 MASSFABRICATION STRUCTURE',
    'TECH2 ENERGYPRODUCTION STRUCTURE',
    'TECH3 MASSEXTRACTION STRUCTURE',
    'TECH3 SHIELD STRUCTURE',
    'TECH2 SHIELD STRUCTURE',
    'TECH3 INTELLIGENCE STRUCTURE',
    'TECH2 INTELLIGENCE STRUCTURE',
    'TECH1 INTELLIGENCE STRUCTURE',
    'TECH2 MASSEXTRACTION STRUCTURE',
    'TECH3 FACTORY LAND STRUCTURE',
    'TECH3 FACTORY AIR STRUCTURE',
    'TECH3 FACTORY NAVAL STRUCTURE',
    'TECH2 FACTORY LAND STRUCTURE',
    'TECH2 FACTORY AIR STRUCTURE',
    'TECH2 FACTORY NAVAL STRUCTURE',
    'TECH1 FACTORY LAND STRUCTURE',
    'TECH1 FACTORY AIR STRUCTURE',
    'TECH1 FACTORY NAVAL STRUCTURE',
    'TECH1 MASSEXTRACTION STRUCTURE',
    'TECH3 STRUCTURE',
    'TECH2 STRUCTURE',
    'TECH1 STRUCTURE',
    'TECH3 MOBILE LAND',
    'TECH2 MOBILE LAND',
    'TECH1 MOBILE LAND',
    'ALLUNITS',
}

local T4WeaponPrioritiesSorian = {
    'COMMAND',
    'EXPERIMENTAL ENERGYPRODUCTION STRUCTURE',
    'EXPERIMENTAL STRATEGIC STRUCTURE',
    'EXPERIMENTAL ARTILLERY OVERLAYINDIRECTFIRE',
    'EXPERIMENTAL ORBITALSYSTEM',
    'TECH3 STRATEGIC STRUCTURE',
    'EXPERIMENTAL LAND',
    'TECH2 STRATEGIC STRUCTURE',
    'TECH3 DEFENSE STRUCTURE',
    'TECH2 DEFENSE STRUCTURE',
    'TECH3 ENERGYPRODUCTION STRUCTURE',
    'TECH3 MASSFABRICATION STRUCTURE',
    'TECH2 ENERGYPRODUCTION STRUCTURE',
    'TECH3 MASSEXTRACTION STRUCTURE',
    'TECH3 SHIELD STRUCTURE',
    'TECH2 SHIELD STRUCTURE',
    'TECH3 INTELLIGENCE STRUCTURE',
    'TECH2 INTELLIGENCE STRUCTURE',
    'TECH1 INTELLIGENCE STRUCTURE',
    'TECH2 MASSEXTRACTION STRUCTURE',
    'TECH3 FACTORY LAND STRUCTURE',
    'TECH3 FACTORY AIR STRUCTURE',
    'TECH3 FACTORY NAVAL STRUCTURE',
    'TECH2 FACTORY LAND STRUCTURE',
    'TECH2 FACTORY AIR STRUCTURE',
    'TECH2 FACTORY NAVAL STRUCTURE',
    'TECH1 FACTORY LAND STRUCTURE',
    'TECH1 FACTORY AIR STRUCTURE',
    'TECH1 FACTORY NAVAL STRUCTURE',
    'TECH1 MASSEXTRACTION STRUCTURE',
    'TECH3 STRUCTURE',
    'TECH2 STRUCTURE',
    'TECH1 STRUCTURE',
    'TECH3 MOBILE LAND',
    'TECH2 MOBILE LAND',
    'TECH1 MOBILE LAND',
    'ALLUNITS',
}

function CDRRunAwaySorian(aiBrain, cdr)
    local shieldPercent
    local cdrPos = cdr:GetPosition()

    cdr.UnitBeingBuiltBehavior = false

    if (cdr:HasEnhancement('Shield') or cdr:HasEnhancement('ShieldGeneratorField') or cdr:HasEnhancement('ShieldHeavy')) and cdr:ShieldIsOn() then
        shieldPercent = (cdr.MyShield:GetHealth() / cdr.MyShield:GetMaxHealth())
    else
        shieldPercent = 1
    end

    local nmeHardcore = aiBrain:GetNumUnitsAroundPoint(categories.EXPERIMENTAL, cdrPos, 130, 'Enemy')
    local nmeT3 = aiBrain:GetNumUnitsAroundPoint(categories.LAND * categories.TECH3 - categories.ENGINEER, cdrPos, 50, 'Enemy')
    if cdr:GetHealthPercent() < 0.7 or shieldPercent < 0.3 or nmeHardcore > 0 or nmeT3 > 4 then
        local nmeAir = aiBrain:GetNumUnitsAroundPoint(categories.AIR - categories.SCOUT - categories.INTELLIGENCE, cdrPos, 30, 'Enemy')
        local nmeLand = aiBrain:GetNumUnitsAroundPoint(categories.COMMAND + categories.LAND - categories.ENGINEER - categories.SCOUT - categories.TECH1, cdrPos, 40, 'Enemy')
        local nmaShield = aiBrain:GetNumUnitsAroundPoint(categories.SHIELD * categories.STRUCTURE, cdrPos, 100, 'Ally')
        if nmeAir > 4 or nmeLand > 9 or nmeT3 > 4 or nmeHardcore > 0 or cdr:GetHealthPercent() < 0.7 or shieldPercent < 0.3 then
            if cdr.UnitBeingBuilt then
                cdr.UnitBeingBuiltBehavior = cdr.UnitBeingBuilt
            end

            cdr.GoingHome = true
            cdr.Fighting = false
            cdr.Upgrading = false

            if cdr.PlatoonHandle then
                cdr.PlatoonHandle:PlatoonDisband()
            end

            aiBrain.BaseMonitor.CDRDistress = cdrPos
            aiBrain.BaseMonitor.CDRThreatLevel = aiBrain:GetThreatAtPosition(cdrPos, 1, true, 'AntiSurface')

            CDRRevertPriorityChange(aiBrain, cdr)

            local runShield = false
            local category
            if nmaShield > 0 then
                category = categories.SHIELD * categories.STRUCTURE
                runShield = true
            elseif nmeAir > 3 then
                category = categories.DEFENSE * categories.ANTIAIR
            else
                category = categories.DEFENSE * categories.DIRECTFIRE
            end

            local runSpot, prevSpot
            local plat = aiBrain:MakePlatoon('', '')
            local canTeleport = false
            aiBrain:AssignUnitsToPlatoon(plat, {cdr}, 'support', 'None')
            repeat
                if not aiBrain:PlatoonExists(plat) then
                    return
                end

                if canTeleport then
                    runSpot = AIUtils.AIFindDefensiveAreaSorian(aiBrain, cdr, category, 10000, runShield)
                else
                    runSpot = AIUtils.AIFindDefensiveAreaSorian(aiBrain, cdr, category, 100, runShield)
                end

                if not runSpot then
                    local x, z = aiBrain:GetArmyStartPos()
                    runSpot = AIUtils.RandomLocation(x, z)
                end

                if not prevSpot or runSpot[1] ~= prevSpot[1] or runSpot[3] ~= prevSpot[3] then
                    IssueClearCommands({cdr})
                    if VDist2(cdrPos[1], cdrPos[3], runSpot[1], runSpot[3]) >= 10 then
                        if canTeleport then
                            IssueTeleport({cdr}, runSpot)
                        else
                            IssueMove({cdr}, runSpot)
                        end
                    end
                end
                WaitSeconds(3)

                if not cdr.Dead then
                    cdrPos = cdr:GetPosition()
                    nmeAir = aiBrain:GetNumUnitsAroundPoint(categories.AIR - categories.SCOUT - categories.INTELLIGENCE, cdrPos, 30, 'Enemy')
                    nmeLand = aiBrain:GetNumUnitsAroundPoint(categories.COMMAND + categories.LAND - categories.ENGINEER - categories.SCOUT - categories.TECH1, cdrPos, 40, 'Enemy')
                    nmeT3 = aiBrain:GetNumUnitsAroundPoint(categories.LAND * categories.TECH3 - categories.ENGINEER, cdrPos, 50, 'Enemy')
                    nmeHardcore = aiBrain:GetNumUnitsAroundPoint(categories.EXPERIMENTAL, cdrPos, 130, 'Enemy')
                    if (cdr:HasEnhancement('Shield') or cdr:HasEnhancement('ShieldGeneratorField') or cdr:HasEnhancement('ShieldHeavy')) and cdr:ShieldIsOn() then
                        shieldPercent = (cdr.MyShield:GetHealth() / cdr.MyShield:GetMaxHealth())
                    else
                        shieldPercent = 1
                    end
                end
            until cdr.Dead or (cdr:GetHealthPercent() > 0.75 and shieldPercent > 0.35 and nmeAir < 5 and nmeLand < 10 and nmeHardcore == 0 and nmeT3 < 5)

            cdr.GoingHome = false
            IssueClearCommands({cdr})
            aiBrain.BaseMonitor.CDRDistress = false
            aiBrain.BaseMonitor.CDRThreatLevel = 0
            if cdr.UnitBeingBuiltBehavior then
                cdr:ForkThread(CDRFinishUnit)
            end
        end
    end
end

function CDROverChargeSorian(aiBrain, cdr)
    local weapBPs = cdr:GetBlueprint().Weapon
    local weapon
    for k, v in weapBPs do
        if v.Label == 'OverCharge' then
            weapon = v
            break
        end
    end

    local distressRange = 100
    local maxRadius = weapon.MaxRadius * 4.55
    local weapRange = weapon.MaxRadius
    cdr.UnitBeingBuiltBehavior = false

    local cdrPos = cdr.CDRHome
    local numUnits1 = aiBrain:GetNumUnitsAroundPoint(categories.LAND * categories.TECH1 - categories.SCOUT - categories.ENGINEER, cdrPos, maxRadius, 'Enemy')
    local numUnits2 = aiBrain:GetNumUnitsAroundPoint(categories.LAND * categories.TECH2 - categories.SCOUT - categories.ENGINEER, cdrPos, maxRadius, 'Enemy')
    local numUnits3 = aiBrain:GetNumUnitsAroundPoint(categories.LAND * categories.TECH3 - categories.SCOUT - categories.ENGINEER, cdrPos, maxRadius, 'Enemy')
    local numUnitsEng = aiBrain:GetNumUnitsAroundPoint(categories.ENGINEER * (categories.TECH1 + categories.TECH2 + categories.TECH3), cdrPos, maxRadius, 'Enemy')
    local numUnits4 = aiBrain:GetNumUnitsAroundPoint(categories.EXPERIMENTAL, cdrPos, maxRadius + 130, 'Enemy')
    local numStructs = aiBrain:GetNumUnitsAroundPoint(categories.STRUCTURE, cdrPos, maxRadius, 'Enemy')
    local numUnitsDF = aiBrain:GetNumUnitsAroundPoint(categories.DEFENSE * categories.STRUCTURE * categories.DIRECTFIRE - categories.TECH1, cdrPos, maxRadius + 50, 'Enemy')
    local numUnitsDF1 = aiBrain:GetNumUnitsAroundPoint(categories.DEFENSE * categories.STRUCTURE * categories.DIRECTFIRE * categories.TECH1, cdrPos, maxRadius + 30, 'Enemy')
    local numUnitsIF = aiBrain:GetNumUnitsAroundPoint(categories.DEFENSE * categories.STRUCTURE * categories.INDIRECTFIRE - categories.TECH1, cdrPos, maxRadius + 260, 'Enemy')
    local totalUnits = numUnits1 + numUnits2 + numUnits3 + numUnits4 + numStructs + numUnitsEng
    local distressLoc = aiBrain:BaseMonitorDistressLocation(cdrPos)

    if (cdr:HasEnhancement('Shield') or cdr:HasEnhancement('ShieldGeneratorField') or cdr:HasEnhancement('ShieldHeavy')) and cdr:ShieldIsOn() then
        shieldPercent = (cdr.MyShield:GetHealth() / cdr.MyShield:GetMaxHealth())
    else
        shieldPercent = 1
    end



    if Utilities.XZDistanceTwoVectors(cdrPos, cdr:GetPosition()) > distressRange then
        return
    end

    local commanderResponse = false
    if distressLoc then
        local distressUnitsNaval = aiBrain:GetNumUnitsAroundPoint(categories.NAVAL, distressLoc, 40, 'Enemy')
        local distressUnitsAir = aiBrain:GetNumUnitsAroundPoint(categories.AIR * (categories.BOMBER + categories.GROUNDATTACK + categories.ANTINAVY), distressLoc, 30, 'Enemy')
        local distressUnitsexp = aiBrain:GetNumUnitsAroundPoint(categories.EXPERIMENTAL, distressLoc, 50, 'Enemy')
        if distressUnitsNaval > 0 then
            if cdr:HasEnhancement('NaniteTorpedoTube') and distressUnitsNaval < 5 and distressUnitsexp < 1 then
                commanderResponse = true
            else
                commanderResponse = false
            end
        elseif distressUnitsAir > 0 then
            commanderResponse = false
        elseif distressUnitsexp > 0 then
            commanderResponse = false
        elseif numUnits1 > 14 or numUnits2 > 9 or numUnits3 > 4 or numUnits4 > 0 or numUnitsDF > 0 or numUnitsIF > 0 or numUnitsDF1 > 2 then
            commanderResponse = false
        else
            commanderResponse = true
        end
    end

    local overCharging = false
    if (cdr:GetHealthPercent() > 0.85 and shieldPercent > 0.35) and ((totalUnits > 0 and numUnits1 < 15 and numUnits2 < 10 and numUnits3 < 5 and numUnits4 < 1 and numUnitsDF1 < 3 and numUnitsDF < 1 and numUnitsIF < 1) or (not cdr.DistressCall and distressLoc and commanderResponse and Utilities.XZDistanceTwoVectors(distressLoc, cdrPos) < distressRange)) then
        CDRRevertPriorityChange(aiBrain, cdr)
        if cdr.UnitBeingBuilt then
            cdr.UnitBeingBuiltBehavior = cdr.UnitBeingBuilt
        end

        cdr.Fighting = true
        cdr.GoingHome = false
        cdr.Upgrading = false
        local plat = aiBrain:MakePlatoon('', '')
        aiBrain:AssignUnitsToPlatoon(plat, {cdr}, 'support', 'None')
        plat:Stop()

        local priList = {categories.ENERGYPRODUCTION * categories.STRUCTURE * categories.DRAGBUILD, categories.TECH3 * categories.INDIRECTFIRE,
            categories.TECH3 * categories.MOBILE, categories.TECH2 * categories.INDIRECTFIRE, categories.MOBILE * categories.TECH2,
            categories.TECH1 * categories.INDIRECTFIRE, categories.TECH1 * categories.MOBILE, categories.CONSTRUCTION * categories.STRUCTURE, categories.ECONOMIC * categories.STRUCTURE, categories.ALLUNITS}
        plat:SetPrioritizedTargetList('support', priList)
        cdr:SetTargetPriorities(priList)

        local target
        local continueFighting = true
        local counter = 0
        local cdrThreat = cdr:GetBlueprint().Defense.SurfaceThreatLevel or 75
        local enemyThreat
        repeat
            overCharging = false
            local cdrCurrentPos = cdr:GetPosition()
            if counter >= 5 or not target or target.Dead or Utilities.XZDistanceTwoVectors(cdrPos, target:GetPosition()) > maxRadius then
                counter = 0
                for _, v in priList do
                    target = plat:FindClosestUnit('Support', 'Enemy', true, v)
                    if target and Utilities.XZDistanceTwoVectors(cdrPos, target:GetPosition()) < maxRadius then
                        local cdrLayer = cdr:GetCurrentLayer()
                        local targetLayer = target:GetCurrentLayer()
                        if not (cdrLayer == 'Land' and (targetLayer == 'Air' or targetLayer == 'Sub' or targetLayer == 'Seabed')) and
                           not (cdrLayer == 'Seabed' and (targetLayer == 'Air' or targetLayer == 'Water')) then
                            break
                        end
                    end
                    target = false
                end
                if target then
                    local targetPos = target:GetPosition()
                    enemyThreat = aiBrain:GetThreatAtPosition(targetPos, 1, true, 'AntiSurface')
                    enemyCdrThreat = aiBrain:GetThreatAtPosition(targetPos, 1, true, 'Commander')
                    friendlyThreat = aiBrain:GetThreatAtPosition(targetPos, 1, true, 'AntiSurface', aiBrain:GetArmyIndex())
                    if enemyThreat - enemyCdrThreat >= friendlyThreat + cdrThreat then
                        return
                    end
                    if aiBrain:GetEconomyStored('ENERGY') >= weapon.EnergyRequired and target and not target.Dead and Utilities.XZDistanceTwoVectors(cdrCurrentPos, target:GetPosition()) <= weapRange then
                        overCharging = true
                        IssueClearCommands({cdr})
                        IssueOverCharge({cdr}, target)
                    elseif target and not target.Dead then
                        local tarPos = target:GetPosition()
                        IssueClearCommands({cdr})
                        IssueMove({cdr}, tarPos)
                        IssueMove({cdr}, cdr.CDRHome)
                    end
                elseif distressLoc then
                    enemyThreat = aiBrain:GetThreatAtPosition(distressLoc, 1, true, 'AntiSurface')
                    enemyCdrThreat = aiBrain:GetThreatAtPosition(distressLoc, 1, true, 'Commander')
                    friendlyThreat = aiBrain:GetThreatAtPosition(distressLoc, 1, true, 'AntiSurface', aiBrain:GetArmyIndex())
                    if enemyThreat - enemyCdrThreat >= friendlyThreat + (cdrThreat / 1.5) then
                        return
                    end
                    if distressLoc and (Utilities.XZDistanceTwoVectors(distressLoc, cdrPos) < distressRange) then
                        IssueClearCommands({cdr})
                        IssueMove({cdr}, distressLoc)
                        IssueMove({cdr}, cdr.CDRHome)
                    end
                end
            end
            if overCharging then
                while target and not target.Dead and not cdr.Dead and counter <= 5 do
                    WaitSeconds(0.5)
                    counter = counter + 0.5
                end
            else
                WaitSeconds(5)
                counter = counter + 5
            end

            distressLoc = aiBrain:BaseMonitorDistressLocation(cdrPos)
            if cdr.Dead then
                return
            end

            if (cdr:HasEnhancement('Shield') or cdr:HasEnhancement('ShieldGeneratorField') or cdr:HasEnhancement('ShieldHeavy')) and cdr:ShieldIsOn() then
                shieldPercent = (cdr.MyShield:GetHealth() / cdr.MyShield:GetMaxHealth())
            else
                shieldPercent = 1
            end

            enemyThreat = aiBrain:GetThreatAtPosition(cdrPos, 1, true, 'AntiSurface')
            enemyCdrThreat = aiBrain:GetThreatAtPosition(cdrPos, 1, true, 'Commander')
            friendlyThreat = aiBrain:GetThreatAtPosition(cdrPos, 1, true, 'AntiSurface', aiBrain:GetArmyIndex())
            if ((aiBrain:GetNumUnitsAroundPoint(categories.LAND - categories.SCOUT, cdrPos, maxRadius, 'Enemy') == 0)
                and (not distressLoc or (Utilities.XZDistanceTwoVectors(distressLoc, cdrPos) > distressRange)
                and (Utilities.XZDistanceTwoVectors(cdr.CDRHome, cdr:GetPosition()) < maxRadius))) or enemyThreat - enemyCdrThreat >= friendlyThreat + (cdrThreat / 1.5) or (aiBrain:GetNumUnitsAroundPoint(categories.LAND - categories.SCOUT, cdrPos, maxRadius, 'Enemy')) >= 15 or (cdr:GetHealthPercent() < .80 or shieldPercent < .30) then
                continueFighting = false
            end
        until not continueFighting or not aiBrain:PlatoonExists(plat)

        cdr.Fighting = false
        IssueClearCommands({cdr})
        if overCharging then
            IssueMove({cdr}, cdr.CDRHome)
        end

        if cdr.UnitBeingBuiltBehavior then
            cdr:ForkThread(CDRFinishUnit)
        end
    end
end

function CDRReturnHomeSorian(aiBrain, cdr, Mult)
    -- This is a reference... so it will autoupdate
    local cdrPos = cdr:GetPosition()
    local rad = 100 * Mult
    local distSqAway = rad * rad
    local loc = cdr.CDRHome
    if not cdr.Dead and VDist2Sq(cdrPos[1], cdrPos[3], loc[1], loc[3]) > distSqAway then
        local plat = aiBrain:MakePlatoon('', '')
        aiBrain:AssignUnitsToPlatoon(plat, {cdr}, 'support', 'None')
        IssueClearCommands({cdr})

        repeat
            CDRRevertPriorityChange(aiBrain, cdr)
            cdr.GoingHome = true
            cdr.Fighting = false
            cdr.Upgrading = false
            if not aiBrain:PlatoonExists(plat) then
                return
            end
            IssueMove({cdr}, loc)
            WaitSeconds(7)
            cdrPos = cdr:GetPosition()
        until cdr.Dead or VDist2Sq(cdrPos[1], cdrPos[3], loc[1], loc[3]) <= (rad / 2) * (rad / 2)

        cdr.GoingHome = false
        IssueClearCommands({cdr})
    end
end

function CDRFinishUnit(cdr)
    if cdr.UnitBeingBuiltBehavior and not cdr.UnitBeingBuiltBehavior:BeenDestroyed() then
        IssueClearCommands({cdr})
        IssueRepair({cdr}, cdr.UnitBeingBuiltBehavior)
        repeat
            WaitSeconds(1)
            if cdr.GoingHome or cdr:IsUnitState("Attacking") or cdr.Fighting then
                return
            end
        until cdr:IsIdleState()

        IssueClearCommands({cdr})
        cdr.UnitBeingBuiltBehavior = false
    end
end

function CommanderBehaviorSorian(platoon)
    for _, v in platoon:GetPlatoonUnits() do
        if not v.Dead and not v.CommanderThread then
            v.CommanderThread = v:ForkThread(CommanderThreadSorian, platoon)
        end
    end
end

function CDRHideBehavior(aiBrain, cdr)
    if cdr:IsIdleState() then
        cdr.GoingHome = false
        cdr.Fighting = false
        cdr.Upgrading = false

        local category = false
        local runShield = false
        local runPos = false
        local nmaShield = aiBrain:GetNumUnitsAroundPoint(categories.SHIELD * categories.STRUCTURE, cdr:GetPosition(), 100, 'Ally')
        local nmaPD = aiBrain:GetNumUnitsAroundPoint(categories.DIRECTFIRE * categories.DEFENSE, cdr:GetPosition(), 100, 'Ally')
        local nmaAA = aiBrain:GetNumUnitsAroundPoint(categories.ANTIAIR * categories.DEFENSE, cdr:GetPosition(), 100, 'Ally')

        if nmaShield > 0 then
            category = categories.SHIELD * categories.STRUCTURE
            runShield = true
        elseif nmaAA > 0 then
            category = categories.DEFENSE * categories.ANTIAIR
        elseif nmaPD > 0 then
            category = categories.DEFENSE * categories.DIRECTFIRE
        end

        if category then
            runPos = AIUtils.AIFindDefensiveAreaSorian(aiBrain, cdr, category, 100, runShield)
            IssueClearCommands({cdr})
            IssueMove({cdr}, runPos)
        end

        if not category or not runPos then
            local x, z = aiBrain:GetArmyStartPos()
            runPos = AIUtils.RandomLocation(x, z)
            IssueClearCommands({cdr})
            IssueMove({cdr}, runPos)
        end
    end
end

function CommanderThreadSorian(cdr, platoon)
    if platoon.PlatoonData.aggroCDR then
        local mapSizeX, mapSizeZ = GetMapSize()
        local size = mapSizeX
        if mapSizeZ > mapSizeX then
            size = mapSizeZ
        end
        cdr.Mult = (size / 2) / 100
    end

    SetCDRHome(cdr, platoon)

    local aiBrain = cdr:GetAIBrain()
    aiBrain:BuildScoutLocationsSorian()
    if not SUtils.CheckForMapMarkers(aiBrain) then
        SUtils.AISendChat('all', ArmyBrains[aiBrain:GetArmyIndex()].Nickname, 'badmap')
    end

    moveOnNext = false
    moveWait = 0
    local Mult = cdr.Mult or 1
    local Delay = platoon.PlatoonData.Delay or 165
    local WaitTaunt = 600 + Random(1, 600)
    while not cdr.Dead do
        if Mult > 1 and (SBC.GreaterThanGameTime(aiBrain, 1200) or not SBC.EnemyToAllyRatioLessOrEqual(aiBrain, 1.0) or not SBC.ClosestEnemyLessThan(aiBrain, 750) or not SUtils.CheckForMapMarkers(aiBrain)) then
            Mult = 1
        end
        WaitTicks(1)

        -- Overcharge
        if Mult == 1 and not cdr.Dead and not cdr.Upgrading and SBC.GreaterThanGameTime(aiBrain, Delay) and
        UCBC.HaveGreaterThanUnitsWithCategory(aiBrain,  1, 'FACTORY') and aiBrain:GetNoRushTicks() <= 0 then
            CDROverChargeSorian(aiBrain, cdr)
        end
        WaitTicks(1)

        -- Run Away
        if not cdr.Dead then CDRRunAwaySorian(aiBrain, cdr) end
        WaitTicks(1)

        -- Go back to base
        if not cdr.Dead then CDRReturnHomeSorian(aiBrain, cdr, Mult) end
        WaitTicks(1)

        if not cdr.Dead and cdr:IsIdleState() and moveOnNext then
            CDRHideBehavior(aiBrain, cdr)
            moveOnNext = false
        end
        WaitTicks(1)

        if not cdr.Dead and cdr:IsIdleState() and not cdr.GoingHome and not cdr.Fighting and not cdr.Upgrading and not cdr:IsUnitState("Building")
        and not cdr:IsUnitState("Attacking") and not cdr:IsUnitState("Repairing") and not cdr.UnitBeingBuiltBehavior and not cdr:IsUnitState("Upgrading")
        and not cdr:IsUnitState("Enhancing") and not moveOnNext then
            moveWait = moveWait + 1
            if moveWait >= 10 then
                moveWait = 0
                moveOnNext = true
            end
        else
            moveWait = 0
        end
        WaitTicks(1)

        -- Call platoon resume building deal...
        if not cdr.Dead and cdr:IsIdleState() and not cdr.GoingHome and not cdr.Fighting and not cdr.Upgrading and not cdr:IsUnitState("Building")
        and not cdr:IsUnitState("Attacking") and not cdr:IsUnitState("Repairing") and not cdr.UnitBeingBuiltBehavior and not cdr:IsUnitState("Upgrading")
        and not cdr:IsUnitState("Enhancing") and not (SUtils.XZDistanceTwoVectorsSq(cdr.CDRHome, cdr:GetPosition()) > 100) then
            if not cdr.EngineerBuildQueue or table.getn(cdr.EngineerBuildQueue) == 0 then
                local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
                aiBrain:AssignUnitsToPlatoon(pool, {cdr}, 'Unassigned', 'None')
            elseif cdr.EngineerBuildQueue and table.getn(cdr.EngineerBuildQueue) ~= 0 then
                if not cdr.NotBuildingThread then
                    cdr.NotBuildingThread = cdr:ForkThread(platoon.WatchForNotBuildingSorian)
                end
            end
        end
        WaitSeconds(1)

        if not cdr.Dead and GetGameTimeSeconds() > WaitTaunt and (not aiBrain.LastVocTaunt or GetGameTimeSeconds() - aiBrain.LastVocTaunt > WaitTaunt) then
            SUtils.AIRandomizeTaunt(aiBrain)
            WaitTaunt = 600 + Random(1, 900)
        end
    end
end

function AirUnitRefitSorian(self)
    for k, v in self:GetPlatoonUnits() do
        if not v.Dead and not v.RefitThread then
            v.RefitThread = v:ForkThread(AirUnitRefitThreadSorian, self:GetPlan(), self.PlatoonData)
        end
    end
end

function AirUnitRefitThreadSorian(unit, plan, data)
    unit.PlanName = plan
    if data then
        unit.PlatoonData = data
    end

    local aiBrain = unit:GetAIBrain()
    while not unit.Dead do
        local fuel = unit:GetFuelRatio()
        local health = unit:GetHealthPercent()
        if not unit.Loading and (fuel < 0.2 or health < 0.4) then

            -- Find air stage
            if aiBrain:GetCurrentUnits(categories.AIRSTAGINGPLATFORM - categories.CARRIER - categories.EXPERIMENTAL) > 0 then
                local unitPos = unit:GetPosition()
                local plats = AIUtils.GetOwnUnitsAroundPoint(aiBrain, categories.AIRSTAGINGPLATFORM - categories.CARRIER - categories.EXPERIMENTAL, unitPos, 400)
                if table.getn(plats) > 0 then
                    local closest, distance
                    for k, v in plats do
                        if not v.Dead then
                            local roomAvailable = false
                            if not EntityCategoryContains(categories.CARRIER, v) then
                                roomAvailable = v:TransportHasSpaceFor(unit)
                            end
                            if roomAvailable and (not v.Refueling or table.getn(v.Refueling) < 6) then
                                local platPos = v:GetPosition()
                                local tempDist = VDist2(unitPos[1], unitPos[3], platPos[1], platPos[3])
                                if (not closest or tempDist < distance) then
                                    closest = v
                                    distance = tempDist
                                end
                            end
                        end
                    end
                    if closest then
                        local plat = aiBrain:MakePlatoon('', '')
                        aiBrain:AssignUnitsToPlatoon(plat, {unit}, 'Attack', 'None')
                        IssueStop({unit})
                        IssueClearCommands({unit})
                        IssueTransportLoad({unit}, closest)
                        if EntityCategoryContains(categories.AIRSTAGINGPLATFORM, closest) and not closest.AirStaging then
                            closest.AirStaging = closest:ForkThread(AirStagingThreadSorian)
                            closest.Refueling = {}
                        elseif EntityCategoryContains(categories.CARRIER, closest) and not closest.CarrierStaging then
                            closest.CarrierStaging = closest:ForkThread(CarrierStagingThread)
                            closest.Refueling = {}
                        end
                        table.insert(closest.Refueling, unit)
                        unit.Loading = true
                    end
                end
            end
        end
        WaitSeconds(1)
    end
end

function AirStagingThreadSorian(unit)
    local aiBrain = unit:GetAIBrain()
    while not unit.Dead do
        local ready = true
        local numUnits = 0
        for _, v in unit.Refueling do
            if not v.Dead and (v:GetFuelRatio() < 0.9 or v:GetHealthPercent() < 0.9) then
                ready = false
            elseif not v.Dead then
                numUnits = numUnits + 1
            end
        end

        local cargo = unit:GetCargo()
        if ready and numUnits == 0 and table.getn(cargo) > 0 then
            local pos = unit:GetPosition()
            IssueClearCommands({unit})
            IssueTransportUnload({unit}, {pos[1] + 5, pos[2], pos[3] + 5})
            for _, v in cargo do
                local plat
                if not v.PlanName then
                    plat = aiBrain:MakePlatoon('', 'AirHuntAI')
                else
                    plat = aiBrain:MakePlatoon('', v.PlanName)
                end

                if v.PlatoonData then
                    plat.PlatoonData = {}
                    plat.PlatoonData = v.PlatoonData
                end
                aiBrain:AssignUnitsToPlatoon(plat, {v}, 'Attack', 'GrowthFormation')
            end
        end
        if numUnits > 0 then
            WaitSeconds(2)
            for k, v in unit.Refueling do
                if not v.Dead and not v:IsUnitState('Attached') and (v:GetFuelRatio() < .9 or v:GetHealthPercent() < .9) then
                    v.Loading = false
                    local plat
                    if not v.PlanName then
                        plat = aiBrain:MakePlatoon('', 'AirHuntAI')
                    else
                        plat = aiBrain:MakePlatoon('', v.PlanName)
                    end

                    if v.PlatoonData then
                        plat.PlatoonData = {}
                        plat.PlatoonData = v.PlatoonData
                    end
                    aiBrain:AssignUnitsToPlatoon(plat, {v}, 'Attack', 'GrowthFormation')
                    unit.Refueling[k] = nil
                end
            end
        end
        WaitSeconds(10)
    end
end

AssignExperimentalPrioritiesSorian = function(platoon)
    local platoonUnits = platoon:GetPlatoonUnits()
    for k, v in platoonUnits do
        if v and not v.Dead then
            SetLandTargetPrioritiesSorian(v, T4WeaponPrioritiesSorian)
        end
    end
end

SetLandTargetPrioritiesSorian = function(self, priTable)
    for i = 1, self:GetWeaponCount() do
        local wep = self:GetWeapon(i)

        if wep:GetBlueprint().CannotAttackGround then
            continue
        end

        for onLayer, targetLayers in wep:GetBlueprint().FireTargetLayerCapsTable do
            if string.find(targetLayers, 'Land') then
                wep:SetWeaponPriorities(priTable)
                break
            end
        end
    end
end

WreckBaseSorian = function(self, base)
    for _, priority in SurfacePrioritiesSorian do
        local numUnitsAtBase = 0
        local notDeadUnit = false
        local unitsAtBase = self:GetBrain():GetUnitsAroundPoint(ParseEntityCategory(priority), base.Position, 200, 'Enemy')

        for _, unit in unitsAtBase do
            if not unit.Dead then
                notDeadUnit = unit
                numUnitsAtBase = numUnitsAtBase + 1
            end
        end

        if numUnitsAtBase > 0 then
            return notDeadUnit, base
        end
    end

    return false, false
end

FindExperimentalTargetSorian = function(self)
    local aiBrain = self:GetBrain()
    if not aiBrain.InterestList or not aiBrain.InterestList.HighPriority then
        -- No target
        return
    end

    -- For each priority in SurfacePriorities list, check against each enemy base we're aware of (through scouting/intel),
    -- The base with the most number of the highest-priority targets gets selected. If there's a tie, pick closer.
    local enemyBases = aiBrain.InterestList.HighPriority
    for _, priority in SurfacePrioritiesSorian do
        local bestBase = false
        local mostUnits = 0
        local bestUnit = false
        for _, base in enemyBases do
            local unitsAtBase = aiBrain:GetUnitsAroundPoint(ParseEntityCategory(priority), base.Position, 100, 'Enemy')
            local numUnitsAtBase = 0
            local notDeadUnit = false

            for _, unit in unitsAtBase do
                if not unit.Dead and unit:GetPosition() then
                    notDeadUnit = unit
                    numUnitsAtBase = numUnitsAtBase + 1
                end
            end

            if numUnitsAtBase > 0 then
                if numUnitsAtBase > mostUnits then
                    bestBase = base
                    mostUnits = numUnitsAtBase
                    bestUnit = notDeadUnit
                elseif numUnitsAtBase == mostUnits then
                    local myPos = self:GetPlatoonPosition()
                    local dist1 = VDist2(myPos[1], myPos[3], base.Position[1], base.Position[3])
                    local dist2 = VDist2(myPos[1], myPos[3], bestBase.Position[1], bestBase.Position[3])
                    if dist1 < dist2 then
                        bestBase = base
                        bestUnit = notDeadUnit
                    end
                end
            end
        end
        if bestBase and bestUnit then
            return bestUnit, bestBase
        end
    end

    return false, false
end

CommanderOverrideCheckSorian = function(self)
    local platoonUnits = self:GetPlatoonUnits()
    local experimental
    for _, v in platoonUnits do
        if not v.Dead then
            experimental = v
            break
        end
    end

    if not experimental or experimental.Dead then
        return false
    end

    local mainWeapon = experimental:GetWeapon(1)
    local weaponRange = mainWeapon:GetBlueprint().MaxRadius

    local aiBrain = self:GetBrain()
    local commanders = aiBrain:GetUnitsAroundPoint(categories.COMMAND, self:GetPlatoonPosition(), weaponRange, 'Enemy')

    if table.getn(commanders) == 0 or commanders[1].Dead or commanders[1]:GetCurrentLayer() == 'Seabed' then
        return false
    end

    local currentTarget = mainWeapon:GetCurrentTarget()
    if commanders[1] ~= currentTarget then
        -- Commander in range who isn't our current target. Force weapons to reacquire targets so they'll grab him.
        for k, v in platoonUnits do
            if not v.Dead then
                for i=1, v:GetWeaponCount() do
                    v:GetWeapon(i):ResetTarget()
                end
            end
        end
    end

    -- Return the commander so an attack order can be issued or something
    return commanders[1]
end

GetHighestThreatClusterLocationSorian = function(aiBrain, experimental)
    if not aiBrain or not aiBrain:PlatoonExists(experimental) then
        return nil
    end

    -- Look for commander first
    local position = experimental:GetPlatoonPosition()
    local threatTable = aiBrain:GetThreatsAroundPosition(position, 16, true, 'Commander')
    for _, threat in threatTable do
        if threat[3] > 0 then
            local unitsAtLocation = aiBrain:GetUnitsAroundPoint(ParseEntityCategory('COMMAND'), {threat[1], 0, threat[2]}, ScenarioInfo.size[1] / 16, 'Enemy')
            local validUnit = false
            for _, unit in unitsAtLocation do
                if not unit.Dead then
                    validUnit = unit
                    break
                end
            end
            if validUnit then
                return table.copy(validUnit:GetPosition())
            end
        end
    end

    -- Now look through the bases for the highest economic threat and largest cluster of units
    local enemyBases = aiBrain.InterestList.HighPriority

    if not aiBrain.InterestList or not aiBrain.InterestList.HighPriority then
        -- No target
        return aiBrain:GetHighestThreatPosition(0, true, 'Economy')
    end

    local bestBaseThreat = nil
    local maxBaseThreat = 0
    for _, base in enemyBases do
        local threatTable = aiBrain:GetThreatsAroundPosition(base.Position, 1, true, 'Economy')
        if table.getn(threatTable) ~= 0 then
            if threatTable[1][3] > maxBaseThreat then
                maxBaseThreat = threatTable[1][3]
                bestBaseThreat = threatTable
            end
        end
    end

    if not bestBaseThreat then
        -- No threat
        return
    end

    -- Look for a cluster of structures
    local maxUnits = -1
    local bestThreat = 1
    for idx, threat in bestBaseThreat do
        if threat[3] > 0 then
            local unitsAtLocation = aiBrain:GetUnitsAroundPoint(ParseEntityCategory('STRUCTURE'), {threat[1], 0, threat[2]}, ScenarioInfo.size[1] / 16, 'Enemy')
            local numunits = table.getn(unitsAtLocation)

            if numunits > maxUnits then
                maxUnits = numunits
                bestThreat = idx
            end
        end
    end

    if bestBaseThreat[bestThreat] then
        local bestPos = {0, 0, 0}
        local maxUnits = 0
        local lookAroundTable = {-2, -1, 0, 1, 2}
        local squareRadius = (ScenarioInfo.size[1] / 16) / table.getn(lookAroundTable)
        for ix, offsetX in lookAroundTable do
            for iz, offsetZ in lookAroundTable do
                local unitsAtLocation = aiBrain:GetUnitsAroundPoint(ParseEntityCategory('STRUCTURE'), {bestBaseThreat[bestThreat][1] + offsetX * squareRadius, 0, bestBaseThreat[bestThreat][2] + offsetZ * squareRadius}, squareRadius, 'Enemy')
                local numUnits = table.getn(unitsAtLocation)
                if numUnits > maxUnits then
                    maxUnits = numUnits
                    bestPos = table.copy(unitsAtLocation[1]:GetPosition())
                end
            end
        end

        if bestPos[1] ~= 0 and bestPos[3] ~= 0 then
            return bestPos
        end
    end

    return nil
end

ExpPathToLocation = function(aiBrain, platoon, layer, dest, aggro, pathDist)
    local cmd = false
    local platoonUnits = platoon:GetPlatoonUnits()
    local path, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, layer, platoon:GetPlatoonPosition(), dest, nil, nil, pathDist)
    if not path then
        if aggro == 'AttackMove' then
            cmd = platoon:AggressiveMoveToLocation(dest)
        elseif aggro ~= 'AttackDest' then
            cmd = platoon:MoveToLocation(dest, false)
        end
    else
        local pathSize = table.getn(path)
        for k, point in path do
            if k == pathSize and aggro == 'AttackDest' then
                -- Let the main script issue the move to attack the target
            elseif aggro == 'AttackMove' then
                cmd = platoon:AggressiveMoveToLocation(point)
            else
                cmd = platoon:MoveToLocation(point, false)
            end
        end
    end

    return cmd
end

CzarBehaviorSorian = function(self)
    local aiBrain = self:GetBrain()
    if not aiBrain:PlatoonExists(self) then
        return
    end

    if not self:GatherUnitsSorian() then
        return
    end

    AssignExperimentalPrioritiesSorian(self)

    local cmd
    local targetUnit, targetBase = FindExperimentalTargetSorian(self)
    local platoonUnits = self:GetPlatoonUnits()
    local oldTargetUnit = nil
    while aiBrain:PlatoonExists(self) do
        self:MergeWithNearbyPlatoonsSorian('ExperimentalAIHubSorian', 50, true)
        if (targetUnit and targetUnit ~= oldTargetUnit) or not self:IsCommandsActive(cmd) then
            if targetUnit and VDist3(targetUnit:GetPosition(), self:GetPlatoonPosition()) > 100 then
                IssueClearCommands(platoonUnits)
                WaitTicks(5)

                cmd = ExpPathToLocation(aiBrain, self, 'Air', targetUnit:GetPosition(), false, 62500)
                cmd = self:AttackTarget(targetUnit)
            else
                IssueClearCommands(platoonUnits)
                WaitTicks(5)

                cmd = self:AttackTarget(targetUnit)
            end
        end

        local nearCommander = CommanderOverrideCheckSorian(self)
        local oldCommander = nil
        while nearCommander and aiBrain:PlatoonExists(self) and self:IsCommandsActive(cmd) do
            if nearCommander and nearCommander ~= oldCommander then
                IssueClearCommands(platoonUnits)
                WaitTicks(5)

                cmd = self:AttackTarget(nearCommander)
                targetUnit = nearCommander
            end
            WaitSeconds(1)

            oldCommander = nearCommander
            nearCommander = CommanderOverrideCheckSorian(self)
        end
        WaitSeconds(1)

        oldTargetUnit = targetUnit
        targetUnit, targetBase = FindExperimentalTarget(self)
    end
end

AhwassaBehaviorSorian = function(self)
    local aiBrain = self:GetBrain()
    if not aiBrain:PlatoonExists(self) then
        return
    end

    if not self:GatherUnitsSorian() then
        return
    end

    AssignExperimentalPrioritiesSorian(self)
    local targetLocation = GetHighestThreatClusterLocationSorian(aiBrain, self)
    local oldTargetLocation = nil
    local platoonUnits = self:GetPlatoonUnits()
    while aiBrain:PlatoonExists(self) do
        self:MergeWithNearbyPlatoonsSorian('ExperimentalAIHubSorian', 50, true)
        if targetLocation and targetLocation ~= oldTargetLocation then
            IssueClearCommands(platoonUnits)
            cmd = ExpPathToLocation(aiBrain, self, 'Air', targetLocation, 'AttackDest', 62500)
            IssueAttack(platoonUnits, targetLocation)
            WaitSeconds(25)
        end
        WaitSeconds(1)

        oldTargetLocation = targetLocation
        targetLocation = GetHighestThreatClusterLocationSorian(aiBrain, self)
    end
end

TickBehaviorSorian = function(self)
    local aiBrain = self:GetBrain()
    if not aiBrain:PlatoonExists(self) then
        return
    end

    if not self:GatherUnitsSorian() then
        return
    end

    AssignExperimentalPrioritiesSorian(self)
    local targetLocation = GetHighestThreatClusterLocationSorian(aiBrain, self)
    local oldTargetLocation = nil
    local platoonUnits = self:GetPlatoonUnits()
    local cmd
    while aiBrain:PlatoonExists(self) do
        self:MergeWithNearbyPlatoonsSorian('ExperimentalAIHubSorian', 50, true)
        if (targetLocation and targetLocation ~= oldTargetLocation) or not self:IsCommandsActive(cmd) then
            IssueClearCommands(platoonUnits)
            cmd = ExpPathToLocation(aiBrain, self, 'Air', targetLocation, false, 62500)
            WaitSeconds(25)
        end
        WaitSeconds(1)

        oldTargetLocation = targetLocation
        targetLocation = GetHighestThreatClusterLocationSorian(aiBrain, self)
    end
end

function ScathisBehaviorSorian(self)
    local aiBrain = self:GetBrain()

    AssignExperimentalPrioritiesSorian(self)

    -- Find target loop
    local experimental
    local targetUnit = false
    local lastBase = false
    local airUnit = false
    local platoonUnits = self:GetPlatoonUnits()
    while aiBrain:PlatoonExists(self) do
        if lastBase then
            targetUnit, lastBase = WreckBaseSorian(self, lastBase)
        end

        if not lastBase then
            targetUnit, lastBase = FindExperimentalTargetSorian(self)
        end

        if targetUnit then
            IssueClearCommands(platoonUnits)
            IssueAggressiveMove(platoonUnits, targetUnit:GetPosition())
        end

        -- Walk to and kill target loop
        while aiBrain:PlatoonExists(self) and targetUnit and not targetUnit.Dead do
            local nearCommander = CommanderOverrideCheckSorian(self)
            if nearCommander and nearCommander ~= targetUnit then
                IssueClearCommands(platoonUnits)
                IssueAggressiveMove(platoonUnits, nearCommander:GetPosition())
                targetUnit = nearCommander
            end

            -- Check if we or the target are under a shield
            local closestBlockingShield = false
            for k, v in platoonUnits do
                if not v.Dead then
                    experimental = v
                    break
                end
            end

            if not airUnit then
                closestBlockingShield = GetClosestShieldProtectingTargetSorian(experimental, experimental)
            end
            closestBlockingShield = closestBlockingShield or GetClosestShieldProtectingTargetSorian(experimental, targetUnit)

            -- Kill shields loop
            while closestBlockingShield do
                IssueClearCommands({experimental})
                IssueAggressiveMove({experimental}, closestBlockingShield:GetPosition())

                -- Wait for shield to die loop
                while not closestBlockingShield.Dead and aiBrain:PlatoonExists(self) do
                    self:MergeWithNearbyPlatoonsSorian('ExperimentalAIHubSorian', 50, true)
                    WaitSeconds(1)
                end

                closestBlockingShield = false
                for k, v in platoonUnits do
                    if not v.Dead then
                        experimental = v
                        break
                    end
                end
                if not airUnit then
                    closestBlockingShield = GetClosestShieldProtectingTargetSorian(experimental, experimental)
                end
                closestBlockingShield = closestBlockingShield or GetClosestShieldProtectingTargetSorian(experimental, targetUnit)
                WaitSeconds(1)
            end
            WaitSeconds(1)
        end
        WaitSeconds(1)
    end
end

function InWaterCheck(platoon)
    local t4Pos = platoon:GetPlatoonPosition()
    local inWater = GetTerrainHeight(t4Pos[1], t4Pos[3]) < GetSurfaceHeight(t4Pos[1], t4Pos[3])

    return inWater
end

function FatBoyBehaviorSorian(self)
    if not self:GatherUnitsSorian() then
        return
    end

    AssignExperimentalPrioritiesSorian(self)

    -- Find target loop
    local experimental
    local targetUnit = false
    local lastBase = false
    local airUnit = false
    local useMove = true
    local aiBrain = self:GetBrain()
    local platoonUnits = self:GetPlatoonUnits()
    local cmd
    while aiBrain:PlatoonExists(self) do
        self:MergeWithNearbyPlatoonsSorian('ExperimentalAIHubSorian', 50, true)
        if lastBase then
            targetUnit, lastBase = WreckBaseSorian(self, lastBase)
        end

        if not lastBase then
            targetUnit, lastBase = FindExperimentalTargetSorian(self)
        end

        useMove = InWaterCheck(self)
        if targetUnit then
            IssueClearCommands(platoonUnits)
            if useMove then
                cmd = ExpPathToLocation(aiBrain, self, 'Amphibious', targetUnit:GetPosition(), false)
            else
                cmd = ExpPathToLocation(aiBrain, self, 'Amphibious', targetUnit:GetPosition(), 'AttackMove')
            end
        else
            --LOG('*DEBUG: FatBoy no target.')
        end

        -- Walk to and kill target loop
        while aiBrain:PlatoonExists(self) and targetUnit and not targetUnit.Dead and useMove == InWaterCheck(self) and self:IsCommandsActive(cmd) do
            self:MergeWithNearbyPlatoonsSorian('ExperimentalAIHubSorian', 50, true)
            useMove = InWaterCheck(self)
            local nearCommander = CommanderOverrideCheckSorian(self)
            if nearCommander and nearCommander ~= targetUnit then
                IssueClearCommands(platoonUnits)
                if useMove then
                    cmd = ExpPathToLocation(aiBrain, self, 'Amphibious', nearCommander:GetPosition(), false)
                else
                    cmd = self:AttackTarget(targetUnit)
                end
                targetUnit = nearCommander
            end

            -- Check if we or the target are under a shield
            local closestBlockingShield = false
            for k, v in platoonUnits do
                if not v.Dead then
                    experimental = v
                    break
                end
            end

            if not airUnit then
                closestBlockingShield = GetClosestShieldProtectingTargetSorian(experimental, experimental)
            end
            closestBlockingShield = closestBlockingShield or GetClosestShieldProtectingTargetSorian(experimental, targetUnit)

            -- Kill shields loop
            local oldTarget = false
            while closestBlockingShield do
                oldTarget = oldTarget or targetUnit
                targetUnit = false
                self:MergeWithNearbyPlatoonsSorian('ExperimentalAIHubSorian', 50, true)
                useMove = InWaterCheck(self)
                IssueClearCommands(platoonUnits)
                if useMove then
                    cmd = ExpPathToLocation(aiBrain, self, 'Amphibious', closestBlockingShield:GetPosition(), false)
                else
                    cmd = ExpPathToLocation(aiBrain, self, 'Amphibious', closestBlockingShield:GetPosition(), 'AttackMove')
                end

                -- Wait for shield to die loop
                while not closestBlockingShield.Dead and aiBrain:PlatoonExists(self) and useMove == InWaterCheck(self) and self:IsCommandsActive(cmd) do
                    self:MergeWithNearbyPlatoonsSorian('ExperimentalAIHubSorian', 50, true)
                    useMove = InWaterCheck(self)
                    WaitSeconds(1)
                end

                closestBlockingShield = false
                for k, v in platoonUnits do
                    if not v.Dead then
                        experimental = v
                        break
                    end
                end

                if not airUnit then
                    closestBlockingShield = GetClosestShieldProtectingTargetSorian(experimental, experimental)
                end
                closestBlockingShield = closestBlockingShield or GetClosestShieldProtectingTargetSorian(experimental, oldTarget)
                WaitSeconds(1)
            end
            WaitSeconds(1)
        end
        WaitSeconds(1)
    end
end

function BehemothBehaviorSorian(self)
    if not self:GatherUnitsSorian() then
        return
    end
    AssignExperimentalPrioritiesSorian(self)

    -- Find target loop
    local experimental
    local targetUnit = false
    local lastBase = false
    local airUnit = false
    local useMove = true
    local farTarget = false
    local aiBrain = self:GetBrain()
    local platoonUnits = self:GetPlatoonUnits()
    local cmd
    while aiBrain:PlatoonExists(self) do
        self:MergeWithNearbyPlatoonsSorian('ExperimentalAIHubSorian', 50, true)
        useMove = InWaterCheck(self)
        if lastBase then
            targetUnit, lastBase = WreckBaseSorian(self, lastBase)
        end

        if not lastBase then
            targetUnit, lastBase = FindExperimentalTargetSorian(self)
        end

        farTarget = false
        if targetUnit and SUtils.XZDistanceTwoVectorsSq(self:GetPlatoonPosition(), targetUnit:GetPosition()) >= 40000 then
            farTarget = true
        end

        if targetUnit then
            IssueClearCommands(platoonUnits)
            if useMove or not farTarget then
                cmd = ExpPathToLocation(aiBrain, self, 'Amphibious', targetUnit:GetPosition(), false)
            else
                cmd = ExpPathToLocation(aiBrain, self, 'Amphibious', targetUnit:GetPosition(), 'AttackMove')
            end
        end

        -- Walk to and kill target loop
        local nearCommander = CommanderOverrideCheckSorian(self)
        local ACUattack = false
        while aiBrain:PlatoonExists(self) and targetUnit and not targetUnit.Dead and useMove == InWaterCheck(self) and
        self:IsCommandsActive(cmd) and (nearCommander or ((farTarget and SUtils.XZDistanceTwoVectorsSq(self:GetPlatoonPosition(), targetUnit:GetPosition()) >= 40000) or
        (not farTarget and SUtils.XZDistanceTwoVectorsSq(self:GetPlatoonPosition(), targetUnit:GetPosition()) < 40000))) do
            self:MergeWithNearbyPlatoonsSorian('ExperimentalAIHubSorian', 50, true)
            useMove = InWaterCheck(self)
            nearCommander = CommanderOverrideCheckSorian(self)

            if nearCommander and (nearCommander ~= targetUnit or
            (not ACUattack and SUtils.XZDistanceTwoVectorsSq(self:GetPlatoonPosition(), nearCommander:GetPosition()) < 40000)) then
                IssueClearCommands(platoonUnits)
                if useMove then
                    cmd = ExpPathToLocation(aiBrain, self, 'Amphibious', nearCommander:GetPosition(), false)
                else
                    cmd = self:AttackTarget(targetUnit)
                    ACUattack = true
                end
                targetUnit = nearCommander
            end

            -- Check if we or the target are under a shield
            local closestBlockingShield = false
            for k, v in platoonUnits do
                if not v.Dead then
                    experimental = v
                    break
                end
            end

            if not airUnit then
                closestBlockingShield = GetClosestShieldProtectingTargetSorian(experimental, experimental)
            end
            closestBlockingShield = closestBlockingShield or GetClosestShieldProtectingTargetSorian(experimental, targetUnit)

            -- Kill shields loop
            local oldTarget = false
            while closestBlockingShield do
                oldTarget = oldTarget or targetUnit
                targetUnit = false
                self:MergeWithNearbyPlatoonsSorian('ExperimentalAIHubSorian', 50, true)
                useMove = InWaterCheck(self)
                IssueClearCommands(platoonUnits)
                if useMove or SUtils.XZDistanceTwoVectorsSq(self:GetPlatoonPosition(), closestBlockingShield:GetPosition()) < 40000 then
                    cmd = ExpPathToLocation(aiBrain, self, 'Amphibious', closestBlockingShield:GetPosition(), false)
                else
                    cmd = ExpPathToLocation(aiBrain, self, 'Amphibious', closestBlockingShield:GetPosition(), 'AttackMove')
                end

                local farAway = true
                if SUtils.XZDistanceTwoVectorsSq(self:GetPlatoonPosition(), closestBlockingShield:GetPosition()) < 40000 then
                    farAway = false
                end

                -- Wait for shield to die loop
                while not closestBlockingShield.Dead and aiBrain:PlatoonExists(self) and useMove == InWaterCheck(self)
                and self:IsCommandsActive(cmd) do
                    self:MergeWithNearbyPlatoonsSorian('ExperimentalAIHubSorian', 50, true)
                    useMove = InWaterCheck(self)
                    local targDistSq = SUtils.XZDistanceTwoVectorsSq(self:GetPlatoonPosition(), closestBlockingShield:GetPosition())
                    if (farAway and targDistSq < 40000) or (not farAway and targDistSq >= 40000) then
                        break
                    end
                    WaitSeconds(1)
                end

                closestBlockingShield = false
                for k, v in platoonUnits do
                    if not v.Dead then
                        experimental = v
                        break
                    end
                end

                if not airUnit then
                    closestBlockingShield = GetClosestShieldProtectingTargetSorian(experimental, experimental)
                end
                closestBlockingShield = closestBlockingShield or GetClosestShieldProtectingTargetSorian(experimental, oldTarget)
                WaitSeconds(1)
            end
            WaitSeconds(1)
        end
        WaitSeconds(1)
    end
end

function GetClosestShieldProtectingTargetSorian(attackingUnit, targetUnit)
    if not targetUnit or not attackingUnit then
        return false
    end
    local blockingList = {}

    -- If targetUnit is within the radius of any shields, the shields need to be destroyed.
    local aiBrain = attackingUnit:GetAIBrain()
    local tPos = targetUnit:GetPosition()
    local aPos = attackingUnit:GetPosition()
    local shields = aiBrain:GetUnitsAroundPoint(categories.SHIELD * categories.STRUCTURE, targetUnit:GetPosition(), 50, 'Enemy')
    for _, shield in shields do
        if not shield.Dead then
            local shieldPos = shield:GetPosition()
            local shieldSizeSq = GetShieldRadiusAboveGroundSquared(shield)

            if VDist2Sq(tPos[1], tPos[3], shieldPos[1], shieldPos[3]) < shieldSizeSq then
                table.insert(blockingList, shield)
            end
        end
    end

    -- Return the closest blocking shield
    local closest = false
    local closestDistSq = 999999
    for _, shield in blockingList do
        local shieldPos = shield:GetPosition()
        local distSq = VDist2Sq(aPos[1], aPos[3], shieldPos[1], shieldPos[3])

        if distSq < closestDistSq then
            closest = shield
            closestDistSq = distSq
        end
    end

    return closest
end
