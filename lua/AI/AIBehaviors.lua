-----------------------------------------------------------------
-- File     :  /lua/AIBehaviors.lua
-- Author(s): Robert Oates, Gautam Vasudevan, ...?
-- Summary  :
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local AIUtils = import("/lua/ai/aiutilities.lua")
local Utilities = import("/lua/utilities.lua")
local ScenarioFramework = import("/lua/scenarioframework.lua")
local AIAttackUtils = import("/lua/ai/aiattackutilities.lua")
local UCBC = import("/lua/editor/unitcountbuildconditions.lua")

-- CDR ADD BEHAVIORS
---@param aiBrain AIBrain
---@param cdr CommandUnit
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
            cdr.PlatoonHandle = plat
            cdr.PlatoonHandle.BuilderName = 'CDRRunAway'
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
                            plat:MoveToLocation(runSpot, false)
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

            IssueToUnitClearCommands(cdr)
        end
    end
end

---@param aiBrain AIBrain
---@param cdr CommandUnit
function CDROverCharge(aiBrain, cdr)
    local weapBPs = cdr:GetBlueprint().Weapon
    local weapon

    for k, v in weapBPs do
        if v.Label == 'OverCharge' then
            weapon = v
            break
        end
    end

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
        and not cdr.Initializing
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
        cdr.Combat = true
        if cdr.UnitBeingBuilt then
            cdr.UnitBeingBuiltBehavior = cdr.UnitBeingBuilt
        end
        local plat = aiBrain:MakePlatoon('', '')
        aiBrain:AssignUnitsToPlatoon(plat, {cdr}, 'support', 'None')
        cdr.PlatoonHandle = plat
        cdr.PlatoonHandle.BuilderName = 'CDROverCharge'
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
        local cdrThreat = cdr:GetBlueprint().Defense.SurfaceThreatLevel or 60
        local enemyThreat
        local enemyCdrThreat 
        local friendlyThreat
        repeat
            overCharging = false
            if counter >= 5 or not target or target.Dead or Utilities.XZDistanceTwoVectors(cdrPos, target:GetPosition()) > maxRadius then
                counter = 0
                local searchRadius = 30
                repeat
                    searchRadius = searchRadius + 30
                    for k, v in priList do
                        target = plat:FindClosestUnit('Support', 'Enemy', true, v)
                        if target and Utilities.XZDistanceTwoVectors(cdrPos, target:GetPosition()) <= searchRadius then
                            local cdrLayer = cdr.Layer
                            local targetLayer = target.Layer
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
                        IssueToUnitClearCommands(cdr)
                        IssueOverCharge({cdr}, target)
                    elseif target and not target.Dead then -- Commander attacks even if not enough energy for overcharge
                        IssueToUnitClearCommands(cdr)
                        IssueToUnitMove(cdr, targetPos)
                        IssueToUnitMove(cdr, cdr.CDRHome)
                    end
                elseif distressLoc then
                    enemyThreat = aiBrain:GetThreatAtPosition(distressLoc, 1, true, 'AntiSurface')
                    enemyCdrThreat = aiBrain:GetThreatAtPosition(distressLoc, 1, true, 'Commander')
                    friendlyThreat = aiBrain:GetThreatAtPosition(distressLoc, 1, true, 'AntiSurface', aiBrain:GetArmyIndex())
                    if enemyThreat - enemyCdrThreat >= friendlyThreat + (cdrThreat / 3) then
                        break
                    end
                    if distressLoc and (Utilities.XZDistanceTwoVectors(distressLoc, cdrPos) < distressRange) then
                        IssueToUnitClearCommands(cdr)
                        IssueToUnitMove(cdr, distressLoc)
                        IssueToUnitMove(cdr, cdr.CDRHome)
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
        if cdr.Initializing then
            cdr.Initializing = false
        end
        IssueToUnitClearCommands(cdr)
    end
end

