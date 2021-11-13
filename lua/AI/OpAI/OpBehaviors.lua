#****************************************************************************
#**
#**  File     :  /lua/OpBehaviors.lua
#**  Author(s): DFS
#**
#**  Summary  :
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
#########################################
# Platoon Lua Module                    #
#########################################
local aibrain_methodsAssignUnitsToPlatoon = moho.aibrain_methods.AssignUnitsToPlatoon
local aibrain_methodsGetPlatoonUniquelyNamed = moho.aibrain_methods.GetPlatoonUniquelyNamed
local platoon_methodsMoveToLocation = moho.platoon_methods.MoveToLocation
local platoon_methodsGetPlatoonUnits = moho.platoon_methods.GetPlatoonUnits
local IssueMove = IssueMove
local aibrain_methodsGetArmyStartPos = moho.aibrain_methods.GetArmyStartPos
local aibrain_methodsGetUnitsAroundPoint = moho.aibrain_methods.GetUnitsAroundPoint
local unit_methodsIsIdleState = moho.unit_methods.IsIdleState
local unit_methodsIsUnitState = moho.unit_methods.IsUnitState
local aibrain_methodsGetNumUnitsAroundPoint = moho.aibrain_methods.GetNumUnitsAroundPoint
local aibrain_methodsMakePlatoon = moho.aibrain_methods.MakePlatoon
local IssueRepair = IssueRepair
local next = next
local ipairs = ipairs
local platoon_methodsFindClosestUnit = moho.platoon_methods.FindClosestUnit
local IssueClearCommands = IssueClearCommands
local aibrain_methodsPlatoonExists = moho.aibrain_methods.PlatoonExists
local aibrain_methodsGetEconomyStored = moho.aibrain_methods.GetEconomyStored
local IssueOverCharge = IssueOverCharge
local VDist2 = VDist2

local AIUtils = import('/lua/ai/aiutilities.lua')
local Utilities = import('/lua/utilities.lua')
local AIBuildStructures = import('/lua/ai/aibuildstructures.lua')
local UnitUpgradeTemplates = import('/lua/upgradetemplates.lua').UnitUpgradeTemplates
local StructureUpgradeTemplates = import('/lua/upgradetemplates.lua').StructureUpgradeTemplates
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local AIAttackUtils = import('/lua/ai/aiattackutilities.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')



