----
----
---- This module contains the Sim-side lua functions that can be invoked
---- from the user side.  These need to validate all arguments against
---- cheats and exploits.
----
--
---- We store the callbacks in a sub-table (instead of directly in the
---- module) so that we don't include any

local Callbacks = {}

function DoCallback(name, data, units)
    local fn = Callbacks[name];
    if fn then
        fn(data, units)
    else
        error('No callback named ' .. repr(name))
    end
end

function SecureUnits(units)
    local secure = {}
    if units and type(units) ~= 'table' then
        units = {units}
    end

    for _, u in units or {} do
        if not IsEntity(u) then
            u = GetEntityById(u)
        end

        if IsEntity(u) and OkayToMessWithArmy(u.Army) then
            table.insert(secure, u)
        end
    end

    return secure
end

local SimUtils = import('/lua/SimUtils.lua')
local SimPing = import('/lua/SimPing.lua')
local SimTriggers = import('/lua/scenariotriggers.lua')
local SUtils = import('/lua/ai/sorianutilities.lua')
local LetterArray = { ["Aeon"] = "ua", ["UEF"] = "ue", ["Cybran"] = "ur", ["Seraphim"] = "xs" }

Callbacks.AutoOvercharge = function(data, units)
    for _, u in units or {} do
        if IsEntity(u) and OkayToMessWithArmy(u.Army) and u.SetAutoOvercharge then
            u:SetAutoOvercharge(data.auto == true)
        end
    end
end

Callbacks.PersistFerry = function(data, units)
    local transports = EntityCategoryFilterDown(categories.TRANSPORTATION, SecureUnits(units))
    if table.empty(transports) then return end
    local start = data.route[1]

    local helper = CreateUnit('hel0001', units[1].Army, start[1], start[2], start[3], 1, 1, 1, 1, 'Air')
    table.insert(units, helper)
    IssueClearCommands(units)
    for _, r in data.route do
        IssueFerry(units, r)
    end
end

Callbacks.TransportLock = function(data)
    local units = SecureUnits(data.ids)
    if not units[1] then return end

    for _, u in units do
        u:TransportLock(data.lock == true)
    end
end

Callbacks.ClearCommands = function(data, units)
    local safe = SecureUnits(data.ids or units)
    IssueClearCommands(safe)
end

local CanBuildInSpot = import('/lua/utilities.lua').CanBuildInSpot
Callbacks.CapMex = function(data, units)
    local units = EntityCategoryFilterDown(categories.ENGINEER, SecureUnits(units))
    if not units[1] then return end

    local mex = GetEntityById(data.target)
    if not mex or not EntityCategoryContains(categories.MASSEXTRACTION * categories.STRUCTURE, mex) then return end

    if mex.Layer == 'Seabed' then return end

    local pos = mex:GetPosition()
    local msid
    local builder

    for _, unit in units do
        msid = LetterArray[unit:GetBlueprint().General.FactionName]..'b1106' -- The identity of the storage we'll build
        if unit:CanBuild(msid) then
            builder = unit
            break
        end
    end

    if not builder then return end

    local locations = {
        up = Vector(pos.x, pos.y, pos.z - 2),
        down = Vector(pos.x, pos.y, pos.z + 2),
        left = Vector(pos.x - 2, pos.y, pos.z),
        right = Vector(pos.x + 2, pos.y, pos.z),
    }

    for key, location in locations do
        if CanBuildInSpot(mex, msid, location) then
            IssueBuildMobile({builder}, location, msid, {})
        end
    end

    IssueGuard(units, builder)
end

Callbacks.SpawnAndSetVeterancyUnit = function(data)
    if not CheatsEnabled() then return end
    for bpId in data.bpId do
        for i = 1, data.count do
            local unit = CreateUnitHPR(bpId, data.army, data.pos[1], data.pos[2], data.pos[3], 0, 0, 0)
            if data.veterancy > 0 then
                for vetLvl = 1, data.veterancy do
                    unit:SetVeterancy(vetLvl)
                end
            end
        end
    end
end

Callbacks.BreakAlliance = SimUtils.BreakAlliance

Callbacks.GiveUnitsToPlayer = SimUtils.GiveUnitsToPlayer

Callbacks.GiveResourcesToPlayer = SimUtils.GiveResourcesToPlayer

Callbacks.SetResourceSharing = SimUtils.SetResourceSharing

Callbacks.RequestAlliedVictory = SimUtils.RequestAlliedVictory

