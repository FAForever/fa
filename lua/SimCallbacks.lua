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

--- List of callbacks that is being populated throughout this file
---@type table<string, fun(data: table, units?: Unit[])>
local Callbacks = {}

---@param name string
---@param data table
---@param units? Unit[]
function DoCallback(name, data, units)
    local start = GetSystemTimeSecondsOnlyForProfileUse()
    local fn = Callbacks[name];
    if fn then
        fn(data, units)
    else
        SPEW('No callback named: ' .. repr(name))
    end

    local timeTaken = GetSystemTimeSecondsOnlyForProfileUse() - start
    if (timeTaken > 0.005) then
        SPEW(string.format("Time to process %s from %d: %f", name, timeTaken, GetCurrentCommandSource() or -2))
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

Callbacks.ValidateAssist = function(data, units)
    units = SecureUnits(units)
    local target = GetEntityById(data.target)
    if units and target then
        for k, u in units do
            if IsEntity(u) and u.Army == target.Army and IsInvalidAssist(u, target) then
                IssueToUnitClearCommands(target)
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

-------------------------------------------------------------------------------
--#region Advanced orders

Callbacks.WeaponPriorities = import("/lua/weaponpriorities.lua").SetWeaponPriorities

---@param data { target: EntityId }
---@param selection Unit[]
Callbacks.RingWithStorages = function(data, selection)
    -- verify selection
    selection = SecureUnits(selection)
    if (not selection) or TableEmpty(selection) then
        return
    end

    -- verify we have engineers
    local engineers = EntityCategoryFilterDown(categories.ENGINEER, selection)
    if TableEmpty(engineers) then
        return
    end

    -- verify the extractor
    local extractor = GetUnitById(data.target) --[[@as Unit]]
    if (not extractor) or
        (not extractor.Army) or
        (not OkayToMessWithArmy(extractor.Army)) or
        (not EntityCategoryContains(categories.MASSEXTRACTION, extractor))
    then
        return
    end

    import("/lua/sim/commands/ringing/ring-with-storages.lua").RingExtractor(extractor, engineers)
end

---@param data { target: EntityId, allFabricators: boolean }
---@param selection Unit[]
Callbacks.RingWithFabricators = function(data, selection)
    -- verify selection
    selection = SecureUnits(selection)
    if (not selection) or TableEmpty(selection) then
        return
    end

    -- verify we have engineers
    local engineers = EntityCategoryFilterDown(categories.ENGINEER, selection)
    if TableEmpty(engineers) then
        return
    end

    -- verify the extractor
    local extractor = GetUnitById(data.target) --[[@as Unit]]
    if (not extractor) or
        (not extractor.Army) or
        (not OkayToMessWithArmy(extractor.Army)) or
        (not EntityCategoryContains(categories.MASSEXTRACTION, extractor))
    then
        return
    end

    import("/lua/sim/commands/ringing/ring-with-fabricators.lua").RingExtractor(extractor, engineers, data.allFabricators)
end

---@param data { target: EntityId }
---@param selection Unit[]
Callbacks.RingRadar = function(data, selection)
    -- verify selection
    selection = SecureUnits(selection)
    if (not selection) or TableEmpty(selection) then
        return
    end

    -- verify we have engineers
    local engineers = EntityCategoryFilterDown(categories.ENGINEER, selection)
    if TableEmpty(engineers) then
        return
    end

    -- verify the extractor
    local target = GetUnitById(data.target) --[[@as Unit]]
    if (not target) or
        (not target.Army) or
        (not OkayToMessWithArmy(target.Army)) or
        (not EntityCategoryContains((categories.RADAR + categories.OMNI) * categories.STRUCTURE, target))
    then
        return
    end

    import("/lua/sim/commands/ringing/ring-with-power-tech1.lua").RingWithPower(target, engineers)
end