# ===== CDR ADD BEHAVIORS ===== #
function CDROverchargeBehavior(platoon)
    local cdr = platoon_methodsGetPlatoonUnits(platoon)[1]
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
    local startX, startZ = aibrain_methodsGetArmyStartPos(aiBrain)
    if cdr.CDRData and cdr.CDRData.LeashPosition then
        local tempPos = ScenarioUtils.MarkerToPosition(cdr.CDRData.LeashPosition)
        startX = tempPos[1]
        startZ = tempPos[3]
    end
    cdr.UnitBeingBuiltBehavior = false
    while not cdr:IsDead() do
        if not cdr.Running and not cdr.GivingUp and not cdr.Leashing then
            local cdrPos = cdr:GetPosition()
            local numUnits = aibrain_methodsGetNumUnitsAroundPoint(aiBrain,  categories.LAND - categories.SCOUT, cdrPos, ( weapon.MaxRadius * 2 ), 'Enemy' )
            local overCharging = false
            if numUnits > 0 then
                cdr.Fighting = true
                if cdr:GetUnitBeingBuilt() then
                    #LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': CDR was building something')
                    cdr.UnitBeingBuiltBehavior = cdr:GetUnitBeingBuilt()
                end
                plat = aibrain_methodsMakePlatoon(aiBrain,  '', '' )
                aibrain_methodsAssignUnitsToPlatoon(aiBrain,  plat, {cdr}, 'support', 'None' )
                plat:Stop()
                local priList = { categories.COMMAND, categories.EXPERIMENTAL, categories.TECH3 * categories.INDIRECTFIRE,
                    categories.TECH3 * categories.MOBILE, categories.TECH2 * categories.INDIRECTFIRE, categories.MOBILE * categories.TECH2,
                    categories.TECH1 * categories.INDIRECTFIRE, categories.TECH1 * categories.MOBILE, categories.ALLUNITS }
                #LOG('*AI DEBUG: ARMY ' , repr(aiBrain:GetArmyIndex()),  ': CDR AI ACTIVATE - Commander go fight stuff! -- ' .. numUnits)
                local target
                local continueFighting = true
                local counter = 0
                repeat
                    overCharging = false
                    if counter >= 5 or not target or target:IsDead() or Utilities.GetDistanceBetweenTwoEntities(cdr, target) > ( weapon.MaxRadius * 3 ) then
                        counter = 0
                        for k,v in priList do
                            target = platoon_methodsFindClosestUnit(plat,  'Support', 'Enemy', true, v )
                            if target and Utilities.GetDistanceBetweenTwoEntities(cdr, target) < (weapon.MaxRadius * 2 ) then
                                break
                            end
                            target = false
                        end
                        if target then
                            if aibrain_methodsGetEconomyStored(aiBrain, 'ENERGY') >= weapon.EnergyRequired and target and not target:IsDead() then
                                overCharging = true
                                IssueClearCommands({cdr})
                                IssueOverCharge( {cdr}, target )
                            elseif not target:IsDead() then
                                local tarPos = target:GetPosition()
                                IssueClearCommands( {cdr} )
                                IssueMove( {cdr}, tarPos )
                                if cdr.CDRData and cdr.CDRData.LeashPosition then
                                    local tempPos = ScenarioUtils.MarkerToPosition(cdr.CDRData.LeashPosition)
                                    startX = tempPos[1]
                                    startZ = tempPos[3]
                                end
                                IssueMove( {cdr}, {startX, 0, startZ} )
                            end
                        end
                    end
                    if overCharging then
                        while target and not target:IsDead() and not cdr:IsDead() and counter <= 5 do
                            WaitSeconds(.5)
                            counter = counter + .5
                        end
                    else
                        WaitSeconds(5)
                        counter = counter + 5
                    end
                    cdrPos = cdr:GetPosition()
                    if cdr:IsDead() then
                        return
                    end
                    if ( aibrain_methodsGetNumUnitsAroundPoint(aiBrain,  categories.LAND - categories.SCOUT, cdrPos, ( weapon.MaxRadius * 2 ), 'Enemy' ) <= 1 ) then
                        continueFighting = false
                    end
                until not continueFighting or not aibrain_methodsPlatoonExists(aiBrain, plat)
                if not cdr:IsDead() then
                    if cdr.CDRData and cdr.CDRData.LeashPosition then
                        local tempPos = ScenarioUtils.MarkerToPosition(cdr.CDRData.LeashPosition)
                        startX = tempPos[1]
                        startZ = tempPos[3]
                    end
                    cdr.Fighting = false
                    if overCharging then
                        IssueMove( {cdr}, {startX, 0, startZ} )
                    end
                end
                #LOG('*AI DEBUG: ARMY ', repr(aiBrain:GetArmyIndex()),  ': CDR AI DEACTIVATE - Nothing to see here!')
                if aibrain_methodsPlatoonExists(aiBrain, plat) then
                    cdr:ForkThread( CDRRepairBuildingUnit, plat )
                end
            end
        end
        WaitSeconds(3)
    end
end

function CDRRepairBuildingUnit( cdr, plat )
    local aiBrain = cdr:GetAIBrain()
    if cdr.UnitBeingBuiltBehavior and not cdr.UnitBeingBuiltBehavior:BeenDestroyed() then
        IssueClearCommands( {cdr} )
        IssueRepair( {cdr}, cdr.UnitBeingBuiltBehavior )
        repeat
            WaitSeconds(1)
            if cdr.Fighting or cdr.Running or cdr.GivingUp or cdr.Leashing or cdr.Cornered then
                return
            end
        until unit_methodsIsIdleState(cdr)
        cdr.UnitBeingBuiltBehavior = false
    end
    if not cdr:IsDead() and not ( cdr.Fighting or cdr.Running or cdr.GivingUp or cdr.Leashing or cdr.Cornered ) then
        local pool = aibrain_methodsGetPlatoonUniquelyNamed(aiBrain, 'ArmyPool')
        aibrain_methodsAssignUnitsToPlatoon(aiBrain,  pool, {cdr}, 'Unassigned', 'None' )
    end
end