Callbacks.SetOfferDraw = SimUtils.SetOfferDraw

Callbacks.SpawnPing = SimPing.SpawnPing

--Nuke Ping
Callbacks.SpawnSpecialPing = SimPing.SpawnSpecialPing

Callbacks.UpdateMarker = SimPing.UpdateMarker

Callbacks.FactionSelection = import('/lua/ScenarioFramework.lua').OnFactionSelect

Callbacks.ToggleSelfDestruct = import('/lua/selfdestruct.lua').ToggleSelfDestruct

Callbacks.MarkerOnScreen = import('/lua/simcameramarkers.lua').MarkerOnScreen

Callbacks.SimDialogueButtonPress = import('/lua/SimDialogue.lua').OnButtonPress

Callbacks.AIChat = SUtils.FinishAIChat

Callbacks.DiplomacyHandler = import('/lua/SimDiplomacy.lua').DiplomacyHandler

Callbacks.Rebuild = function(data, units)
    local wreck = GetEntityById(data.entity)
    if not wreck.AssociatedBP then return end
    local units = SecureUnits(units)
    if not units[1] then return end
    if data.Clear then
        IssueClearCommands(units)
    end

    wreck:Rebuild(units)
end

--Callbacks.GetUnitHandle = import('/lua/debugai.lua').GetHandle

function Callbacks.OnMovieFinished(name)
    ScenarioInfo.DialogueFinished[name] = true
end

Callbacks.OnControlGroupAssign = function(units)
    if ScenarioInfo.tutorial then
        local function OnUnitKilled(unit)
            if ScenarioInfo.ControlGroupUnits then
                for i,v in ScenarioInfo.ControlGroupUnits do
                   if unit == v then
                        table.remove(ScenarioInfo.ControlGroupUnits, i)
                   end
                end
            end
        end


        if not ScenarioInfo.ControlGroupUnits then
            ScenarioInfo.ControlGroupUnits = {}
        end

        -- add units to list
        local entities = {}
        for k,v in units do
            table.insert(entities, GetEntityById(v))
        end
        ScenarioInfo.ControlGroupUnits = table.merged(ScenarioInfo.ControlGroupUnits, entities)

        -- remove units on death
        for k,v in entities do
            SimTriggers.CreateUnitDeathTrigger(OnUnitKilled, v)
            SimTriggers.CreateUnitReclaimedTrigger(OnUnitKilled, v) --same as killing for our purposes
        end
    end
end

Callbacks.OnControlGroupApply = function(units)
    --LOG(repr(units))
end

local SimCamera = import('/lua/SimCamera.lua')

Callbacks.OnCameraFinish = SimCamera.OnCameraFinish




local SimPlayerQuery = import('/lua/SimPlayerQuery.lua')

Callbacks.OnPlayerQuery = SimPlayerQuery.OnPlayerQuery

Callbacks.OnPlayerQueryResult = SimPlayerQuery.OnPlayerQueryResult

Callbacks.PingGroupClick = import('/lua/SimPingGroup.lua').OnClickCallback

Callbacks.GiveOrders = import('/lua/spreadattack.lua').GiveOrders

Callbacks.ValidateAssist = function(data, units)
    units = SecureUnits(units)
    local target = GetEntityById(data.target)
    if units and target then
        for k, u in units do
            if IsEntity(u) and u.Army == target.Army and IsInvalidAssist(u, target) then
                IssueClearCommands({target})
                return
            end
        end
    end
end

function IsInvalidAssist(unit, target)
    if target and target.EntityId == unit.EntityId then
        return true
    elseif not target or not target:GetGuardedUnit() then
        return false
    else
        return IsInvalidAssist(unit, target:GetGuardedUnit())
    end
end

Callbacks.AttackMove = function(data, units)
    if data.Clear then
        IssueClearCommands(units)
    end
    IssueAggressiveMove(units, data.Target)
end

--tells a unit to toggle its pointer
Callbacks.FlagShield = function(data, units)
    units = SecureUnits(units)
    local target = GetEntityById(data.target)
    if units and target then
        for k, u in units do
            if IsEntity(u) and u.PointerEnabled == true then
                u.PointerEnabled = false --turn the pointer flag off
                u:DisablePointer() --turn the pointer off
            end
        end
    end
end

Callbacks.WeaponPriorities = import('/lua/WeaponPriorities.lua').SetWeaponPriorities
