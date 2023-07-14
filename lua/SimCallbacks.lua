----
----
---- This module contains the Sim-side lua functions that can be invoked
---- from the user side.  These need to validate all arguments against
---- cheats and exploits.
----
--
---- We store the callbacks in a sub-table (instead of directly in the
---- module) so that we don't include any

---@class SimCallback
---@field Func string
---@field Args table

local SimUtils = import("/lua/simutils.lua")
local SimPing = import("/lua/simping.lua")
local SimTriggers = import("/lua/scenariotriggers.lua")
local SUtils = import("/lua/ai/sorianutilities.lua")
local ScenarioFramework = import("/lua/scenarioframework.lua")

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

-- upvalue categories for performance
local CategoriesTransportation = categories.TRANSPORTATION
local CategoriesEngineer = categories.ENGINEER - categories.INSIGNIFICANTUNIT

--- Used to warn users (mainly developers) once for invalid use of functionality
local Warnings = {}

--- List of callbacks that is being populated throughout this file
---@type table<string, function>
local Callbacks = {}

function DoCallback(name, data, units)
    local fn = Callbacks[name];
    if fn then
        fn(data, units)
    else
        SPEW('No callback named: ' .. repr(name))
    end
end

--- Common utility function to retrieve the actual units.
function SecureUnits(units)
    local secure = {}
    if units and type(units) ~= 'table' then
        units = { units }
    end

    for _, u in units or {} do
        if not IsEntity(u) then
            u = GetEntityById(u)
        end

        if IsEntity(u) and OkayToMessWithArmy(u.Army) then
            TableInsert(secure, u)
        end
    end

    return secure
end

--- Empty callback for ui mods to communicate
Callbacks.EmptyCallback = function(data, units)
end

Callbacks.AutoOvercharge = function(data, units)
    for _, u in units or {} do
        if IsEntity(u) and OkayToMessWithArmy(u.Army) and u.SetAutoOvercharge then
            u:SetAutoOvercharge(data.auto == true)
        end
    end
end

Callbacks.PersistFerry = function(data, units)
    local transports = EntityCategoryFilterDown(CategoriesTransportation, SecureUnits(units))
    if TableEmpty(transports) then return end
    local start = data.route[1]

    -- function CreateUnit(blueprint, army, tx, ty, tz, qx, qy, qz, qw, [layer])
    local helper = CreateUnit('hel0001', units[1].Army, start[1], start[2], start[3], 1, 1, 1, 1, 'Air')
    TableInsert(units, helper)
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
local function ConstructBlueprintID(faction, blueprintID)
    return LetterArray[faction] .. blueprintID
end

--- Allocated once to prevent re-allocations and de-allocations
local buildLocation = Vector(0, 0, 0)

--- Templates for units with a skirt size of 1, such as point defense
local skirtSize1 = {
    { { -1, 0 }, { -1, 1 }, { 0, 1 }, { 1, 1 }, { 1, 0 }, { 1, -1 }, { 0, -1 }, { -1, -1 }, },
}

--- Templates for units with a skirtSize of 1 such as radars and mass extractors
local skirtSize2 = {
    -- inner layer for storages
    { { 2, 0 }, { 0, 2 }, { -2, 0 }, { 0, -2 }, },

    -- outer layer for fabricators
    { { -2, 2 }, { 2, 2 }, { 2, -2 }, { -2, -2 }, { -4, 0 }, { 0, 4 }, { 4, 0 }, { 0, -4 }, },
}

--- Templates for units with a skirtSize of 3 such as fabricators
local skirtSize6 = {
    -- inner layer for storages
    { { -2, 4 }, { 0, 4 }, { 2, 4 }, { 4, 2 }, { 4, 0 }, { 4, -2 }, { 2, -4 }, { 0, -4 }, { -2, -4 }, { -4, -2 },
        { -4, 0 },
        { -4, 2 }, },
}