function CDRLeashThread(cdr)
    # if no radius specified return out of function
    local rad
    if cdr.CDRData and cdr.CDRData.LeashRadius then
        rad = cdr.CDRData.LeashRadius
    else
        return
    end

    local aiBrain = cdr:GetAIBrain()
    local locX, locZ = aibrain_methodsGetArmyStartPos(aiBrain)
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
                local plat = aibrain_methodsMakePlatoon(aiBrain,  '', '' )
                aibrain_methodsAssignUnitsToPlatoon(aiBrain,  plat, {cdr}, 'support', 'none' )
                plat:Stop()
                platoon_methodsMoveToLocation(plat,  loc, false )
                cdr.Leashing = true
                #LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': CDR AI ACTIVATE - Commander leashing to MAIN' )
                WaitSeconds( 10 )
                if not cdr:IsDead() then
                    cdr.Leashing = false
                    if aibrain_methodsPlatoonExists(aiBrain, plat) then
                        cdr:ForkThread( CDRRepairBuildingUnit, plat )
                    end
                end
            end
        end
        WaitSeconds(5)
    end
end

function CDRRunAwayThread( cdr )
    local aiBrain = cdr:GetAIBrain()
    local runSpotX, runSpotZ = aibrain_methodsGetArmyStartPos(aiBrain)
    local runSpot = { runSpotX, 0, runSpotZ }
    if cdr.CDRData and cdr.CDRData.LeashPosition then
        runSpot = ScenarioUtils.MarkerToPosition(cdr.CDRData.LeashPosition)
    end
    while not cdr:IsDead() do
        if cdr:GetHealthPercent() < .4 and not cdr.GivingUp then
            if cdr.CDRData and cdr.CDRData.LeashPosition then
                runSpot = ScenarioUtils.MarkerToPosition(cdr.CDRData.LeashPosition)
            end
            #LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': CDR AI ACTIVATE - CDR RUNNING AWAY' )
            local cdrPos = cdr:GetPosition()
            local nmeAir = aibrain_methodsGetUnitsAroundPoint(aiBrain,  categories.AIR, cdrPos, 25, 'Enemy' )
            local nmeLand = aibrain_methodsGetUnitsAroundPoint(aiBrain,  categories.LAND, cdrPos, 25, 'Enemy' )
            local nmeHardcore = aibrain_methodsGetUnitsAroundPoint(aiBrain,  categories.EXPERIMENTAL, cdrPos, 25, 'Enemy' )
            if ( Utilities.XZDistanceTwoVectors( cdrPos, runSpot) > 15 ) and ( nmeAir > 3 or nmeLand > 3 or nmeHardcore > 0 ) then
                if unit_methodsIsUnitState(cdr, 'Building') then
                    cdr.UnitBeingBuiltBehavior = cdr:GetUnitBeingBuilt()
                end
                cdr.Running = true
                local plat = aibrain_methodsMakePlatoon(aiBrain,  '', '' )
                aibrain_methodsAssignUnitsToPlatoon(aiBrain,  plat, {cdr}, 'support', 'None' )
                repeat
                    plat:Stop()
                    cmd = platoon_methodsMoveToLocation(plat,  runSpot, false )
                    WaitSeconds(3)
                    if not cdr:IsDead() then
                        cdrPos = cdr:GetPosition()
                        nmeAir = aibrain_methodsGetUnitsAroundPoint(aiBrain,  categories.AIR, cdrPos, 25, 'Enemy' )
                        nmeLand = aibrain_methodsGetUnitsAroundPoint(aiBrain,  categories.LAND, cdrPos, 25, 'Enemy' )
                        nmeHardcore = aibrain_methodsGetUnitsAroundPoint(aiBrain,  categories.EXPERIMENTAL, cdrPos, 25, 'Enemy' )
                        if cdr.CDRData and cdr.CDRData.LeashPosition then
                            runSpot = ScenarioUtils.MarkerToPosition(cdr.CDRData.LeashPosition)
                        end
                    end
                until cdr:IsDead() or ( Utilities.XZDistanceTwoVectors( cdrPos, runSpot) > 15 ) or ( nmeAir < 2 and nmeLand < 2 and nmeHardcore == 0 ) or cdr:GetHealthPercent() > .4
                #LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': CDR AI DEACTIVATE - Run away no more!')
                cdr.Running = false
                cdr.Cornered = false
                if not cdr:IsDead() and not cdr.GivingUp and aibrain_methodsPlatoonExists(aiBrain, plat) then
                    cdr:ForkThread( CDRRepairBuildingUnit, plat )
                end
            end
        end
        WaitSeconds(3)
    end
end