-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- General Sim scripts

-- ==============================================================================
-- Diplomacy
-- ==============================================================================

local sharedUnits = {}

function BreakAlliance(data)

    -- You cannot change alliances in a team game
    if ScenarioInfo.TeamGame then
        return
    end

    if OkayToMessWithArmy(data.From) then
        SetAlliance(data.From,data.To,"Enemy")

        if Sync.BrokenAlliances == nil then
            Sync.BrokenAlliances = {}
        end
        table.insert(Sync.BrokenAlliances, { From = data.From, To = data.To })
    end
    import('/lua/SimPing.lua').OnAllianceChange()
end

function OnAllianceResult(resultData)
    -- You cannot change alliances in a team game
    if ScenarioInfo.TeamGame then
        return
    end

    if OkayToMessWithArmy(resultData.From) then
        if resultData.ResultValue == "accept" then
            SetAlliance(resultData.From,resultData.To,"Ally")
            if Sync.FormedAlliances == nil then
                Sync.FormedAlliances = {}
            end
            table.insert(Sync.FormedAlliances, { From = resultData.From, To = resultData.To })
        end
    end
    import('/lua/SimPing.lua').OnAllianceChange()
end
import('/lua/SimPlayerQuery.lua').AddResultListener("OfferAlliance", OnAllianceResult)

function KillSharedUnits(owner)
    if sharedUnits[owner] and table.getn(sharedUnits[owner]) > 0 then
        for index,unit in sharedUnits[owner] do
            if not unit.Dead and unit.oldowner == owner then
                unit:Kill()
            end
        end
        sharedUnits[owner] = {}
    end
end

function TransferUnitsOwnership(units, ToArmyIndex)
    local toBrain = GetArmyBrain(ToArmyIndex)
    if not toBrain or toBrain:IsDefeated() or not units or table.getn(units) < 1 then
        return
    end
    local fromBrain = GetArmyBrain(units[1]:GetArmy())

    table.sort(units, function (a, b) return a:GetBlueprint().Economy.BuildCostMass > b:GetBlueprint().Economy.BuildCostMass end)

    local newUnits = {}
    for k,v in units do
        local owner = v:GetArmy()
        -- Only allow units not attached to be given. This is because units will give all of it's children over
        -- aswell, so we only want the top level units to be given.
        -- Units currently being captured is also denied
        local disallowTransfer = owner == ToArmyIndex or
                                 v:GetParent() ~= v or (v.Parent and v.Parent ~= v) or
                                 v.CaptureProgress > 0

        if disallowTransfer then
            continue
        end

        local unit = v
        local bp = unit:GetBlueprint()
        local unitId = unit:GetUnitId()

        -- B E F O R E
        local numNukes = unit:GetNukeSiloAmmoCount()  -- looks like one of these 2 works for SMDs also
        local numTacMsl = unit:GetTacticalSiloAmmoCount()
        local xp = unit.xp
        local unitHealth = unit:GetHealth()
        local shieldIsOn = false
        local ShieldHealth = 0
        local hasFuel = false
        local fuelRatio = 0
        local enh = {} -- enhancements
        local oldowner = unit.oldowner

        if unit.MyShield then
            shieldIsOn = unit:ShieldIsOn()
            ShieldHealth = unit.MyShield:GetHealth()
        end
        if bp.Physics.FuelUseTime and bp.Physics.FuelUseTime > 0 then   -- going through the BP to check for fuel
            fuelRatio = unit:GetFuelRatio()                             -- usage is more reliable then unit.HasFuel
            hasFuel = true                                              -- cause some buildings say they use fuel
        end
        local posblEnh = bp.Enhancements
        if posblEnh then
            for k,v in posblEnh do
                if unit:HasEnhancement(k) then
                   table.insert(enh, k)
                end
            end
        end

        unit.IsBeingTransferred = true

        -- changing owner
        unit = ChangeUnitArmy(unit,ToArmyIndex)
        if not unit then
            continue
        end

        table.insert(newUnits, unit)

        unit.oldowner = oldowner

        if IsAlly(owner, ToArmyIndex) then
            if not unit.oldowner then
                unit.oldowner = owner
            end

            if not sharedUnits[unit.oldowner] then
                sharedUnits[unit.oldowner] = {}
            end
            table.insert(sharedUnits[unit.oldowner], unit)
        end

        -- A F T E R
        if xp and xp > 0 then
            unit:AddXP(xp)
        end
        if enh and table.getn(enh) > 0 then
            for k, v in enh do
                unit:CreateEnhancement(v)
            end
        end
        if unitHealth > unit:GetMaxHealth() then
            unitHealth = unit:GetMaxHealth()
        end
        unit:SetHealth(unit,unitHealth)
        if hasFuel then
            unit:SetFuelRatio(fuelRatio)
        end
        if numNukes and numNukes > 0 then
            unit:GiveNukeSiloAmmo((numNukes - unit:GetNukeSiloAmmoCount()))
        end
        if numTacMsl and numTacMsl > 0 then
            unit:GiveTacticalSiloAmmo((numTacMsl - unit:GetTacticalSiloAmmoCount()))
        end
        if unit.MyShield then
            unit.MyShield:SetHealth(unit, ShieldHealth)
            if shieldIsOn then
                unit:EnableShield()
            else
                unit:DisableShield()
            end
        end
        if EntityCategoryContains(categories.ENGINEERSTATION, unit) then
            unit:SetPaused(true)
        end

        unit.IsBeingTransferred = false

        v:OnGiven(unit)
    end

    if table.getn(EntityCategoryFilterDown(categories.RESEARCH, newUnits)) > 0 then
        for _,aiBrain in {fromBrain, toBrain} do
            local buildRestrictionVictims = aiBrain:GetListOfUnits(categories.FACTORY + categories.ENGINEER, false)
            for _, victim in buildRestrictionVictims do
                victim:updateBuildRestrictions()
            end
        end
    end

    return newUnits