---@param aiBrain AIBrain
---@param cdr CommandUnit
function CDRRevertPriorityChange(aiBrain, cdr)
    if cdr.PreviousPriority and cdr.Platoon and aiBrain:PlatoonExists(cdr.Platoon) then
        aiBrain:PBMSetPriority(cdr.Platoon, cdr.PreviousPriority)
    end
end

---@param aiBrain AIBrain
---@param cdr CommandUnit
function CDRReturnHome(aiBrain, cdr)
    -- This is a reference... so it will autoupdate
    local cdrPos = cdr:GetPosition()
    local distSqAway = 1600
    local loc = cdr.CDRHome
    if not cdr.Initializing and not cdr.Dead and VDist2Sq(cdrPos[1], cdrPos[3], loc[1], loc[3]) > distSqAway then
        local plat = aiBrain:MakePlatoon('', '')
        aiBrain:AssignUnitsToPlatoon(plat, {cdr}, 'support', 'None')
        cdr.PlatoonHandle = plat
        cdr.PlatoonHandle.BuilderName = 'CDRReturnHome'
        repeat
            CDRRevertPriorityChange(aiBrain, cdr)
            if not aiBrain:PlatoonExists(plat) then
                return
            end
            IssueStop({cdr})
            IssueToUnitMove(cdr, loc)
            cdr.GoingHome = true
            WaitSeconds(7)
        until cdr.Dead or VDist2Sq(cdrPos[1], cdrPos[3], loc[1], loc[3]) <= distSqAway

        cdr.Combat = false
        cdr.GoingHome = false
        IssueToUnitClearCommands(cdr)
    end
    if not cdr.Dead and cdr.Combat and VDist2Sq(cdrPos[1], cdrPos[3], loc[1], loc[3]) < distSqAway then
        cdr.Combat = false
    end
end

---@param cdr CommandUnit
---@param plat Platoon
function SetCDRHome(cdr, plat)
    cdr.CDRHome = table.copy(cdr:GetPosition())
end

---@param platoon Platoon
function CommanderBehavior(platoon)
    for _, v in platoon:GetPlatoonUnits() do
        if not v.Dead and not v.CommanderThread then
            v.CommanderThread = v:ForkThread(CommanderThread, platoon)
        end
    end
end

---@param platoon Platoon
function CommanderBehaviorImproved(platoon)
    for _, v in platoon:GetPlatoonUnits() do
        if not v.Dead and not v.CommanderThread then
            v.CommanderThread = v:ForkThread(CommanderThreadImproved, platoon)
        end
    end
end

---@param cdr CommandUnit
---@param platoon Platoon
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

        if not cdr.Dead and not cdr.Combat and cdr.UnitBeingBuiltBehavior then
            cdr:ForkThread(CDRFinishUnit)
        end

        -- Call platoon resume building deal...
        if not cdr.Dead and cdr:IsIdleState() and not cdr.GoingHome and not cdr:IsUnitState("Building")
        and not cdr:IsUnitState("Attacking") and not cdr:IsUnitState("Repairing")
        and not cdr:IsUnitState("Upgrading") and not cdr:IsUnitState('BlockCommandQueue') then
            if not cdr.EngineerBuildQueue or table.empty(cdr.EngineerBuildQueue) then
                local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
                aiBrain:AssignUnitsToPlatoon(pool, {cdr}, 'Unassigned', 'None')
            elseif cdr.EngineerBuildQueue and not table.empty(cdr.EngineerBuildQueue) then
                if not cdr.NotBuildingThread then
                    cdr.NotBuildingThread = cdr:ForkThread(platoon.WatchForNotBuilding)
                end
            end
        end
    end
end

