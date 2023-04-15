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
local Warnings = { }

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
        units = {units}
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
    {  {-2, 2}, {2, 2}, {2, -2}, {-2, -2}, {-4, 0},{0, 4}, {4, 0}, {0, -4}, },
}

--- Templates for units with a skirtSize of 3 such as fabricators
local skirtSize6 = { 
    -- inner layer for storages
    { {-2, 4}, {0, 4}, {2, 4}, {4, 2}, {4, 0}, {4, -2}, {2, -4}, {0, -4}, {-2, -4}, {-4, -2}, {-4, 0}, {-4, 2}, },
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
    local otherBuilders = { }
    local buildersByFaction = { }

    -- determine of all units in selection what they can build
    for _, unit in units do
        -- make sure we're allowed to mess with this unit, if not we exclude
        if unit.Army and OkayToMessWithArmy(unit.Army) then 
            -- compute blueprint id
            local faction = unit.Blueprint.FactionCategory
            local blueprintID = ConstructBlueprintID(faction, data.id)

            -- check if this unit can build it
            if unit:CanBuild(blueprintID) then
                buildersByFaction[faction] = buildersByFaction[faction] or { }
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
    local builders = { }
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
                pz + sz + offset  -- bottom right
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
                    IssueBuildMobile({builder}, buildLocation, blueprintID, {})
                end
            end
        end

        -- assist for all other builders, spread over the number of actual builders
        local t = { }
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

local SpawnedMeshes = {}

local function SpawnUnitMesh(id, x, y, z, pitch, yaw, roll)
    local bp = __blueprints[id]
    local bpD = bp.Display
    if __blueprints[bpD.MeshBlueprint] then
        SPEW("Spawning mesh of "..id)
        local entity = import('/lua/sim/Entity.lua').Entity()
        if bp.CollisionOffsetY and bp.CollisionOffsetY < 0 then
            y = y-bp.CollisionOffsetY
        end
        entity:SetPosition(Vector(x,y,z), true)
        entity:SetMesh(bpD.MeshBlueprint)
        entity:SetDrawScale(bpD.UniformScale)
        entity:SetVizToAllies'Intel'
        entity:SetVizToNeutrals'Intel'
        entity:SetVizToEnemies'Intel'
        table.insert(SpawnedMeshes, entity)
        return entity
    else
        SPEW("Can\' spawn mesh of "..id.." no mesh found")
    end
end

local function SetWorldCameraToUnitIconAngle(location, zoom)
    local sx = 1/6
    local th = 1 + (location[2] - GetSurfaceHeight(location[1], location[3]))
    -- Note: The maths for setting zoom is kinda all over the place, and is just 'good enough' for what I used it for.
    --_ALERT(location[2], GetSurfaceHeight(location[1], location[3]), th)
    --_ALERT(zoom, th)
    Sync.CameraRequests = Sync.CameraRequests or { }
    table.insert( Sync.CameraRequests, {
        Name = 'WorldCamera',
        Type = 'CAMERA_UNIT_SPIN',
        Marker = {
            orientation = VECTOR3(math.pi*(1+sx), math.pi*sx, 0),
            position = location,
            zoom = FLOAT(zoom*th),
        },
        HeadingRate = 0,
        Callback = {
            Func = 'OnCameraFinish',
            Args = 'WorldCamera',
        }
    })
end

Callbacks.ClearSpawnedMeshes = function()
    if not CheatsEnabled() then return end

    for i, v in SpawnedMeshes do
        v:Destroy()
    end
    SpawnedMeshes = {}
end

Callbacks.CheatBoxSpawnProp = function(data)
    if not CheatsEnabled() then return end

    local offsetX = data.bpId.SizeX or 1
    local offsetZ = data.bpId.SizeZ or 1

    local squareX = math.ceil(math.sqrt(data.count or 1))
    local squareZ = math.ceil((data.count or 1)/squareX)

    local startOffsetX = (squareX-1) * 0.5 * offsetX
    local startOffsetZ = (squareZ-1) * 0.5 * offsetZ

    for i = 1, (data.count or 1) do
        local x = data.pos[1] - startOffsetX + math.mod(i,squareX) * offsetX
        local z = data.pos[3] - startOffsetZ + math.mod(math.floor(i/squareX), squareZ) * offsetZ
        if data.rand and data.rand ~= 0 then
            x = (x - data.rand*0.5) + data.rand*Random()
            z = (z - data.rand*0.5) + data.rand*Random()
            if math.mod(data.yaw or 0, 360) == 0 then
                data.yaw = 360*Random()
            end
        end
        CreatePropHPR(data.bpId, x, GetTerrainHeight(x,z), z, data.yaw or 0, 0, 0)--blueprint, x, y, z, heading, pitch, roll
    end
end

Callbacks.CheatSpawnUnit = function(data)
    if not CheatsEnabled() then return end

    local pos = data.pos
    if data.MeshOnly then
        SpawnUnitMesh(data.bpId, pos[1], pos[2], pos[3], 0, data.yaw, 0)
    else
        local unit = CreateUnitHPR(data.bpId, data.army, pos[1], pos[2], pos[3], 0, data.yaw, 0)
        local unitbp = __blueprints[data.bpId]
        if data.CreateTarmac and unit.CreateTarmac and unitbp.Display and unitbp.Display.Tarmacs then
            unit:CreateTarmac(true,true,true,false,false)
        end
        if data.UnitIconCameraMode then
            local size = math.max(
                (unitbp.SizeX or 1),
                (unitbp.SizeY or 1) * 3,
                (unitbp.SizeZ or 1),
                (unitbp.Physics.SkirtSizeX or 1),
                (unitbp.Physics.SkirtSizeZ or 1)
            ) + math.abs(unitbp.CollisionOffsetY or 0)
            local dist = size / math.tan(60 --[[* (9/16)]] * 0.5 * ((math.pi*2)/360))
            SetWorldCameraToUnitIconAngle(pos, dist)
        end
        if data.veterancy and data.veterancy ~= 0 and unit.SetVeterancy then
            unit:SetVeterancy(data.veterancy)
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

Callbacks.ToggleDebugChainByName = function (data, units)
    LOG("ToggleDebugChainByName")
end

Callbacks.ToggleDebugMarkersByType = function (data, units)
    import("/lua/sim/markerutilities.lua").ToggleDebugMarkersByType(data.Type)
end

--- Toggles the profiler on / off
Callbacks.ToggleProfiler = function (data)
    import("/lua/sim/profiler.lua").ToggleProfiler(data.Army, data.ForceEnable or false )
end

-- Allows searching for benchmarks
Callbacks.FindBenchmarks = function (data)
    import("/lua/sim/profiler.lua").FindBenchmarks(data.Army)
end

-- Allows a benchmark to be run in the sim
Callbacks.RunBenchmarks = function (data)
    import("/lua/sim/profiler.lua").RunBenchmarks(data.Info)
end

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
            local notUpgrading = { }
            
            local upgradingh = 1 
            local upgrading = { }

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
                IssueUpgrade( notUpgrading, "xrb0204")
            
            -- upgrading to t3 from t1
            elseif data.UpgradeTo == "xrb0304" then 
                IssueUpgrade( notUpgrading, "xrb0204")
                IssueUpgrade( xrb0104, "xrb0304")
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
                IssueUpgrade( xrb0204, "xrb0304")
            end
        end
    end
end

do
    --- Allows the player to force a target recheck on the selected units
    ---@param data table   an empty table
    ---@param units Unit[] table of units
    Callbacks.RecheckTargetsOfWeapons = function(data, units)

        -- make sure we have valid units with the correct command source
        units = SecureUnits(units)
        local tick = GetGameTick()
        local rechecks = 0 

        -- reset their weapons
        for k, unit in units do
            if
                -- unit should still exist
                not unit:BeenDestroyed() and
                (   -- do not allow players to spam this
                    not unit.RecheckTargetsOfWeaponsTick or
                    (tick - unit.RecheckTargetsOfWeaponsTick > 10)
                ) 
            then
                rechecks = rechecks + 1
                unit.RecheckTargetsOfWeaponsTick = tick
                for l = 1, unit.WeaponCount do
                    unit:GetWeapon(l):ResetTarget()
                end
            end
        end

        -- user feedback
        if rechecks > 0 then 
            if units[1].Army == GetFocusArmy() then
                if rechecks == 1 then 
                    print("1 weapon target recheck")
                else 
                    print(string.format("%d weapon target rechecks", rechecks))
                end
            end
        end
    end
end

Callbacks.MapResoureCheck = function(data)
    import("/lua/sim/maputilities.lua").MapResourceCheck()
end

Callbacks.iMapSwitchPerspective = function(data)
    import("/lua/sim/maputilities.lua").iMapSwitchPerspective(data.Army)
end

Callbacks.iMapToggleRendering = function(data)
    import("/lua/sim/maputilities.lua").iMapToggleRendering()
end

Callbacks.iMapToggleThreat = function(data)
    import("/lua/sim/maputilities.lua").iMapToggleThreat(data.Identifier)
end

Callbacks.SelectHighestEngineerAndAssist = function(data, selection)
    if selection then

        local noACU = EntityCategoryFilterDown(categories.ALLUNITS - categories.COMMAND, selection)

        ---@type Unit
        local target = GetEntityById(data.TargetId)

        IssueClearCommands(noACU)
        IssueGuard(noACU, target)
    end
end

---@class CargoSlots
---@field Large number 
---@field Medium number 
---@field Small number

---@type CargoSlots[]
local GetCargoSlotsCache = {}

---@param unit Unit
---@return CargoSlots
local function GetCargoSlots(unit)

    -- try the cache first
    if GetCargoSlotsCache[unit.UnitId] then 
        return GetCargoSlotsCache[unit.UnitId]
    end

    ---@type CargoSlots
    local slots = {
        Large = 0,
        Medium = 0,
        Small = 0,
    }

    -- based on attachment points
    for i = 1, unit:GetBoneCount() do
        if unit:GetBoneName(i) ~= nil then
            if string.find(unit:GetBoneName(i), 'Attachpoint_Lrg') then
                slots.Large = slots.Large + 1
            elseif string.find(unit:GetBoneName(i), 'Attachpoint_Med') then
                slots.Medium = slots.Medium + 1
            elseif string.find(unit:GetBoneName(i), 'Attachpoint') then
                slots.Small = slots.Small + 1
            end
        end
    end

    -- based on blueprint definitions
    slots.Large = math.min(slots.Large, unit.Blueprint.Transport.SlotsLarge or slots.Large)
    slots.Medium = math.min(slots.Medium, unit.Blueprint.Transport.SlotsMedium or slots.Medium)
    slots.Small = math.min(slots.Small, unit.Blueprint.Transport.SlotsSmall or slots.Small)

    -- cache it and return
    GetCargoSlotsCache[unit.UnitId] = slots
    return slots
end

Callbacks.NavToggleScanLayer = import("/lua/sim/navdebug.lua").ToggleScanLayer
Callbacks.NavToggleScanLabels = import("/lua/sim/navdebug.lua").ToggleScanLabels
Callbacks.NavDebugStatisticsToUI = import("/lua/sim/navdebug.lua").StatisticsToUI
Callbacks.NavDebugCanPathTo = import("/lua/sim/navdebug.lua").CanPathTo
Callbacks.NavDebugPathTo = import("/lua/sim/navdebug.lua").PathTo
Callbacks.NavDebugPathToWithThreatThreshold = import("/lua/sim/navdebug.lua").PathToWithThreatThreshold
Callbacks.NavDebugGetLabel = import("/lua/sim/navdebug.lua").GetLabel
Callbacks.NavDebugGetLabelMetadata = import("/lua/sim/navdebug.lua").GetLabelMeta
Callbacks.NavGenerate = import("/lua/sim/navgenerator.lua").Generate

Callbacks.GridReclaimDebugEnable = import("/lua/ai/gridreclaim.lua").EnableDebugging
Callbacks.GridReclaimDebugDisable = import("/lua/ai/gridreclaim.lua").DisableDebugging