end

function GiveUnitsToPlayer(data, units)
    if units then
        local owner = units[1]:GetArmy()
        if OkayToMessWithArmy(owner) and IsAlly(owner,data.To) then
            TransferUnitsOwnership(units, data.To)
        end
    end
end

function SetResourceSharing(data)
    if not OkayToMessWithArmy(data.Army) then return end
    local brain = GetArmyBrain(data.Army)
    brain:SetResourceSharing(data.Value)
end

function RequestAlliedVictory(data)
    -- You cannot change this in a team game

    if ScenarioInfo.TeamGame then
        return
    end

    if not OkayToMessWithArmy(data.Army) then return end

    local brain = GetArmyBrain(data.Army)
    brain.RequestingAlliedVictory = data.Value
end

function SetOfferDraw(data)
    if not OkayToMessWithArmy(data.Army) then return end

    local brain = GetArmyBrain(data.Army)
    brain.OfferingDraw = data.Value
end


-- ==============================================================================
-- UNIT CAP
-- ==============================================================================
function UpdateUnitCap(deadArmy)
    -- If we are asked to share out unit cap for the defeated army, do the following...
    local mode = ScenarioInfo.Options.ShareUnitCap
    if not mode or mode == 'none' then return end

    local totalCount = 0
    local aliveCount = 0
    local alive = {}

    for index, brain in ArmyBrains do
        if (mode == 'all' or (mode == 'allies' and IsAlly(deadArmy, index))) and not ArmyIsCivilian(index) then
            if not brain:IsDefeated() then
                brain.index = index
                table.insert(alive, brain)
                aliveCount = aliveCount + 1
            end
            totalCount = totalCount + 1
        end
    end

    if aliveCount > 0 then
        local currentCap = GetArmyUnitCap(alive[1].index) -- First time, this is the initial army cap, but it will update each time this function runs
        local totalCap = (aliveCount + 1) * currentCap -- Total cap for the team/game. Uses aliveCount to take account of currentCap updating
        local newCap = math.floor(totalCap / aliveCount)
        for _, brain in alive do
            SetArmyUnitCap(brain.index, newCap)
        end
    end
end

function SendChatToReplay(data)
    if data.Sender and data.Msg then
        if not Sync.UnitData.Chat then
            Sync.UnitData.Chat = {}
        end
        table.insert(Sync.UnitData.Chat, {sender=data.Sender, msg=data.Msg})
    end
end

function GiveResourcesToPlayer(data)
    SendChatToReplay(data)
    if data.From != -1 then
        if not OkayToMessWithArmy(data.From) then
            return
        end
        local fromBrain = GetArmyBrain(data.From)
        local toBrain = GetArmyBrain(data.To)
        if fromBrain:IsDefeated() or toBrain:IsDefeated() then
            return
        end
        local massTaken = fromBrain:TakeResource('Mass',data.Mass * fromBrain:GetEconomyStored('Mass'))
        local energyTaken = fromBrain:TakeResource('Energy',data.Energy * fromBrain:GetEconomyStored('Energy'))
        toBrain:GiveResource('Mass',massTaken)
        toBrain:GiveResource('Energy',energyTaken)
    end
end