---@param cdr CommandUnit
---@param platoon Platoon
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

        if not cdr.Dead and not cdr.Combat and cdr.UnitBeingBuiltBehavior then
            CDRFinishUnit(cdr)
        end

        -- Call platoon resume building deal...
        if not cdr.Initializing and not cdr.Dead and cdr:IsIdleState() and not cdr.GoingHome and not cdr:IsUnitState("Moving")
        and not cdr:IsUnitState("Building") and not cdr:IsUnitState("Guarding")
        and not cdr:IsUnitState("Attacking") and not cdr:IsUnitState("Repairing")
        and not cdr:IsUnitState("Upgrading") and not cdr:IsUnitState("Enhancing")
        and not cdr:IsUnitState('BlockCommandQueue') then
            -- if we have nothing to build...
            if not cdr.EngineerBuildQueue or table.empty(cdr.EngineerBuildQueue) then
                -- check if the we have still a platton assigned to the CDR
                if cdr.PlatoonHandle then
                    local platoonUnits = cdr.PlatoonHandle:GetPlatoonUnits() or 1
                    -- only disband the platton if we have 1 unit, plan and buildername. (NEVER disband the armypool platoon!!!)
                    if table.getn(platoonUnits) == 1 and (not cdr.PlatoonHandle.ArmyPool) and cdr.PlatoonHandle.BuilderName then
                        --SPEW('ACU PlatoonHandle found. Builder '..cdr.PlatoonHandle.BuilderName..'. Disbanding CDR platoon!')
                        cdr.PlatoonHandle:PlatoonDisband()
                    end
                end
                -- get the global armypool platoon
                local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
                -- assing the CDR to the armypool
                aiBrain:AssignUnitsToPlatoon(pool, {cdr}, 'Unassigned', 'None')
            -- if we have a BuildQueue then continue building
            elseif cdr.EngineerBuildQueue and not table.empty(cdr.EngineerBuildQueue) then
                if not cdr.NotBuildingThread then
                    cdr.NotBuildingThread = cdr:ForkThread(platoon.WatchForNotBuilding)
                end
            end
        end
        WaitTicks(1)
    end
end

--- Generic Unit Behaviors
---@param platoon Platoon
function BuildOnceAI(platoon)
    platoon:BuildOnceAI()
end

---@param self Platoon
function AirUnitRefit(self)
    for k, v in self:GetPlatoonUnits() do
        if not v.Dead and not v.RefitThread then
            v.RefitThreat = v:ForkThread(AirUnitRefitThread, self:GetPlan(), self.PlatoonData)
        end
    end
end

---@param unit Unit
---@param plan any
---@param data any
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
                if not table.empty(plats) then
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
                        IssueToUnitClearCommands(unit)
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

---@param unit Unit
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
            IssueToUnitClearCommands(unit)
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

---@param platoon Platoon
function AirLandToggle(platoon)
    for _, v in platoon:GetPlatoonUnits() do
        if not v.Dead and not v.AirLandToggleThread then
            v.AirLandToggleThread = v:ForkThread(AirLandToggleThread)
        end
    end
end

---@param unit Unit
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

--- Table: SurfacePriorities AKA "Your stuff just got wrecked" priority list.
--- Description:
--- Provides a list of target priorities an experimental should use when
--- wrecking stuff or deciding what stuff should be wrecked next.
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

--- Checks if an enemy commander is within range of the unit's main weapon but not currently targeted.
--- If true, forces weapons to reacquire targets
---@param self Platoon              # the single-experimental platoon to run the behavior on
---@return boolean                  # the commander that was found, else nil
CommanderOverrideCheck = function(self)
    local aiBrain = self:GetBrain()
    local experimental = self:GetPlatoonUnits()[1]

    local mainWeapon = experimental:GetWeapon(1)
    local weaponRange = mainWeapon:GetBlueprint().MaxRadius + 50 -- Look outside range.

    local commanders = aiBrain:GetUnitsAroundPoint(categories.COMMAND, self:GetPlatoonPosition(), weaponRange, 'Enemy')
    if table.empty(commanders) or commanders[1].Dead then
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

--- Finds the experiemental unit in the platoon (assumes platoons are only experimentals)
---@param platoon Platoon
---@return Unit                 # experimental or nil
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

