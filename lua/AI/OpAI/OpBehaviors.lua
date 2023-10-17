---------------------------------------------------------------------
-- File     :  /lua/OpBehaviors.lua
-- Author(s): DFS
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------

-- Platoon Lua Module --
local Utilities = import("/lua/utilities.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")

-- ===== CDR ADD BEHAVIORS ===== --
---@param platoon Platoon
function CDROverchargeBehavior(platoon)
    local cdr = platoon:GetPlatoonUnits()[1]
    if platoon.CDRData then
        cdr.CDRData = platoon.CDRData
    end
    if not cdr.OverchargeThread then
        cdr.OverchargeThread = cdr:ForkThread( CDROverChargeThread )
    end
    if not cdr.LeashThread then
        cdr.LeashThread = cdr:ForkThread( CDRLeashThread )
    end
    if not cdr.RunAwayThread then
        cdr.RunAwayThread = cdr:ForkThread( CDRRunAwayThread )
    end
end

---@param cdr CommandUnit
function CDROverChargeThread( cdr )
    local aiBrain = cdr:GetAIBrain()
    local weapBPs = cdr:GetBlueprint().Weapon
    local weapon
    for k,v in weapBPs do
        if v.Label == 'OverCharge' then
            weapon = v
            break
        end
    end
    local beingBuilt = false
    local plat
    local startX, startZ = aiBrain:GetArmyStartPos()
    if cdr.CDRData and cdr.CDRData.LeashPosition then
        local tempPos = ScenarioUtils.MarkerToPosition(cdr.CDRData.LeashPosition)
        startX = tempPos[1]
        startZ = tempPos[3]
    end
    cdr.UnitBeingBuiltBehavior = false
    while not cdr:IsDead() do
        if not cdr.Running and not cdr.GivingUp and not cdr.Leashing then
            local cdrPos = cdr:GetPosition()
            local numUnits = aiBrain:GetNumUnitsAroundPoint( categories.LAND - categories.SCOUT, cdrPos, ( weapon.MaxRadius * 2 ), 'Enemy' )
            local overCharging = false
            if numUnits > 0 then
                cdr.Fighting = true
                if cdr:GetUnitBeingBuilt() then
                    --LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': CDR was building something')
                    cdr.UnitBeingBuiltBehavior = cdr:GetUnitBeingBuilt()
                end
                plat = aiBrain:MakePlatoon( '', '' )
                aiBrain:AssignUnitsToPlatoon( plat, {cdr}, 'support', 'None' )
                plat:Stop()
                local priList = { categories.COMMAND, categories.EXPERIMENTAL, categories.TECH3 * categories.INDIRECTFIRE,
                    categories.TECH3 * categories.MOBILE, categories.TECH2 * categories.INDIRECTFIRE, categories.MOBILE * categories.TECH2,
                    categories.TECH1 * categories.INDIRECTFIRE, categories.TECH1 * categories.MOBILE, categories.ALLUNITS }
                --LOG('*AI DEBUG: ARMY ' , repr(aiBrain:GetArmyIndex()),  ': CDR AI ACTIVATE - Commander go fight stuff! -- ' .. numUnits)
                local target
                local continueFighting = true
                local counter = 0
                repeat
                    overCharging = false
                    if counter >= 5 or not target or target:IsDead() or Utilities.GetDistanceBetweenTwoEntities(cdr, target) > ( weapon.MaxRadius * 3 ) then
                        counter = 0
                        for k,v in priList do
                            target = plat:FindClosestUnit( 'Support', 'Enemy', true, v )
                            if target and Utilities.GetDistanceBetweenTwoEntities(cdr, target) < (weapon.MaxRadius * 2 ) then
                                break
                            end
                            target = false
                        end
                        if target then
                            if aiBrain:GetEconomyStored('ENERGY') >= weapon.EnergyRequired and target and not target:IsDead() then
                                overCharging = true
                                IssueToUnitClearCommands(cdr)
                                IssueOverCharge( {cdr}, target )
                            elseif not target:IsDead() then
                                local tarPos = target:GetPosition()
                                IssueToUnitClearCommands(cdr)
                                IssueToUnitMove(cdr, tarPos )
                                if cdr.CDRData and cdr.CDRData.LeashPosition then
                                    local tempPos = ScenarioUtils.MarkerToPosition(cdr.CDRData.LeashPosition)
                                    startX = tempPos[1]
                                    startZ = tempPos[3]
                                end
                                IssueToUnitMove(cdr, {startX, 0, startZ} )
                            end
                        end
                    end
                    if overCharging then
                        while target and not target:IsDead() and not cdr:IsDead() and counter <= 5 do
                            WaitTicks(6)
                            counter = counter + .5
                        end
                    else
                        WaitTicks(51)
                        counter = counter + 5
                    end
                    cdrPos = cdr:GetPosition()
                    if cdr:IsDead() then
                        return
                    end
                    if ( aiBrain:GetNumUnitsAroundPoint( categories.LAND - categories.SCOUT, cdrPos, ( weapon.MaxRadius * 2 ), 'Enemy' ) <= 1 ) then
                        continueFighting = false
                    end
                until not continueFighting or not aiBrain:PlatoonExists(plat)
                if not cdr:IsDead() then
                    if cdr.CDRData and cdr.CDRData.LeashPosition then
                        local tempPos = ScenarioUtils.MarkerToPosition(cdr.CDRData.LeashPosition)
                        startX = tempPos[1]
                        startZ = tempPos[3]
                    end
                    cdr.Fighting = false
                    if overCharging then
                        IssueToUnitMove(cdr, {startX, 0, startZ} )
                    end
                end
                --LOG('*AI DEBUG: ARMY ', repr(aiBrain:GetArmyIndex()),  ': CDR AI DEACTIVATE - Nothing to see here!')
                if aiBrain:PlatoonExists(plat) then
                    cdr:ForkThread( CDRRepairBuildingUnit, plat )
                end
            end
        end
        WaitTicks(31)
    end