---@param data { target: EntityId }
---@param selection Unit[]
Callbacks.RingArtilleryTech2 = function(data, selection)
    -- verify selection
    selection = SecureUnits(selection)
    if (not selection) or TableEmpty(selection) then
        return
    end

    -- verify we have engineers
    local engineers = EntityCategoryFilterDown(categories.ENGINEER, selection)
    if TableEmpty(engineers) then
        return
    end

    -- verify the extractor
    local target = GetUnitById(data.target) --[[@as Unit]]
    if (not target) or
        (not target.Army) or
        (not OkayToMessWithArmy(target.Army)) or
        (not EntityCategoryContains(categories.ARTILLERY * categories.TECH2 * categories.STRUCTURE, target))
    then
        return
    end

    import("/lua/sim/commands/ringing/ring-with-power-tech1.lua").RingWithPower(target, engineers)
end

---@param data { target: EntityId }
---@param selection Unit[]
Callbacks.RingArtilleryTech3Exp = function(data, selection)
    -- verify selection
    selection = SecureUnits(selection)
    if (not selection) or TableEmpty(selection) then
        return
    end

    -- verify we have engineers
    local engineers = EntityCategoryFilterDown(categories.ENGINEER, selection)
    if TableEmpty(engineers) then
        return
    end

    -- verify the extractor
    local target = GetUnitById(data.target) --[[@as Unit]]
    if (not target) or
        (not target.Army) or
        (not OkayToMessWithArmy(target.Army)) or
        (not EntityCategoryContains(categories.ARTILLERY * (categories.TECH3 + categories.EXPERIMENTAL) * categories.STRUCTURE, target))
    then
        return
    end

    import("/lua/sim/commands/ringing/ring-with-power-tech3.lua").RingWithPower(target, engineers)
end

---@param data any
---@param selection Unit[]
Callbacks.SelectHighestEngineerAndAssist = function(data, selection)
    if selection then
        -- check for cheats
        local target = GetUnitById(data.TargetId) --[[@as Unit]]
        if not target or not target.Army then return end
        if not OkayToMessWithArmy(target.Army) then return end

        local noACU = EntityCategoryFilterDown(categories.ALLUNITS - categories.COMMAND, selection)
        IssueClearCommands(noACU)
        IssueGuard(noACU, target)
    end
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

    --- Processes the orders and re-distributes them over the units
    ---@param data { Target: EntityId, ClearCommands: boolean }
    ---@param selection Unit[]
    Callbacks.DistributeOrders = function(data, selection)
        -- verify selection
        selection = SecureUnits(selection)
        if (not selection) or TableEmpty(selection) then
            return
        end

        -- verify the target
        local target = (data.Target and GetUnitById(data.Target)) --[[@as Unit]]
        if (not target) or
            (not target.Army) or
            (not OkayToMessWithArmy(target.Army))
        then
            return
        end

        import("/lua/sim/commands/distribute-queue.lua").DistributeOrders(selection, target, data.ClearCommands or false, true)
    end
end

do 
    --- Processes the orders and re-distributes them over the units
    ---@param data { Target: EntityId, ClearCommands: boolean }
    ---@param selection Unit[]
    Callbacks.CopyOrders = function(data, selection)
        -- verify selection
        selection = SecureUnits(selection)
        if (not selection) or TableEmpty(selection) then
            return
        end

        -- verify the target
        local target = GetUnitById(data.Target) --[[@as Unit]]
        if (not target) or
            (not target.Army) or
            (not OkayToMessWithArmy(target.Army))
        then
            return
        end

        import("/lua/sim/commands/copy-queue.lua").CopyOrders(selection, target, data.ClearCommands or false, true)
    end
end

do

    ---@param data { ClearCommands: boolean }
    ---@param selection Unit[]
    Callbacks.LoadIntoTransports = function(data, selection)
       -- verify selection
       selection = SecureUnits(selection)
       if (not selection) or TableEmpty(selection) then
           return
       end

       local transports = EntityCategoryFilterDown(categories.TRANSPORTATION, selection)
       local transportees = EntityCategoryFilterDown(categories.ALLUNITS - (categories.AIR + categories.TRANSPORTATION), selection)
       local transportedUnits, transportsUsed, remUnits, remTransports = import("/lua/sim/commands/load-in-transport.lua").LoadIntoTransports(transportees, transports, data.ClearCommands or false, true)
    end