--- Sets the experimental's land weapon target priorities to the SurfacePriorities table.
---@param platoon Platoon
AssignExperimentalPriorities = function(platoon)
    local experimental = GetExperimentalUnit(platoon)
    if experimental then
        experimental:SetLandTargetPriorities(SurfacePriorities)
    end
end

--- Finds a unit in the base we're currently wrecking.
---@param self Platoon          # the single-experimental platoon to run the behavior on
---@param base any              # the base to wreck
---@return boolean              # Unit to wreck, base. Else nil.
---@return any
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

--- Goes through the SurfacePriorities table looking for the enemy base (high priority scouting location. See ScoutingAI in platoon.lua)
--- with the most number of the highest priority targets.
---@param self Platoon      # the single-experimental platoon to run the behavior on
---@return boolean          #  target unit, target base, else nil
---@return boolean
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

----------------------------------
-- Indivitual Unit Behaviors
----------------------------------

-- Generic experimental AI. Find a base with good stuff to destroy, and go attack it.
-- If an enemy commander comes within range of the main weapon, attack it.
---@param self any
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
            IssueToUnitClearCommands(experimental)
            IssueAttack({experimental}, targetUnit)
        end

        -- Walk to and kill target loop
        while not experimental.Dead and not experimental:IsIdleState() do
            local nearCommander = CommanderOverrideCheck(self)
            if nearCommander and nearCommander ~= targetUnit then
                IssueToUnitClearCommands(experimental)
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
                IssueToUnitClearCommands(experimental)
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

--- Since a shield can be vertically offset, its blueprint radius is not truly indicative of its
---protective coverage at ground level. This function gets the square of the actual protective radius of the shield
---@param shield Unit           # the shield to check the radius of
---@return number               # The square of the shield's radius at the surface.
function GetShieldRadiusAboveGroundSquared(shield)
    local BP = shield:GetBlueprint().Defense.Shield
    local width = BP.ShieldSize
    local height = BP.ShieldVerticalOffset

    return width * width - height * height
end

--- Gets the closest shield protecting the target unit
---@param attackingUnit Unit        # the attacking unit
---@param targetUnit Unit           # the unit being attacked
---@return boolean                  # The shield, else false
function GetClosestShieldProtectingTarget(attackingUnit, targetUnit)
    if attackingUnit.Dead or targetUnit.Dead then
        return false
    end
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

--- Find a base to attack. Sit outside of the base in weapon range and build units.
---@param platoon Platoon
---@return boolean
function InWaterCheck(platoon)
    local t4Pos = platoon:GetPlatoonPosition()
    local inWater = GetTerrainHeight(t4Pos[1], t4Pos[3]) < GetSurfaceHeight(t4Pos[1], t4Pos[3])
    return inWater
end

---@param self any
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
            IssueToUnitClearCommands(experimental)

            local useMove = InWaterCheck(self)
            if useMove then
                IssueToUnitMove(experimental, targetUnit:GetPosition())
            else
                IssueAttack({experimental}, targetUnit)
            end

            -- Wait to get in range
            local pos = experimental:GetPosition()
            while VDist2(pos[1], pos[3], lastBase.Position[1], lastBase.Position[3]) > weaponRange + 10
                and not experimental.Dead and not experimental:IsIdleState() do
                    WaitSeconds(5)
            end

            IssueToUnitClearCommands(experimental)

            -- Send our homies to wreck this base
            local goodList = {}
            for _, platoon in experimental.Platoons do
                local platoonUnits = false

                if aiBrain:PlatoonExists(platoon) then
                    platoonUnits = platoon:GetPlatoonUnits()
                end

                if platoonUnits and not table.empty(platoonUnits) then
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

--- Builds a random T3 land unit
---@param self Platoon
function FatBoyBuildCheck(self)
    local aiBrain = self:GetBrain()
    local experimental = GetExperimentalUnit(self)

    -- Randomly build T3 MMLs, siege bots, and percivals.
    local buildUnits = {'uel0303', 'xel0305', 'xel0306', }
    local unitToBuild = table.random(buildUnits)

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
        IssueToUnitClearCommands(unitBeingBuilt)
        IssueGuard({unitBeingBuilt}, experimental)
    end
