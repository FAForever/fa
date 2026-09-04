---------------------------------------------------------------------
-- File     :  /lua/OpBehaviors.lua
-- Author(s): DFS
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------

local Utilities = import("/lua/utilities.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")

local XZDist = Utilities.XZDistanceTwoVectors
local DistEnts = Utilities.GetDistanceBetweenTwoEntities

local ipairs = ipairs
local Vector = Vector
local WaitSeconds = WaitSeconds

---@class PlatoonCDRData
---@field CDRData OpAICDRData

---@class OpAICDRData
---@field LeashPosition? MarkerName Name of the marker to return to
---@field LeashRadius? integer Distance to trigger return back to `LeashPosition`

---@class OpAIACUUnit: CommandUnit
---@field Fighting boolean ACU is fighting enemy units
---@field Running boolean ACU is running away due to low HP
---@field GivingUp boolean Not implemented yet
---@field Leashing boolean ACU got too far from the base position and is being moved back
---@field Cornered boolean Not implemented yet
---@field CDRData? OpAICDRData
---@field UnitBeingBuiltBehavior? Unit Reference to the unit commander was building in case it goes fight
---@field OverchargeThread? thread
---@field LeashThread? thread
---@field RunAwayThread? thread

-- Target priorities for the commander OC / fight
CDRTargetPriorities = {
    categories.COMMAND,
    categories.EXPERIMENTAL,
    categories.TECH3 * categories.INDIRECTFIRE,
    categories.TECH3 * categories.MOBILE,
    categories.TECH2 * categories.INDIRECTFIRE,
    categories.MOBILE * categories.TECH2,
    categories.TECH1 * categories.INDIRECTFIRE,
    categories.TECH1 * categories.MOBILE, categories.ALLUNITS
}

---Sets up threads for ACU fighting
--- - actively OC-ing and attacking nearby units.
--- - returning to base if got too far during fight
--- - return to base if on low HP
--- - finish construction projects if they were abandonned for fighting
---@see PlatoonCDRData For required platoon data.
---@param platoon Platoon
function CDROverchargeBehavior(platoon)
    local cdr = platoon:GetPlatoonUnits()[1]--[[@as OpAIACUUnit]]
    if platoon.CDRData then
        cdr.CDRData = platoon.CDRData
    end
    if not cdr.OverchargeThread then
        cdr.OverchargeThread = cdr:ForkThread(CDROverChargeThread)
    end
    if not cdr.LeashThread then
        cdr.LeashThread = cdr:ForkThread(CDRLeashThread)
    end
    if not cdr.RunAwayThread then
        cdr.RunAwayThread = cdr:ForkThread(CDRRunAwayThread)
    end
end