end

--#endregion

-------------------------------------------------------------------------------
--#region Chat and event message functionality

---@param message UIMessage
Callbacks.DistributeChatMessage = function(message)
    -- basic validation
    if  (not message.From) or
        (GetCurrentCommandSource() != message.From) or
        (not OkayToMessWithArmy(message.From))
    then
        WARN(string.format("Malformed chat message: (command source: %d) %s", GetCurrentCommandSource(), reprs(message)))
        CheatsEnabled()
        return
    end

    -- validate the message
    local ok, msg  = import("/lua/shared/chat.lua").ValidateMessage(message)
    if not ok then
        WARN(msg)
        CheatsEnabled()
        return
    end

    import('/lua/SimSyncUtils.lua').SyncUIChatMessage(message)
end

---@param data UIMessage
Callbacks.DistributeEventMessage = function(data)
    -- basic validation
    if  (not data.From) or
        (GetCurrentCommandSource() != data.From) or
        (not OkayToMessWithArmy(data.From))
    then
        WARN(string.format("Malformed event message: (command source: %d) %s", GetCurrentCommandSource(), reprs(data)))
        CheatsEnabled()
        return
    end

    -- validate the message
    local ok, msg  = import("/lua/shared/chat.lua").ValidateMessage(message)
    if not ok then
        WARN(msg)
        CheatsEnabled()
        return
    end

    import('/lua/SimSyncUtils.lua').SyncUIEventMessage(data)
end

--@endregion

-------------------------------------------------------------------------------
--#region Development / debug related functionality

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

local function ShowRaisedPlatforms(self)
    local plats = self:GetBlueprint().Physics.RaisedPlatforms
    if not plats then return end
    local pos = self:GetPosition()
    local entities = {}
    for i=1, (table.getn(plats)/12) do
        entities[i]={}
        for b=1,4 do
            entities[i][b] = import('/lua/sim/Entity.lua').Entity{Owner = self}
            self.Trash:Add(entities[i][b])
            entities[i][b]:SetPosition(Vector(
                pos[1]+plats[((i-1)*12)+(b*3)-2],
                pos[2]+plats[((i-1)*12)+(b*3)],
                pos[3]+plats[((i-1)*12)+(b*3)-1]
            ), true)
        end
        self.Trash:Add(AttachBeamEntityToEntity(entities[i][1], -2, entities[i][2], -2, self:GetArmy(), '/effects/emitters/build_beam_01_emit.bp'))
        self.Trash:Add(AttachBeamEntityToEntity(entities[i][1], -2, entities[i][3], -2, self:GetArmy(), '/effects/emitters/build_beam_01_emit.bp'))
        self.Trash:Add(AttachBeamEntityToEntity(entities[i][4], -2, entities[i][2], -2, self:GetArmy(), '/effects/emitters/build_beam_01_emit.bp'))
        self.Trash:Add(AttachBeamEntityToEntity(entities[i][4], -2, entities[i][3], -2, self:GetArmy(), '/effects/emitters/build_beam_01_emit.bp'))
    end
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
        -- allow creating multiple units to make it easier to test specific scenarios
        for i = 1, (data.count or 1) do
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
            if data.ShowRaisedPlatforms then
                ShowRaisedPlatforms(unit)
            end
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

Callbacks.NavDebugUpdateGetPositionsInRadius = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug/getpositionsinradius.lua").Update(data)
end

Callbacks.NavDebugEnableGetPositionsInRadius = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug/getpositionsinradius.lua").Enable()
end

Callbacks.NavDebugDisableGetPositionsInRadius = function(data, units)
    if not PassesAIAntiCheatCheck() then
        return
    end

    import("/lua/sim/navdebug/getpositionsinradius.lua").Disable()
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