end

---@param cdr CommandUnit
---@param plat Platoon
function CDRRepairBuildingUnit( cdr, plat )
    local aiBrain = cdr:GetAIBrain()
    if cdr.UnitBeingBuiltBehavior and not cdr.UnitBeingBuiltBehavior:BeenDestroyed() then
        IssueToUnitClearCommands(cdr)
        IssueRepair( {cdr}, cdr.UnitBeingBuiltBehavior )
        repeat
            WaitTicks(11)
            if cdr.Fighting or cdr.Running or cdr.GivingUp or cdr.Leashing or cdr.Cornered then
                return
            end
        until cdr:IsIdleState()
        cdr.UnitBeingBuiltBehavior = false
    end
    if not cdr:IsDead() and not ( cdr.Fighting or cdr.Running or cdr.GivingUp or cdr.Leashing or cdr.Cornered ) then
        local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
        aiBrain:AssignUnitsToPlatoon( pool, {cdr}, 'Unassigned', 'None' )
    end
end

---@param cdr CommandUnit
function CDRLeashThread(cdr)
    -- if no radius specified return out of function
    local rad
    if cdr.CDRData and cdr.CDRData.LeashRadius then
        rad = cdr.CDRData.LeashRadius
    else
        return
    end

    local aiBrain = cdr:GetAIBrain()
    local locX, locZ = aiBrain:GetArmyStartPos()
    local loc = { locX, 0, locZ }
    if cdr.CDRData and cdr.CDRData.LeashPosition then
        loc = ScenarioUtils.MarkerToPosition( cdr.CDRData.LeashPosition )
    end
    while not cdr:IsDead() do
        if cdr.CDRData and cdr.CDRData.LeashPosition then
            loc = ScenarioUtils.MarkerToPosition( cdr.CDRData.LeashPosition )
        end
        if not cdr.GivingUp and not cdr.Running then
            local cdrPos = cdr:GetPosition()
            if VDist2( cdrPos[1], cdrPos[3], loc[1], loc[3] ) > rad then
                local plat = aiBrain:MakePlatoon( '', '' )
                aiBrain:AssignUnitsToPlatoon( plat, {cdr}, 'support', 'none' )
                plat:Stop()
                plat:MoveToLocation( loc, false )
                cdr.Leashing = true
                --LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': CDR AI ACTIVATE - Commander leashing to MAIN' )
                WaitTicks(101)
                if not cdr:IsDead() then
                    cdr.Leashing = false
                    if aiBrain:PlatoonExists(plat) then
                        cdr:ForkThread( CDRRepairBuildingUnit, plat )
                    end
                end
            end
        end
        WaitTicks(51)
    end