---@param cdr OpAIACUUnit
function CDROverChargeThread(cdr)
    local aiBrain = cdr:GetAIBrain()
    local data = cdr.CDRData
    local weapBPs = cdr:GetBlueprint().Weapon
    ---@cast weapBPs -nil
    ---@type WeaponBlueprint
    local weapon
    for _,v in weapBPs do
        if v.Label == 'OverCharge' then
            weapon = v
            break
        end
    end

    local plat
    ---@type Vector
    local startPos
    if data and data.LeashPosition then
        startPos = ScenarioUtils.MarkerToPosition(data.LeashPosition)
    else
        local locX, locZ = aiBrain:GetArmyStartPos()
        startPos = Vector(locX, 0, locZ)
    end

    local scanCategories = categories.LAND - categories.SCOUT

    cdr.UnitBeingBuiltBehavior = nil
    while not cdr.Dead do
        if not cdr.Running and not cdr.GivingUp and not cdr.Leashing then
            local cdrPos = cdr:GetPosition()
            local numUnits = aiBrain:GetNumUnitsAroundPoint(scanCategories, cdrPos, (weapon.MaxRadius * 2), 'Enemy')
            local overCharging = false

            if numUnits > 0 then
                cdr.Fighting = true
                if cdr.UnitBeingBuilt then
                    --LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': CDR was building something')
                    cdr.UnitBeingBuiltBehavior = cdr.UnitBeingBuilt
                end

                plat = aiBrain:MakePlatoon('', '')
                aiBrain:AssignUnitToPlatoon(plat, cdr, 'Support', 'None')
                plat:Stop()

                local priList = CDRTargetPriorities
                ---@type Unit|nil
                local target
                local continueFighting = true
                local counter = 0

                repeat
                    overCharging = false
                    if counter >= 5 or not target or target.Dead or DistEnts(cdr, target) > (weapon.MaxRadius * 3) then
                        counter = 0
                        for _, v in ipairs(priList) do
                            target = plat:FindClosestUnit('Support', 'Enemy', true, v)
                            if target and DistEnts(cdr, target) < (weapon.MaxRadius * 2) then
                                break
                            end
                            target = nil
                        end

                        if target then
                            if aiBrain:GetEconomyStored('ENERGY') >= weapon.EnergyRequired and not target.Dead then
                                overCharging = true
                                IssueToUnitClearCommands(cdr)
                                IssueOverCharge({cdr}, target)
                            elseif not target.Dead then
                                local tarPos = target:GetPosition()
                                IssueToUnitClearCommands(cdr)
                                IssueToUnitMove(cdr, tarPos)
                                IssueToUnitMove(cdr, startPos)
                            end
                        end
                    end

                    if overCharging then
                        while target and not target.Dead and not cdr.Dead and counter <= 5 do
                            WaitTicks(6)
                            counter = counter + .5
                        end
                    else
                        WaitSeconds(5)
                        counter = counter + 5
                    end
                    if cdr.Dead then return end

                    cdrPos = cdr:GetPosition()
                    if aiBrain:GetNumUnitsAroundPoint(scanCategories, cdrPos, weapon.MaxRadius * 2, 'Enemy') <= 1 then
                        continueFighting = false
                    end
                until not continueFighting or not aiBrain:PlatoonExists(plat)

                if not cdr.Dead then
                    if cdr.CDRData and cdr.CDRData.LeashPosition then
                        startPos = ScenarioUtils.MarkerToPosition(cdr.CDRData.LeashPosition)
                    end

                    cdr.Fighting = false
                    if overCharging then
                        IssueToUnitMove(cdr, startPos)
                    end
                end

                if aiBrain:PlatoonExists(plat) then
                    cdr:ForkThread(CDRRepairBuildingUnit, plat)
                end
            end
        end
        WaitSeconds(3)
    end
end

---Finishes the constructioin of the unit the ACU was previously building
---@param cdr OpAIACUUnit
---@param plat Platoon
function CDRRepairBuildingUnit(cdr, plat)
    local aiBrain = cdr:GetAIBrain()
    local targetUnit = cdr.UnitBeingBuiltBehavior

    if targetUnit and not targetUnit:BeenDestroyed() and targetUnit:GetFractionComplete() < 1 then
        IssueToUnitClearCommands(cdr)
        IssueRepair({cdr}, targetUnit)

        repeat
            WaitSeconds(1)
            if cdr.Fighting or cdr.Running or cdr.GivingUp or cdr.Leashing or cdr.Cornered then
                return
            end
        until cdr:IsIdleState()

        cdr.UnitBeingBuiltBehavior = nil
    end

    if not cdr.Dead and not (cdr.Fighting or cdr.Running or cdr.GivingUp or cdr.Leashing or cdr.Cornered) then
        local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
        aiBrain:AssignUnitToPlatoon(pool, cdr, 'Unassigned', 'NoFormation')
    end
end