end

--- AI for fatboy child platoons. Wrecks the base that the fatboy has selected.
--- Once the base is wrecked, the units will return to guard the fatboy until a new
--- target base is reached, at which point they will attack it.
---@param self Platoon
---@param parent any
---@param base any
function FatboyChildBehavior(self, parent, base)
    local aiBrain = self:GetBrain()
    local targetUnit = false

    -- Find target loop
    while aiBrain:PlatoonExists(self) and not table.empty(self:GetPlatoonUnits()) do
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
        while aiBrain:PlatoonExists(self) and not table.empty(self:GetPlatoonUnits()) and not targetUnit.Dead do
            WaitSeconds(3)
        end

        WaitSeconds(1)
    end
end

---@param self any
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
                IssueToUnitClearCommands(unit)
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
                IssueToUnitClearCommands(unitBeingBuilt)
                unitBeingBuilt:ForkThread(TempestBuiltUnitMoveOut, position, testHeading)
            end
            self.BreakOff = false
            numStrucs = aiBrain:GetNumUnitsAroundPoint(categories.STRUCTURE - (categories.MASSEXTRACTION + categories.WALL), position, 65, 'Enemy')
            numNaval = aiBrain:GetNumUnitsAroundPoint((categories.MOBILE * categories.NAVAL) * (categories.EXPERIMENTAL + categories.TECH3 + categories.TECH2), position, 65, 'Enemy')
        end

        if aiBrain:PlatoonExists(self) and not self.Patrolling then
            self:Stop()
            self.Patrolling = true
            local scoutPath = AIUtils.AIGetSortedNavalLocations(self:GetBrain())
            for k, v in scoutPath do
                self:Patrol(v)
            end
        end
        WaitSeconds(5)
    end
end

---@param unit Unit
function TempestUnitDeath(unit)
    if unit.Tempest and not unit.Tempest.Dead and unit.Tempest.BuiltUnitCount then
        unit.Tempest.BuildUnitCount = unit.Tempest.BuildUnitCount - 1
    end
end

---@param unit Unit
---@param platoon Platoon
---@param position Vector
---@param heading number
function TempestBuiltUnitMoveOut(unit, platoon, position, heading)
    if heading >= 270 or heading <= 90 then
        position =  {position[1], position[2], position[3] + 20}
    else
        position = {position[1], position[2], position[3] - 20}
    end

    local counter = 0
    repeat
        IssueToUnitClearCommands(unit)
        IssueToUnitMove(unit, position)
        WaitSeconds(5)
        if unit.Dead then
            return
        end
        counter = counter + 1
    until counter == 4 or platoon.Patrolling
end

--- Finds a good base to attack and attacks it.  Prefers to find a commander to kill.
--- Is unique in that it will issue a ground attack and then a move to keep the beam
--- on while moving, instead of attacking specific targets
---@param self Platoon
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
            IssueToUnitClearCommands(experimental)
            WaitTicks(5)

            -- Move to the target without attacking. This will get it out of your base without the beam on.
            if targetUnit and VDist3(targetUnit:GetPosition(), experimental:GetPosition()) > 50 then
                IssueToUnitMove(experimental, targetUnit:GetPosition())
            else
                IssueAttack({experimental}, experimental:GetPosition())
                WaitTicks(5)

                IssueToUnitMove(experimental, targetUnit:GetPosition())
            end
        end

        local nearCommander = CommanderOverrideCheck(self)
        local oldCommander = nil
        while nearCommander and not experimental.Dead and not experimental:IsIdleState() do
            if nearCommander and nearCommander ~= oldCommander and nearCommander ~= targetUnit then
                IssueToUnitClearCommands(experimental)
                WaitTicks(5)

                IssueAttack({experimental}, experimental:GetPosition())
                WaitTicks(5)

                IssueToUnitMove(experimental, nearCommander:GetPosition())
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