end

---@param cdr CommandUnit
function CDRRunAwayThread( cdr )
    local aiBrain = cdr:GetAIBrain()
    local runSpotX, runSpotZ = aiBrain:GetArmyStartPos()
    local runSpot = { runSpotX, 0, runSpotZ }
    if cdr.CDRData and cdr.CDRData.LeashPosition then
        runSpot = ScenarioUtils.MarkerToPosition(cdr.CDRData.LeashPosition)
    end
    while not cdr:IsDead() do
        if cdr:GetHealthPercent() < .4 and not cdr.GivingUp then
            if cdr.CDRData and cdr.CDRData.LeashPosition then
                runSpot = ScenarioUtils.MarkerToPosition(cdr.CDRData.LeashPosition)
            end
            --LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': CDR AI ACTIVATE - CDR RUNNING AWAY' )
            local cdrPos = cdr:GetPosition()
            local nmeAir = aiBrain:GetUnitsAroundPoint( categories.AIR, cdrPos, 25, 'Enemy' )
            local nmeLand = aiBrain:GetUnitsAroundPoint( categories.LAND, cdrPos, 25, 'Enemy' )
            local nmeHardcore = aiBrain:GetUnitsAroundPoint( categories.EXPERIMENTAL, cdrPos, 25, 'Enemy' )
            if ( Utilities.XZDistanceTwoVectors( cdrPos, runSpot) > 15 ) and ( nmeAir > 3 or nmeLand > 3 or nmeHardcore > 0 ) then
                if cdr:IsUnitState('Building') then
                    cdr.UnitBeingBuiltBehavior = cdr:GetUnitBeingBuilt()
                end
                cdr.Running = true
                local plat = aiBrain:MakePlatoon( '', '' )
                aiBrain:AssignUnitsToPlatoon( plat, {cdr}, 'support', 'None' )
                repeat
                    plat:Stop()
                    cmd = plat:MoveToLocation( runSpot, false )
                    WaitTicks(31)
                    if not cdr:IsDead() then
                        cdrPos = cdr:GetPosition()
                        nmeAir = aiBrain:GetUnitsAroundPoint( categories.AIR, cdrPos, 25, 'Enemy' )
                        nmeLand = aiBrain:GetUnitsAroundPoint( categories.LAND, cdrPos, 25, 'Enemy' )
                        nmeHardcore = aiBrain:GetUnitsAroundPoint( categories.EXPERIMENTAL, cdrPos, 25, 'Enemy' )
                        if cdr.CDRData and cdr.CDRData.LeashPosition then
                            runSpot = ScenarioUtils.MarkerToPosition(cdr.CDRData.LeashPosition)
                        end
                    end
                until cdr:IsDead() or ( Utilities.XZDistanceTwoVectors( cdrPos, runSpot) > 15 ) or ( nmeAir < 2 and nmeLand < 2 and nmeHardcore == 0 ) or cdr:GetHealthPercent() > .4
                --LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': CDR AI DEACTIVATE - Run away no more!')
                cdr.Running = false
                cdr.Cornered = false
                if not cdr:IsDead() and not cdr.GivingUp and aiBrain:PlatoonExists(plat) then
                    cdr:ForkThread( CDRRepairBuildingUnit, plat )
                end
            end
        end
        WaitTicks(31)
    end
end