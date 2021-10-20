----
----
---- This module contains the Sim-side lua functions that can be invoked
---- from the user side.  These need to validate all arguments against
---- cheats and exploits.
----
--
---- We store the callbacks in a sub-table (instead of directly in the
---- module) so that we don't include any

--- Used to warn users (mainly developers) once for invalid use of functionality 
local Warnings = { }

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

    -- function CreateUnit(blueprint, army, tx, ty, tz, qx, qy, qz, qw, [layer])
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

--- Name is self explanatory :)
local CanBuildInSpot = import('/lua/utilities.lua').CanBuildInSpot

local LetterArray = { 
    ["Aeon"] = "ua", 
    ["AEON"] = "ua",
    ["UEF"] = "ue", 
    ["Cybran"] = "ur", 
    ["CYBRAN"] = "ur", 
    ["Seraphim"] = "xs",
    ["SERAPHIM"] = "xs",
}

--- Compute the faction-specific blueprint identifier
local function ConstructBlueprintID (faction, blueprintID)
    return LetterArray[faction] .. blueprintID 
end

--- Allocated once to prevent re-allocations and de-allocations 
local buildLocation = Vector(0, 0, 0)

--- Templates for units with a footprint of 1 such as radars and mass extractors
local footprint1 = { 
    -- inner layer for storages
    { {1, 0}, {0, 1}, {-1, 0}, {0, -1}, },

    -- outer layer for fabricators
    { {-2, 0}, {-1, 1}, {0, 2}, {1, 1}, {2, 0}, {1, -1}, {0, -2}, {-1, -1}, },
}

--- Templates for units with a footprint of 3 such as fabricators
local footprint3 = { 
    -- inner layer for storages
    { {-1, 2}, {0, 2}, {1, 2}, {2, 1}, {2, 0}, {2, -1}, {1, -2}, {0, -2}, {-1, -2}, {-2, -1}, {-2, 0}, {-2, 1}, },
}

--- Easy to use table for direct footprint size -> template conversion
local footprints = {
    footprint1,
    { }, -- ease of use
    footprint3
}

--- Computes the n'th layer of a previous layer. Recursive function by definition, use FootprintToLayer for a valid initial state.
-- @param previous The last set of points that represent a leyr.
-- @param layers The number of layers to compute.
local function RetrieveNthStructureLayer (footprint, nthLayer)

    -- attempt to retrieve the right set of layers for this footprint
    local layers = footprints[footprint]

    -- if we have some layers for this footprint
    if layers then 

        -- attempt to retrieve the right layer count
        local layer = layers[nthLayer]

        -- if we have that too
        if layer then 

            -- then we can return that
            return layer 
        end
    end

    -- no structure layer available
    local identifier = "RetrieveNthStructureLayer" .. footprint .. " - " .. nthLayer
    if not Warnings[identifier] then 
        Warnings[identifier] = true
        WARN("Attempted to retrieve a build layer for footprint " .. footprint .. " and layer " .. nthLayer .. " which is not supported. The only supported values are: footprint 1 with layer 0 and 1, footprint 3 with layer 0.")
    end

    -- boo
    return { }
end

--- Called by the UI when right-clicking a mass extractor
Callbacks.CapStructure = function(data, units)

    -- check if we have a structure
    local structure = GetEntityById(data.target)
    if not structure then return end 

    -- we can't cap an extractor that is on the ocean floor
    if structure.Layer == 'Seabed' then return end

    -- check if we have units
    local units = EntityCategoryFilterDown(categories.ENGINEER, SecureUnits(units))
    if not units[1] then return end

    -- check if we have buildings we want to use for capping
    if (not data.ids) or (not data.ids[1]) then return end 

    -- for each ID passed along we will try to cap it
    for k, id in data.ids do 

        -- populate faction table
        local others = { }
        local buildersByFaction = { }

        -- determine of all units in selection what they can build
        for _, unit in units do
            local faction = unit.factionCategory
            local blueprintID = ConstructBlueprintID(faction, id)
            if unit:CanBuild(blueprintID) then
                buildersByFaction[faction] = buildersByFaction[faction] or { }
                table.insert(buildersByFaction[faction], unit)
            else
                table.insert(others, unit)
            end
        end 

        -- sanity check: find at least one engineer that can build the structure in question
        local oneCanBuild = false 
        for k, faction in buildersByFaction do 
            oneCanBuild = true
        end 

        -- check if we have units
        if not oneCanBuild then continue end 

        -- find majority
        local faction = ""
        local builders = { }
        for k, engineers in buildersByFaction do 
            if table.getn(builders) < table.getn(engineers) then 
                builders = engineers 
                faction = k
            end
        end

        -- append the rest to other builders
        for k, engineers in buildersByFaction do 
            if k != faction then 
                for k, engineer in engineers do 
                    table.insert(others, engineer)
                end
            end
        end

        -- compute / retrieve information for capping
        local brain = builders[1]:GetAIBrain()
        local blueprintID = ConstructBlueprintID(faction, id)
        local footprint = structure:GetBlueprint().Footprint
        local layer = RetrieveNthStructureLayer(footprint.SizeX, k)

        -- compute build locations and issue the capping
        local center = structure:GetPosition()
        for k, location in layer do 

            -- determine build location using cached value
            buildLocation[1] = center[1] + 2 * location[1]
            buildLocation[2] = center[2]
            buildLocation[3] = center[3] + 2 * location[2]

            -- order all builders to build
            for _, builder in builders do 
                if brain:CanBuildStructureAt(blueprintID, buildLocation) then 
                    IssueBuildMobile({builder}, buildLocation, blueprintID, {})
                end
            end
        end

        -- assist for all other builders
        IssueGuard(others, builders[1])
    end
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