--- Easy to use table for direct skirtSize size -> template conversion
local skirtSizes = {
    [1] = skirtSize1,
    [2] = skirtSize2,
    [6] = skirtSize6
}

--- Computes the n'th layer of a previous layer.
---@param skirtSize number skirt size of the unit
---@param nthLayer number nth layer we'd like to have for this unit
local function RetrieveNthStructureLayer(skirtSize, nthLayer)

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
        WARN("Attempted to retrieve a build layer for skirtSize " ..
            skirtSize ..
            " and layer " ..
            nthLayer ..
            " which is not supported. The only supported values are: skirtSize 1 with layer 1, skirtSize 2 with layer 1 and 2, skirtSize 6 with layer 0.")
    end

    -- boo
    return false
end

--- Called by the UI when right-clicking a mass extractor
Callbacks.CapStructure = function(data, units)

    -- check if we have a structure
    -- if army is not set then the structure is not 'our' structure (e.g., we're trying to cap an allied or hostile extractor)
    local structure = GetEntityById(data.target)
    if (not structure) or (not structure.Army) then return end

    -- check if we're allowed to mess with this structure
    if not OkayToMessWithArmy(structure.Army) then return end

    -- check if we have units
    local units = EntityCategoryFilterDown(CategoriesEngineer, SecureUnits(units))
    if not units[1] then return end

    -- check if it is our structure
    if structure.Army ~= units[1].Army then return end

    -- check if we have buildings we want to use for capping
    if (not data.id) or (not data.layer) then return end

    -- populate faction table
    local otherBuilders = {}
    local buildersByFaction = {}

    -- determine of all units in selection what they can build
    for _, unit in units do
        -- make sure we're allowed to mess with this unit, if not we exclude
        if unit.Army and OkayToMessWithArmy(unit.Army) then
            -- compute blueprint id
            local faction = unit.Blueprint.FactionCategory
            local blueprintID = ConstructBlueprintID(faction, data.id)

            -- check if this unit can build it
            if unit:CanBuild(blueprintID) then
                buildersByFaction[faction] = buildersByFaction[faction] or {}
                TableInsert(buildersByFaction[faction], unit)
            else
                TableInsert(otherBuilders, unit)
            end
        end
    end

    -- sanity check: find at least one engineer that can build the structure in question
    local oneCanBuild = nil
    for k, faction in buildersByFaction do
        oneCanBuild = true
    end

    -- check if we have units
    if not oneCanBuild then return end

    -- find majority
    local faction = ""
    local builders = {}
    for k, engineers in buildersByFaction do
        if TableGetn(builders) < TableGetn(engineers) then
            builders = engineers
            faction = k
        end
    end

    -- append the rest to other builders
    for k, engineers in buildersByFaction do
        if k ~= faction then
            for k, engineer in engineers do
                TableInsert(otherBuilders, engineer)
            end
        end
    end

    -- -- only keep at most six builders due to performance
    -- local allBuilders = builders
    -- builders = { }
    -- for k, engineer in allBuilders do
    --     if k < 7 then
    --         builders[k] = engineer
    --     else
    --         TableInsert(otherBuilders, engineer)
    --     end
    -- end

    -- compute / retrieve information for capping
    local blueprintID = ConstructBlueprintID(faction, data.id)
    local blueprint = structure:GetBlueprint()
    local skirtSize = blueprint.Physics.SkirtSizeX

    -- compute the layer locations
    local layer = RetrieveNthStructureLayer(skirtSize, data.layer)

    -- check if we got anything valid
    if layer then

        -- compute build locations and issue the capping
        local cx, cy, cz = structure:GetPositionXYZ()

        -- full extent of search rectangle for other buildings
        local x1 = cx - (skirtSize + 10)
        local z1 = cz - (skirtSize + 10)
        local x2 = cx + (skirtSize + 10)
        local z2 = cz + (skirtSize + 10)

        -- find all units that may prevent us from building
        local structures = GetUnitsInRect(x1, z1, x2, z2)
        structures = EntityCategoryFilterDown(categories.STRUCTURE + categories.EXPERIMENTAL, structures)

        -- determine offset to enlarge unit skirt to include structure we're trying to use to cap
        -- this is a hard-coded fix to make walls work
        local offset = 1
        if skirtSize == 1 then
            offset = 0.5
        end

        -- replace unit -> skirt to prevent allocating a new table
        for k, unit in structures do
            local blueprint = unit:GetBlueprint()
            local px, py, pz = unit:GetPositionXYZ()
            local sx, sz = 0.5 * blueprint.Physics.SkirtSizeX, 0.5 * blueprint.Physics.SkirtSizeZ
            local rect = {
                px - sx - offset, -- top left
                pz - sz - offset, -- top left
                px + sx + offset, -- bottom right
                pz + sz + offset -- bottom right
            }

            structures[k] = rect
        end

        -- name convention
        local skirts = structures

        -- loop over build locations in given layer
        for k, location in layer do

            -- determine build location using cached value
            buildLocation[1] = cx + location[1]
            buildLocation[3] = cz + location[2]
            buildLocation[2] = GetTerrainHeight(buildLocation[1], buildLocation[3])

            -- check all skirts manually as brain:CanBuildStructureAt(...) is unreliable when structures have been upgraded
            local freeToBuild = true
            for k, skirt in skirts do
                if buildLocation[1] > skirt[1] and buildLocation[1] < skirt[3] then
                    if buildLocation[3] > skirt[2] and buildLocation[3] < skirt[4] then
                        freeToBuild = false
                        break
                    end
                end
            end

            -- issue if we can build here
            if freeToBuild then
                for _, builder in builders do
                    IssueBuildMobile({ builder }, buildLocation, blueprintID, {})
                end
            end
        end

        -- assist for all other builders, spread over the number of actual builders
        local t = {}
        local builderIndex = 1
        local builderCount = TableGetn(builders)
        for k, builder in otherBuilders do
            t[1] = builder
            IssueGuard(t, builders[builderIndex])

            builderIndex = builderIndex + 1
            if builderIndex > builderCount then
                builderIndex = 1
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

Callbacks.SetRecallVote = import("/lua/sim/recall.lua").SetRecallVote

Callbacks.SpawnPing = SimPing.SpawnPing

--Nuke Ping
Callbacks.SpawnSpecialPing = SimPing.SpawnSpecialPing

Callbacks.UpdateMarker = SimPing.UpdateMarker

Callbacks.FactionSelection = ScenarioFramework.OnFactionSelect

Callbacks.ToggleSelfDestruct = import("/lua/selfdestruct.lua").ToggleSelfDestruct

Callbacks.MarkerOnScreen = import("/lua/simcameramarkers.lua").MarkerOnScreen

Callbacks.SimDialogueButtonPress = import("/lua/simdialogue.lua").OnButtonPress

Callbacks.AIChat = SUtils.FinishAIChat

Callbacks.DiplomacyHandler = import("/lua/simdiplomacy.lua").DiplomacyHandler

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

--Callbacks.GetUnitHandle = import("/lua/debugai.lua").GetHandle

function Callbacks.OnMovieFinished(name)
    ScenarioInfo.DialogueFinished[name] = true
end

Callbacks.OnControlGroupAssign = function(units)
    if ScenarioInfo.tutorial then
        local function OnUnitKilled(unit)
            if ScenarioInfo.ControlGroupUnits then
                for i, v in ScenarioInfo.ControlGroupUnits do
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
        for k, v in units do
            TableInsert(entities, GetEntityById(v))
        end
        ScenarioInfo.ControlGroupUnits = TableMerged(ScenarioInfo.ControlGroupUnits, entities)

        -- remove units on death
        for k, v in entities do
            SimTriggers.CreateUnitDeathTrigger(OnUnitKilled, v)
            SimTriggers.CreateUnitReclaimedTrigger(OnUnitKilled, v) --same as killing for our purposes
        end
    end
end

local SimCamera = import("/lua/simcamera.lua")

Callbacks.OnCameraFinish = SimCamera.OnCameraFinish

local SimPlayerQuery = import("/lua/simplayerquery.lua")

Callbacks.OnPlayerQuery = SimPlayerQuery.OnPlayerQuery

Callbacks.OnPlayerQueryResult = SimPlayerQuery.OnPlayerQueryResult

Callbacks.PingGroupClick = import("/lua/simpinggroup.lua").OnClickCallback

Callbacks.GiveOrders = import("/lua/spreadattack.lua").GiveOrders

Callbacks.ValidateAssist = function(data, units)
    units = SecureUnits(units)
    local target = GetEntityById(data.target)
    if units and target then
        for k, u in units do
            if IsEntity(u) and u.Army == target.Army and IsInvalidAssist(u, target) then
                IssueClearCommands({ target })
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
    -- exclude structures as it makes no sense to apply a move command to them
    local allNonStructures = EntityCategoryFilterDown(categories.ALLUNITS - categories.STRUCTURE, units)

    if data.Clear then
        IssueClearCommands(allNonStructures)
    end
    IssueAggressiveMove(allNonStructures, data.Target)
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

Callbacks.WeaponPriorities = import("/lua/weaponpriorities.lua").SetWeaponPriorities

do
    -- upvalue for performance
    local EntityCategoryFilterDown = EntityCategoryFilterDown
    local IssueClearCommands = IssueClearCommands
    local IssueUpgrade = IssueUpgrade

    local cxrb0104 = categories.xrb0104
    local cxrb0204 = categories.xrb0204

    --- Forces hives in the selection to upgrade immediately
    ---@param data {UpgradeTo: string} what we want to upgrade to, should be 'xrb0204' or 'xrb0304'
    ---@param units Unit[] selected units
    Callbacks.ImmediateHiveUpgrade = function(data, units)

        -- make sure we have valid units
        units = SecureUnits(units)

        -- find t1 / t2 hives
        local xrb0104 = EntityCategoryFilterDown(cxrb0104, units)
        local xrb0204 = EntityCategoryFilterDown(cxrb0204, units)

        -- upgrade tech 1 hives
        if xrb0104[1] then

            -- oof for performance, but this doesn't get run that often
            local notUpgradingh = 1
            local notUpgrading = {}

            local upgradingh = 1
            local upgrading = {}

            -- split between upgrading / and not upgrading hives for different behavior
            for k, unit in xrb0104 do
                if not unit:IsUnitState('Upgrading') then
                    notUpgrading[notUpgradingh] = unit
                    notUpgradingh = notUpgradingh + 1
                else
                    upgrading[upgradingh] = unit
                    upgradingh = upgradingh + 1
                end
            end

            -- always clear things out
            IssueClearCommands(notUpgrading)

            -- upgrading to t2 from t1
            if data.UpgradeTo == "xrb0204" then
                IssueUpgrade(notUpgrading, "xrb0204")

                -- upgrading to t3 from t1
            elseif data.UpgradeTo == "xrb0304" then
                IssueUpgrade(notUpgrading, "xrb0204")
                IssueUpgrade(xrb0104, "xrb0304")
            end
        end

        -- upgrade tech 2 hives
        if xrb0204[1] then

            -- always clear things out
            if data.ClearCommands then
                IssueClearCommands(xrb0204)
            end

            -- upgrading to t3 form t1
            if data.UpgradeTo == "xrb0304" then
                IssueUpgrade(xrb0204, "xrb0304")
            end
        end
    end
end

do

    local toSimCommand = {
        false, --  1 "Stop
        IssueMove, --  2 "Move
        false, --  3 "Dive
        IssueMove, --  4 "FormMove
        false, --  5 "BuildSiloTactical
        false, --  6 "BuildSiloNuke"
        false, --  7 "BuildFactory"
        IssueBuildMobile, --  8 "BuildMobile"
        IssueGuard, --  9 "BuildAssist"
        IssueAttack, --  10 "Attack
        IssueAttack, --  11 "FormAttack
        IssueNuke, --  12 "Nuke
        IssueTactical, --  13 "Tactical
        IssueTeleport, --  14 "Teleport
        IssueGuard, --  15 "Guard
        false, --  16 "Patrol
        false, --  17 "Ferry
        false, --  18 "FormPatrol
        IssueReclaim, --  19 "Reclaim
        IssueRepair, --  20 "Repair
        IssueCapture, --  21 "Capture
        false, --  22 "TransportLoadUnits
        false, --  23 "TransportReverseLoadUnits
        IssueTransportUnload, --  24 "TransportUnloadUnits
        false, --  25 "TransportUnloadSpecificUnits
        false, --  26 "DetachFromTransport
        false, --  27 "Upgrade
        false, --  28 "Script
        false, --  29 "AssistCommander
        false, --  30 "KillSelf
        false, --  31 "DestroySelf
        false, --  32 "Sacrifice
        false, --  33 "Pause
        false, --  34 "OverCharge
        IssueAggressiveMove, --  35 "AggressiveMove
        IssueAggressiveMove, --  36 "FormAggressiveMove
        false, --  37 "AssistMove
        false, --  38 "SpecialAction
        false, --  39 "Dock
    }

    local requiresEntity = {
        false, --  1 "Stop
        false, --  2 "Move
        false, --  3 "Dive
        false, --  4 "FormMove
        false, --  5 "BuildSiloTactical
        false, --  6 "BuildSiloNuke"
        false, --  7 "BuildFactory"
        false, --  8 "BuildMobile"
        false, --  9 "BuildAssist"
        false, --  10 "Attack
        false, --  11 "FormAttack
        false, --  12 "Nuke
        false, --  13 "Tactical
        false, --  14 "Teleport
        true, --  15 "Guard
        false, --  16 "Patrol
        false, --  17 "Ferry
        false, --  18 "FormPatrol
        true, --  19 "Reclaim
        true, --  20 "Repair
        true, --  21 "Capture
        false, --  22 "TransportLoadUnits
        false, --  23 "TransportReverseLoadUnits
        false, --  24 "TransportUnloadUnits
        false, --  25 "TransportUnloadSpecificUnits
        false, --  26 "DetachFromTransport
        false, --  27 "Upgrade
        false, --  28 "Script
        false, --  29 "AssistCommander
        false, --  30 "KillSelf
        false, --  31 "DestroySelf
        false, --  32 "Sacrifice
        false, --  33 "Pause
        false, --  34 "OverCharge
        false, --  35 "AggressiveMove
        false, --  36 "FormAggressiveMove
        false, --  37 "AssistMove
        false, --  38 "SpecialAction
        false, --  39 "Dock
    }

    ---@param data any
    ---@param units Unit[]
    Callbacks.DistributeOrders = function(data, units)
        LOG("DistributeOrders")
        local units = SecureUnits(units)
        if not (units and units[1]) then
            return
        end

        -- bundle the orders
        local groups = {}
        local orders = units[1]:GetCommandQueue()
        for k, order in orders do
            -- find the last group
            local group = groups[table.getn(groups)]
            if not group then
                group = {}
                table.insert(groups, group)
            end

            -- edge case: group has no orders, so we add this order and call it a day
            if not group[1] then
                table.insert(group, order)
                -- usual case: check if the current group is of the same type of order, if so add to the group otherwise create a new group
            else
                if group[1].commandType == order.commandType then
                    table.insert(group, order)
                else
                    table.insert(groups, { order })
                end
            end
        end

        -- clear existing orders
        IssueClearCommands(units)

        -- assign orders in an interleaved fashion
        for offset, unit in units do
            for k, group in groups do
                local count = table.getn(group)
                local index = math.mod(offset, count) + 1
                local order = group[index]
                local callback = toSimCommand[order.commandType]
                if callback then
                    local candidate = GetEntityById(order.targetId)
                    if candidate then
                        local target

                        -- props are always valid
                        if IsProp(candidate) then
                            target = candidate
                        else
                            -- units are only valid in certain cases
                            if IsUnit(candidate) then
                                -- our own and allied units are always valid
                                if candidate.Army == unit.Army or IsAllied(candidate.Army, unit.Army) then
                                    target = candidate

                                -- enemy units are only valid if we've ever seen them
                                elseif candidate:GetBlip(unit.Army):IsSeenEver() then
                                    target = candidate
                                end
                            end
                        end

                        -- at this point we need a valid target
                        if target then
                            callback({ unit }, target)
                        end
                    else
                        -- at this point we may need an entity, so we check and bail if we do need one
                        if not requiresEntity[order.commandType] then
                            callback({ unit }, { order.x, order.y, order.z })
                        end
                    end
                end
            end
        end
    end

end

-------------------------------------------------------------------------------
--@region Development / debug related functionality

--- An anti cheat check that passes when there is only 1 player or cheats are enabled
---@return boolean
local PassesAntiCheatCheck = function()
    -- perform UI checks on sim to prevent cheating
    local count = 0
    for k, brain in ArmyBrains do
        if brain.BrainType == "Human" then
            count = count + 1
        end
    end

    -- allow when there is 1 or less players
    if count <= 1 then
        return true
    end

    -- allow when cheats are enabled
    return CheatsEnabled()
end

--- A simplified check that also passes when the game has AIs
---@return boolean
local PassesAIAntiCheatCheck = function()
    -- allow when there are AIs
    if ScenarioInfo.GameHasAIs then
        return true
    end

    -- allow when cheats are enabled
    return PassesAntiCheatCheck()
end



local SpawnedMeshes = {}

local function SpawnUnitMesh(id, x, y, z, pitch, yaw, roll)
    local bp = __blueprints[id]
    local bpD = bp.Display
    if __blueprints[bpD.MeshBlueprint] then
        SPEW("Spawning mesh of " .. id)
        local entity = import('/lua/sim/Entity.lua').Entity()
        if bp.CollisionOffsetY and bp.CollisionOffsetY < 0 then
            y = y - bp.CollisionOffsetY
        end
        entity:SetPosition(Vector(x, y, z), true)
        entity:SetMesh(bpD.MeshBlueprint)
        entity:SetDrawScale(bpD.UniformScale)
        entity:SetVizToAllies 'Intel'
        entity:SetVizToNeutrals 'Intel'
        entity:SetVizToEnemies 'Intel'
        table.insert(SpawnedMeshes, entity)
        return entity
    else
        SPEW("Can\' spawn mesh of " .. id .. " no mesh found")
    end
end

local function SetWorldCameraToUnitIconAngle(location, zoom)
    local sx = 1 / 6
    local th = 1 + (location[2] - GetSurfaceHeight(location[1], location[3]))
    -- Note: The maths for setting zoom is kinda all over the place, and is just 'good enough' for what I used it for.
    --_ALERT(location[2], GetSurfaceHeight(location[1], location[3]), th)
    --_ALERT(zoom, th)
    Sync.CameraRequests = Sync.CameraRequests or {}
    table.insert(Sync.CameraRequests, {
        Name = 'WorldCamera',
        Type = 'CAMERA_UNIT_SPIN',
        Marker = {
            orientation = VECTOR3(math.pi * (1 + sx), math.pi * sx, 0),
            position = location,
            zoom = FLOAT(zoom * th),
        },
        HeadingRate = 0,
        Callback = {
            Func = 'OnCameraFinish',
            Args = 'WorldCamera',
        }
    })
end

Callbacks.ClearSpawnedMeshes = function()
    if not PassesAntiCheatCheck() then
        return
    end

    for i, v in SpawnedMeshes do
        v:Destroy()
    end
    SpawnedMeshes = {}
end

Callbacks.CheatBoxSpawnProp = function(data)
    if not PassesAntiCheatCheck() then
        return
    end

    local offsetX = data.bpId.SizeX or 1
    local offsetZ = data.bpId.SizeZ or 1

    local squareX = math.ceil(math.sqrt(data.count or 1))
    local squareZ = math.ceil((data.count or 1) / squareX)

    local startOffsetX = (squareX - 1) * 0.5 * offsetX
    local startOffsetZ = (squareZ - 1) * 0.5 * offsetZ

    for i = 1, (data.count or 1) do
        local x = data.pos[1] - startOffsetX + math.mod(i, squareX) * offsetX
        local z = data.pos[3] - startOffsetZ + math.mod(math.floor(i / squareX), squareZ) * offsetZ
        if data.rand and data.rand ~= 0 then
            x = (x - data.rand * 0.5) + data.rand * Random()
            z = (z - data.rand * 0.5) + data.rand * Random()
            if math.mod(data.yaw or 0, 360) == 0 then
                data.yaw = 360 * Random()
            end
        end
        CreatePropHPR(data.bpId, x, GetTerrainHeight(x, z), z, data.yaw or 0, 0, 0) --blueprint, x, y, z, heading, pitch, roll
    end
end

Callbacks.CheatSpawnUnit = function(data)
    if not PassesAntiCheatCheck() then
        return
    end

    local pos = data.pos
    if data.MeshOnly then
        SpawnUnitMesh(data.bpId, pos[1], pos[2], pos[3], 0, data.yaw, 0)
    else
        local unit = CreateUnitHPR(data.bpId, data.army, pos[1], pos[2], pos[3], 0, data.yaw, 0)
        local unitbp = __blueprints[data.bpId]
        if data.CreateTarmac and unit.CreateTarmac and unitbp.Display and unitbp.Display.Tarmacs then
            unit:CreateTarmac(true, true, true, false, false)
        end
        if data.UnitIconCameraMode then
            local size = math.max(
                (unitbp.SizeX or 1),
                (unitbp.SizeY or 1) * 3,
                (unitbp.SizeZ or 1),
                (unitbp.Physics.SkirtSizeX or 1),
                (unitbp.Physics.SkirtSizeZ or 1)
            ) + math.abs(unitbp.CollisionOffsetY or 0)
            local dist = size / math.tan(60 --[[* (9/16)]] * 0.5 * ((math.pi * 2) / 360))
            SetWorldCameraToUnitIconAngle(pos, dist)
        end
        if data.veterancy and data.veterancy ~= 0 and unit.SetVeterancy then
            unit:SetVeterancy(data.veterancy)
        end
    end
end

--- Toggles the profiler on / off
Callbacks.ToggleProfiler = function(data)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/profiler.lua").ToggleProfiler(data.Army, data.ForceEnable or false)
end

-- Allows searching for benchmarks
Callbacks.FindBenchmarks = function(data)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/profiler.lua").FindBenchmarks(data.Army)
end

-- Allows a benchmark to be run in the sim
Callbacks.RunBenchmarks = function(data)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/profiler.lua").RunBenchmarks(data.Info)
end

Callbacks.ToggleDebugMarkersByType = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/markerutilities.lua").ToggleDebugMarkersByType(data.Type)
end

Callbacks.MapResoureCheck = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/maputilities.lua").MapResourceCheck()
end

Callbacks.iMapSwitchPerspective = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/maputilities.lua").iMapSwitchPerspective(data.Army)
end

Callbacks.iMapToggleRendering = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/maputilities.lua").iMapToggleRendering()
end

Callbacks.iMapToggleThreat = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/maputilities.lua").iMapToggleThreat(data.Identifier)
end

Callbacks.NavEnableDebugging = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug.lua").EnableDebugging()
end

Callbacks.NavDisableDebugging = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug.lua").DisableDebugging()
end

Callbacks.NavToggleScanLayer = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug.lua").ToggleScanLayer(data)
end

Callbacks.NavToggleScanLabels = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug.lua").ToggleScanLabels(data)
end

Callbacks.NavDebugStatisticsToUI = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug.lua").StatisticsToUI()
end

Callbacks.NavDebugCanPathTo = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug.lua").CanPathTo(data)
end

Callbacks.NavDebugPathTo = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug.lua").PathTo(data)
end

Callbacks.NavDebugPathToWithThreatThreshold = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug.lua").PathToWithThreatThreshold(data)
end

Callbacks.NavDebugGetLabel = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug.lua").GetLabel(data)
end

Callbacks.NavDebugEnableDirectionsFrom = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug/directionsfrom.lua").Enable()
end

Callbacks.NavDebugDisableDirectionsFrom = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug/directionsfrom.lua").Disable()
end

Callbacks.NavDebugUpdateDirectionsFrom = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug/directionsfrom.lua").Update(data)
end

Callbacks.NavDebugUpdateRandomDirectionFrom = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug/randomdirectionfrom.lua").Update(data)
end

Callbacks.NavDebugEnableRandomDirectionFrom = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug/randomdirectionfrom.lua").Enable()
end

Callbacks.NavDebugDisableRandomDirectionFrom = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug/randomdirectionfrom.lua").Disable()
end

Callbacks.NavDebugUpdateRetreatDirectionFrom = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug/retreatdirectionfrom.lua").Update(data)
end

Callbacks.NavDebugEnableRetreatDirectionFrom = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug/retreatdirectionfrom.lua").Enable()
end

Callbacks.NavDebugDisableRetreatDirectionFrom = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug/retreatdirectionfrom.lua").Disable()
end

Callbacks.NavDebugUpdateDirectionTo = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug/directionto.lua").Update(data)
end

Callbacks.NavDebugEnableDirectionTo = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug/directionto.lua").Enable()
end

Callbacks.NavDebugDisableDirectionTo = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug/directionto.lua").Disable()
end

Callbacks.NavDebugGetLabelMetadata = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug.lua").GetLabelMeta(data)
end

Callbacks.NavGenerate = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navgenerator.lua").Generate()
end


Callbacks.GridReclaimDebugEnable = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/ai/gridreclaim.lua").EnableDebugging()
end

Callbacks.GridReclaimDebugDisable = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/ai/gridreclaim.lua").DisableDebugging()
end

Callbacks.GridReconDebugEnable = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/ai/gridrecon.lua").EnableDebugging()
end

Callbacks.GridReconDebugDisable = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/ai/gridrecon.lua").DisableDebugging()
end

Callbacks.GridPresenceDebugEnable = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/ai/gridpresence.lua").EnableDebugging()
end

Callbacks.GridPresenceDebugDisable = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/ai/gridpresence.lua").DisableDebugging()
end


Callbacks.AIBrainEconomyDebugEnable = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/aibrains/components/economy.lua").EnableDebugging()
end

Callbacks.AIBrainEconomyDebugDisable = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/aibrains/components/economy.lua").DisableDebugging()
end


Callbacks.AIPlatoonSimpleRaidBehavior = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/aibrains/platoons/platoon-simple-raid.lua").DebugAssignToUnits(data, units)
end

Callbacks.AIPlatoonSimpleStructureBehavior = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/aibrains/platoons/platoon-simple-structure.lua").DebugAssignToUnits(data, units)
end

--#endregion
