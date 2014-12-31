-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- General Sim scripts

#==============================================================================
# Diplomacy
#==============================================================================

local sharedUnits = {}

function BreakAlliance( data )

    # You cannot change alliances in a team game
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

function OnAllianceResult( resultData )
    # You cannot change alliances in a team game
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
import('/lua/SimPlayerQuery.lua').AddResultListener( "OfferAlliance", OnAllianceResult )

function KillSharedUnits(owner)
    if sharedUnits[owner] and table.getn(sharedUnits[owner]) > 0 then
        for index,unit in sharedUnits[owner] do
            if not unit:IsDead() and unit.oldowner == owner then
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

    local newUnits = {}
    for k,v in units do
        local owner = v:GetArmy()
        --if owner == ToArmyIndex or GetArmyBrain(owner):IsDefeated() then
        if owner == ToArmyIndex then
            continue
        end

        -- Only allow units not attached to be given. This is because units will give all of it's children over
        -- aswell, so we only want the top level units to be given. Also, don't allow commanders to be given.
        if v:GetParent() ~= v or (v.Parent and v.Parent ~= v) then
            continue
        end

        local unit = v
        local bp = unit:GetBlueprint()
        local unitId = unit:GetUnitId()

        # B E F O R E
        local numNukes = unit:GetNukeSiloAmmoCount()  #looks like one of these 2 works for SMDs also
        local numTacMsl = unit:GetTacticalSiloAmmoCount()
        local unitKills = unit:GetStat('KILLS', 0).Value
        local xp = unit.xp
        local unitHealth = unit:GetHealth()
        local shieldIsOn = false
        local ShieldHealth = 0
        local hasFuel = false
        local fuelRatio = 0
        local enh = {} # enhancements
        local oldowner = unit.oldowner

        if unit.MyShield then
            shieldIsOn = unit:ShieldIsOn()
            ShieldHealth = unit.MyShield:GetHealth()
        end
        if bp.Physics.FuelUseTime and bp.Physics.FuelUseTime > 0 then   # going through the BP to check for fuel
            fuelRatio = unit:GetFuelRatio()                             # usage is more reliable then unit.HasFuel
            hasFuel = true                                              # cause some buildings say they use fuel
        end
        local posblEnh = bp.Enhancements
        if posblEnh then
            for k,v in posblEnh do
                if unit:HasEnhancement( k ) then
                   table.insert( enh, k )
                end
            end
        end

        # changing owner
        unit:OnBeforeTransferingOwnership(ToArmyIndex)
        unit = ChangeUnitArmy(unit,ToArmyIndex)
        if not unit then
            continue
        end

        table.insert(newUnits, unit)

        unit.oldowner = oldowner

        if IsAlly(owner, ToArmyIndex) then
            if unit.oldowner == nil then
                unit.oldowner = owner
                if not sharedUnits[owner] then
                    sharedUnits[owner] = {}
                end
                table.insert(sharedUnits[owner], unit)
            end
        end

        -- A F T E R
        if unitKills and unitKills > 0 then
            unit:AddKills( unitKills )
        end
        if xp and xp > 0 then
            unit:AddXP(xp)
        end
        if enh and table.getn(enh) > 0 then
            for k, v in enh do
                unit:CreateEnhancement( v )
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
            unit:GiveNukeSiloAmmo( (numNukes - unit:GetNukeSiloAmmoCount()) )
        end
        if numTacMsl and numTacMsl > 0 then
            unit:GiveTacticalSiloAmmo( (numTacMsl - unit:GetTacticalSiloAmmoCount()) )
        end
        if unit.MyShield then
            unit.MyShield:SetHealth( unit, ShieldHealth )
            if shieldIsOn then
                unit:EnableShield()
            else
                unit:DisableShield()
            end
        end
        unit:OnAfterTransferingOwnership(owner)
    end
    return newUnits
end

function GiveUnitsToPlayer( data, units )
    if units then
        local owner = units[1]:GetArmy()
        if OkayToMessWithArmy(owner) and IsAlly(owner,data.To) then
            TransferUnitsOwnership( units, data.To )
        end
    end
end

function SetResourceSharing( data )
    if not OkayToMessWithArmy(data.Army) then return end
    local brain = GetArmyBrain(data.Army)
    brain:SetResourceSharing(data.Value)
end

function RequestAlliedVictory( data )
    # You cannot change this in a team game

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


#==============================================================================
# UNIT CAP
#==============================================================================
function UpdateUnitCap(deadArmy)
    # If we are asked to share out unit cap for the defeated army, do the following...
    local mode = ScenarioInfo.Options.ShareUnitCap

    if(not mode or mode == 'none') then
        return
    end

    local totalCount = 0
    local aliveCount = 0
    local alive = {}

    for k,brain in ArmyBrains do
        local index = brain:GetArmyIndex()
        local eligible

        if(mode == 'all' or (mode == 'allies' and IsAlly(deadArmy, index))) then
            eligible = true
        else
            eligible = false
        end

        if eligible then
            if not brain:IsDefeated() then
                table.insert(alive, brain)
            end

            totalCount = totalCount + 1
        end
    end

    aliveCount = table.getsize(alive)
    if aliveCount > 0 then
        local initialCap = tonumber(ScenarioInfo.Options.UnitCap)
        local totalCap = totalCount * initialCap
        local newCap = math.floor(totalCap / aliveCount)

        for _, brain in alive do
            SetArmyUnitCap(brain:GetArmyIndex(), newCap)
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