-- Finds a good base to attack and attacks it.
-- Is unique in that it will look for a cluster of units to hit with its large AOE bomb.
---@param self Platoon
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
            IssueToUnitClearCommands(experimental)
            IssueAttack({experimental}, targetLocation)
            WaitSeconds(25)
        end
        WaitSeconds(1)

        oldTargetLocation = targetLocation
        targetLocation = GetHighestThreatClusterLocation(aiBrain, experimental)
    end
end

-- Finds a good base to attack and attacks it.
-- Is unique in that it will look for a cluster of units to hit with its gunshipness.
---@param self Platoon
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
            IssueToUnitClearCommands(experimental)
            IssueAggressiveMove({experimental}, targetLocation)
            WaitSeconds(25)
        end
        WaitSeconds(1)

        oldTargetLocation = targetLocation
        targetLocation = GetHighestThreatClusterLocation(aiBrain, experimental)
    end
end

-- Finds the commander first, or a high economic threat that has a lot of units
-- Good for AoE type attacks
---@param aiBrain AIBrain           # aiBrain for experimental
---@param experimental Unit         # the unit itself
---@return nil                      # position of best place to attack, nil if nothing found
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
        if not table.empty(threatTable) then
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

---@param cdr CommandUnit
function CDRFinishUnit(cdr)
    if cdr.UnitBeingBuiltBehavior and (not cdr.UnitBeingBuiltBehavior:BeenDestroyed()) then
        IssueToUnitClearCommands(cdr)
        IssueRepair({cdr}, cdr.UnitBeingBuiltBehavior)
        repeat
            WaitSeconds(1)
            if cdr.GoingHome or cdr:IsUnitState("Attacking") or cdr.Fighting then
                return
            end
        until cdr:IsIdleState()

        IssueToUnitClearCommands(cdr)
        if cdr.UnitBeingBuiltBehavior and (not cdr.UnitBeingBuiltBehavior:BeenDestroyed()) then
            if cdr.UnitBeingBuiltBehavior:GetFractionComplete() == 1 then
                cdr.UnitBeingBuiltBehavior = false
            end
        else
            cdr.UnitBeingBuiltBehavior = false
        end
    end
end

---@param aiBrain AIBrain
---@param cdr CommandUnit
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
            IssueToUnitClearCommands(cdr)
            IssueToUnitMove(cdr, runPos)
        end

        if not category or not runPos then
            local x, z = aiBrain:GetArmyStartPos()
            runPos = AIUtils.RandomLocation(x, z)
            IssueToUnitClearCommands(cdr)
            IssueToUnitMove(cdr, runPos)
        end
    end
end

---@param aiBrain AIBrain
---@param platoon Platoon
---@param layer Layer
---@param dest Vector
---@param aggro any
---@param pathDist any
---@return boolean
ExpPathToLocation = function(aiBrain, platoon, layer, dest, aggro, pathDist)
    local NavUtils = import("/lua/sim/navutils.lua")
    local cmd = false
    local platoonUnits = platoon:GetPlatoonUnits()
    platoon.PlatoonSurfaceThreat = platoon:GetPlatoonThreat('Surface', categories.ALLUNITS)
    local path, reason = NavUtils.PathToWithThreatThreshold(layer, platoon:GetPlatoonPosition(), dest, aiBrain, NavUtils.ThreatFunctions.AntiSurface, platoon.PlatoonSurfaceThreat * 10, aiBrain.IMAPConfig.Rings)
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

---@param platoon Platoon
---@return boolean
function InWaterCheck(platoon)
    local t4Pos = platoon:GetPlatoonPosition()
    local inWater = GetTerrainHeight(t4Pos[1], t4Pos[3]) < GetSurfaceHeight(t4Pos[1], t4Pos[3])

    return inWater
end

---@param attackingUnit Unit
---@param targetUnit Unit
---@return boolean
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

-- Kept for Mod Support
local AIBuildStructures = import("/lua/ai/aibuildstructures.lua")
local TriggerFile = import("/lua/scenariotriggers.lua")