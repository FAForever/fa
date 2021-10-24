----
----
---- This module contains the Sim-side lua functions that can be invoked
---- from the user side.  These need to validate all arguments against
---- cheats and exploits.
----
--
---- We store the callbacks in a sub-table (instead of directly in the
---- module) so that we don't include any

local SimUtils = import('/lua/SimUtils.lua')
local SimPing = import('/lua/SimPing.lua')
local SimTriggers = import('/lua/scenariotriggers.lua')
local SUtils = import('/lua/ai/sorianutilities.lua')

-- upvalue table operations for performance
local TableInsert = table.insert
local TableEmpty = table.empty
local TableGetn = table.getn
local TableRemove = table.remove
local TableMerged = table.merged

-- upvalue globals for performance
local type = type
local Vector = Vector
local IsEntity = IsEntity
local GetEntityById = GetEntityById
local GetSurfaceHeight = GetSurfaceHeight
local OkayToMessWithArmy = OkayToMessWithArmy
local EntityCategoryFilterDown = EntityCategoryFilterDown

local IssueClearCommands = IssueClearCommands
local IssueBuildMobile = IssueBuildMobile
local IssueAggressiveMove = IssueAggressiveMove
local IssueGuard = IssueGuard
local IssueFerry = IssueFerry

--- Used to warn users (mainly developers) once for invalid use of functionality 
local Warnings = { }

--- List of callbacks that is being populated throughout this file
local Callbacks = {}

function DoCallback(name, data, units)
    local fn = Callbacks[name];
    if fn then
        fn(data, units)
    else
        error('No callback named ' .. repr(name))
    end
end

--- Common utility function to retrieve the actual units.
local function SecureUnits(units)
    local secure = {}
    if units and type(units) ~= 'table' then
        units = {units}
    end

    for _, u in units or {} do
        if not IsEntity(u) then
            u = GetEntityById(u)
        end

        if IsEntity(u) and OkayToMessWithArmy(u.Army) then
            TableInsert (secure, u)
        end
    end

    return secure
end

Callbacks.AutoOvercharge = function(data, units)
    for _, u in units or {} do
        if IsEntity(u) and OkayToMessWithArmy(u.Army) and u.SetAutoOvercharge then
            u:SetAutoOvercharge(data.auto == true)
        end
    end
end

Callbacks.PersistFerry = function(data, units)
    local transports = EntityCategoryFilterDown(categories.TRANSPORTATION, SecureUnits(units))
    if TableEmpty(transports) then return end
    local start = data.route[1]

    -- function CreateUnit(blueprint, army, tx, ty, tz, qx, qy, qz, qw, [layer])
    local helper = CreateUnit('hel0001', units[1].Army, start[1], start[2], start[3], 1, 1, 1, 1, 'Air')
    TableInsert (units, helper)
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

--- Templates for units with a skirt size of 1, such as point defense
local skirtSize1 = {
    { {-1, 0}, {-1, 1}, {0, 1}, {1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, -1}, },
}

--- Templates for units with a skirtSize of 1 such as radars and mass extractors
local skirtSize2 = { 
    -- inner layer for storages
    { {2, 0}, {0, 2}, {-2, 0}, {0, -2}, },

    -- outer layer for fabricators
    { {-4, 0}, {-2, 2}, {0, 4}, {2, 2}, {4, 0}, {2, -2}, {0, -4}, {-2, -2}, },
}

--- Templates for units with a skirtSize of 3 such as fabricators
local skirtSize6 = { 
    -- inner layer for storages
    { {-2, 4}, {0, 4}, {2, 4}, {4, 2}, {4, 0}, {4, -2}, {2, -4}, {0, -4}, {-2, -4}, {-4, -2}, {-4, 0}, {-4, 2}, },
}

--- Easy to use table for direct skirtSize size -> template conversion
local skirtSizes = {
    skirtSize1,
    skirtSize2,
    { }, -- ease of use
    { }, -- ease of use
    { }, -- ease of use
    skirtSize6
}