---Moves the commander back to the base position if it get's too far while fighting.
---@param cdr OpAIACUUnit
function CDRLeashThread(cdr)
    local data = cdr.CDRData
    local rad = data and data.LeashRadius
    -- if no radius specified return out of function
    if not rad then return end

    local aiBrain = cdr:GetAIBrain()
    ---@type Vector
    local pos
    if data and data.LeashPosition then
        pos = ScenarioUtils.MarkerToPosition(data.LeashPosition)
    else
        local locX, locZ = aiBrain:GetArmyStartPos()
        pos = Vector(locX, 0, locZ)
    end

    while not cdr.Dead do
        if not cdr.GivingUp and not cdr.Running then
            local cdrPos = cdr:GetPosition()

            if XZDist(cdrPos, pos) > rad then
                local plat = aiBrain:MakePlatoon('', '')
                aiBrain:AssignUnitToPlatoon(plat, cdr, 'Support', 'NoFormation')
                plat:Stop()
                plat:MoveToLocation(pos, false)
                cdr.Leashing = true
                --LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': CDR AI ACTIVATE - Commander leashing to MAIN' )
                WaitSeconds(10)

                if not cdr.Dead then
                    cdr.Leashing = false
                    if aiBrain:PlatoonExists(plat) then
                        cdr:ForkThread(CDRRepairBuildingUnit, plat)
                    end
                end
            end
        end
        WaitSeconds(5)
    end
end

---@param cdr OpAIACUUnit
function CDRRunAwayThread(cdr)
    local aiBrain = cdr:GetAIBrain()
    local data = cdr.CDRData
    ---@type Vector
    local runSpot
    if data and data.LeashPosition then
        runSpot = ScenarioUtils.MarkerToPosition(data.LeashPosition)
    else
        local locX, locZ = aiBrain:GetArmyStartPos()
        runSpot = Vector(locX, 0, locZ)
    end

    local hpThreshold = 0.4

    while not cdr.Dead do
        if cdr:GetHealthPercent() < hpThreshold and not cdr.GivingUp then
            --LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': CDR AI ACTIVATE - CDR RUNNING AWAY' )
            local cdrPos = cdr:GetPosition()
            local nmeAir = aiBrain:GetNumUnitsAroundPoint(categories.AIR, cdrPos, 25, 'Enemy')
            local nmeLand = aiBrain:GetNumUnitsAroundPoint(categories.LAND, cdrPos, 25, 'Enemy')
            local nmeHardcore = aiBrain:GetNumUnitsAroundPoint(categories.EXPERIMENTAL, cdrPos, 25, 'Enemy')

            if (XZDist(cdrPos, runSpot) > 15) and (nmeAir > 3 or nmeLand > 3 or nmeHardcore > 0) then
                if cdr:IsUnitState('Building') then
                    cdr.UnitBeingBuiltBehavior = cdr.UnitBeingBuilt
                end

                cdr.Running = true
                local plat = aiBrain:MakePlatoon('', '')
                aiBrain:AssignUnitToPlatoon(plat, cdr, 'Support', 'NoFormation')

                repeat
                    plat:Stop()
                    plat:MoveToLocation(runSpot, false)

                    WaitSeconds(3)

                    if not cdr.Dead then
                        cdrPos = cdr:GetPosition()
                        nmeAir = aiBrain:GetNumUnitsAroundPoint(categories.AIR, cdrPos, 25, 'Enemy')
                        nmeLand = aiBrain:GetNumUnitsAroundPoint(categories.LAND, cdrPos, 25, 'Enemy')
                        nmeHardcore = aiBrain:GetNumUnitsAroundPoint(categories.EXPERIMENTAL, cdrPos, 25, 'Enemy')
                        if cdr.CDRData and cdr.CDRData.LeashPosition then
                            runSpot = ScenarioUtils.MarkerToPosition(cdr.CDRData.LeashPosition)
                        end
                    end
                until cdr.Dead or (XZDist(cdrPos, runSpot) > 15) or (nmeAir < 2 and nmeLand < 2 and nmeHardcore == 0) or cdr:GetHealthPercent() > hpThreshold
                --LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': CDR AI DEACTIVATE - Run away no more!')
                cdr.Running = false
                cdr.Cornered = false
                if not cdr.Dead and not cdr.GivingUp and aiBrain:PlatoonExists(plat) then
                    cdr:ForkThread(CDRRepairBuildingUnit, plat)
                end
            end
        end

        WaitSeconds(3)
    end
end
