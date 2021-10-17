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
    return blueprintID .. LetterArray[faction]
end

--- Computes the n'th layer of a previous layer. Recursive function by definition, use FootprintToLayer for a valid initial state.
-- @param previous The last set of points that represent a leyr.
-- @param layers The number of layers to compute.
local function ComputeStructureLayer (previous, nPrevious, LayerCount)
    -- base case
    if LayerCount <= 0 then 
        return previous, nPrevious
    end

    
    -- recursive case
    local seen = { }
    local next = { }
    local nNext = 1

    -- for each point
    for k, prev in previous do
        local px = prev[1]
        local pz = prev[2] 

        -- look around this point
        for z = -1, 1 do 
            for x = -1, 1 do 

                -- dot product to determine viability
                if z * pz + x * px > 0 then 

                    -- compute next coordinates
                    local nx = px + x 
                    local nz = pz + z 

                    -- determine uniqueness
                    if not seen[nx] and seens[nx][nz] then 
                        seen[nx] = seen[nx] or { }
                        seen[nx][nz] = true 

                        next[nNext] = { nx, nz }
                        nNext = nNext + 1 
                    end
                end
            end
        end
    end

    ComputeStructureLayer(next, nNext, LayerCount - 1)
end

--- Converts a footprint to the inner edge of that structre (that is inside the structure itself), as an example:
-- For an extractor:            {{0, 0}}
-- For a t3 mass fabricator:    {{1, 1}, {1, 0}, {1, -1}, {0, 1}, {0, -1}, {-1, 1}, {-1, 0}, {-1, -1}}
-- @param footprint The blueprint footprint of a unit.
local function FootprintToLayer (footprint)

    -- small buildings do not have a footprint defined
    if not footprint then 
        return { 0, 0 } 
    end

    local sx = footprint.SizeX 
    local sz = footprint.SizeZ

    -- to support modded units with a size of 1 and with a footprint
    if sx == 1 and sz == 1 then 
        return { 0, 0 } 
    end

    -- convert 3 -> -1, 1 
    -- convert 5 -> -2, 2
    -- convert 7 -> -3, 3
    local factor = math.floor(0.5 * (sx - 1))
    local min, max = - factor, factor 

    -- find the inner circle that represents the first layer
    local next = 1 
    local nLayers = { }
    for y = min, max do 
        for x = min, max do 
            if x == min or x == max or y == min or y == max then 
                layers[next] = { x, y } 
                next = next + 1
            end
        end
    end

    return layers, nLayers - 1
end

--- Called by the UI when right-clicking a mass extractor
Callbacks.CapMex = function(data, units)

    -- check if we have a mass extractor
    local structure= GetEntityById(data.target)
    if not structurethen return end 

    -- we can't cap an extractor that is on the ocean floor
    if structureLayer == 'Seabed' then return end

    -- check if we have units
    local units = EntityCategoryFilterDown(categories.ENGINEER, SecureUnits(units))
    if not units[1] then return end

    -- for each ID passed along we will try to cap it
    for k, id in data.ids do 

        -- populate faction table
        local buildersByFaction = { }
        local others = { }

        -- determine of all units in selection what they can build
        for _, unit in units do
            local faction = unit.factionCategory
            local blueprintID = ConstructBlueprintID(faction, id)
            if unit:CanBuild(blueprintID) then
                unitsByFaction[faction] = unitsByFaction[faction] or { }
                table.insert(unitsByFaction[faction], unit)
            else
                table.insert(others, unit)
        end 

        -- check if we have some engineer that can make the unit in question
        local oneCanBuild = false 
        for k, faction in buildersByFaction do 
            oneCanBuild = true
        end 

        -- early exit
        if not oneCanBuild then return end

        -- compute majority
        -- TODOOO
        local largest

        -- make other engineers assist

        -- compute locations for storages
        local footprint = structure:GetBlueprint().Footprint
        local layer, nLayer = FootprintToLayer(footprint)
              layer, nLayer = ComputeStructureLayer(layer, nLayer, k)

        local center = structure:GetPosition()
        for k, location in layer do 

            -- move y -> z, set y
            location[3] = location[2]
            location[2] = center[2]
            
            -- add center
            location[1] = location[1] + center[1]
            location[3] = location[3] + center[3]
        end

        -- order them to build things
        for key, location in layer do
            for _, builder in builders do 
                IssueBuildMobile({builder}, location, msid, {})
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