--- Computes the n'th layer of a previous layer.
-- @param skirtSize The skirt size of the unit.
-- @param layers The nth layer we'd like to have for this unit.
local function RetrieveNthStructureLayer (skirtSize, nthLayer)

    -- attempt to retrieve the right set of layers for this skirtSize
    local layers = skirtSizes[skirtSize]

    -- if we have some layers for this skirtSize
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
    local identifier = "RetrieveNthStructureLayer" .. skirtSize .. " - " .. nthLayer
    if not Warnings[identifier] then 
        Warnings[identifier] = true
        WARN("Attempted to retrieve a build layer for skirtSize " .. skirtSize .. " and layer " .. nthLayer .. " which is not supported. The only supported values are: skirtSize 1 with layer 1, skirtSize 2 with layer 1 and 2, skirtSize 6 with layer 0.")
    end

    -- boo
    return false
end

--- Called by the UI when right-clicking a mass extractor
Callbacks.CapStructure = function(data, units)

    -- check if we have a structure
    local structure = GetEntityById(data.target)
    if not structure then return end 

    -- check if we're allowed to mess with this structure
    if not OkayToMessWithArmy(structure.Army) then return end

    -- we can't cap an extractor that is on the ocean floor
    if structure.Layer == 'Seabed' then return end

    -- check if we have units
    local units = EntityCategoryFilterDown(categories.ENGINEER, SecureUnits(units))
    if not units[1] then return end

    -- check if we have buildings we want to use for capping
    if (not data.id) or (not data.layer) then return end 

    -- populate faction table
    local others = { }
    local buildersByFaction = { }

    -- determine of all units in selection what they can build
    for _, unit in units do
        -- make sure we're allowed to mess with this unit, if not we exclude
        if OkayToMessWithArmy(unit.Army) then 
            -- compute blueprint id
            local faction = unit.factionCategory
            local blueprintID = ConstructBlueprintID(faction, data.id)

            -- check if this unit can build it
            if unit:CanBuild(blueprintID) then
                buildersByFaction[faction] = buildersByFaction[faction] or { }
                TableInsert(buildersByFaction[faction], unit)
            else
                TableInsert(others, unit)
            end
        end
    end 

    -- sanity check: find at least one engineer that can build the structure in question
    local oneCanBuild = false 
    for k, faction in buildersByFaction do 
        oneCanBuild = true
    end 

    -- check if we have units
    if not oneCanBuild then return end 

    -- find majority
    local faction = ""
    local builders = { }
    for k, engineers in buildersByFaction do 
        if TableGetn(builders) < TableGetn(engineers) then 
            builders = engineers 
            faction = k
        end
    end

    -- append the rest to other builders
    for k, engineers in buildersByFaction do 
        if k != faction then 
            for k, engineer in engineers do 
                TableInsert(others, engineer)
            end
        end
    end

    -- compute / retrieve information for capping
    local brain = builders[1]:GetAIBrain()
    local blueprintID = ConstructBlueprintID(faction, data.id)
    local skirtSize = structure:GetBlueprint().Physics.SkirtSizeX

    -- compute the layer locations
    local layer = RetrieveNthStructureLayer(skirtSize, data.layer)

    -- compute build locations and issue the capping
    local center = structure:GetPosition()
    for k, location in layer do 

        -- determine build location using cached value
        buildLocation[1] = center[1] + location[1]
        buildLocation[3] = center[3] + location[2]
        buildLocation[2] = GetSurfaceHeight(buildLocation[1], buildLocation[3])

        -- order all builders to build if possible
        if brain:CanBuildStructureAt(blueprintID, buildLocation) then 
            for _, builder in builders do 
                IssueBuildMobile({builder}, buildLocation, blueprintID, {})
            end
        end
    end

    -- assist for all other builders
    IssueGuard(others, builders[1])
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
                        TableRemove(ScenarioInfo.ControlGroupUnits, i)
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
            TableInsert(entities, GetEntityById(v))
        end
        ScenarioInfo.ControlGroupUnits = TableMerged(ScenarioInfo.ControlGroupUnits, entities)

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
