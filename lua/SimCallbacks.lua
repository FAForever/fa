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

-------------------------------------------------------------------------------
--#region Advanced orders

Callbacks.WeaponPriorities = import("/lua/weaponpriorities.lua").SetWeaponPriorities

---@param data any
---@param selection any
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

    ---@class DistributeOrderInfo
    ---@field BatchOrders boolean
    ---@field FullRedundancy boolean
    ---
    ---@field Type string                   # Describes the intended order, used during debugging
    ---@field Callback function | false     # Function that matches the intended order
    ---@field RequiresEntity boolean        # Flag that indicates this order requires an entity and should be skipped otherwise
    ---@field ApplyAllOrders boolean        # Flag that indicates we want to apply all orders
    ---@field Redundancy number             # Flag that indicates the default redundancy for each group of orders

    --- The order of this list is determined in the engine, see also the files in:
    --- - https://github.com/FAForever/FA-Binary-Patches/pull/22
    ---@type DistributeOrderInfo[]
    local CommandInfo = {
        [1] = {
            Type = "Stop",
            Callback = false,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [2] = {
            Type = "Move",
            Callback = IssueMove,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
            BatchOrders = true,
        },
        [3] = {
            Type = "Dive",
            Callback = false,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [4] = {
            Type = "FormMove",
            Callback = IssueMove,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [5] = {
            Type = "BuildSiloTactical",
            Callback = false,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [6] = {
            Type = "BuildSiloNuke",
            Callback = false,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [7] = {
            Type = "BuildFactory",
            Callback = false,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [8] = {
            Type = "BuildMobile",
            Callback = IssueBuildMobile,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = true,
        },
        [9] = {
            Type = "BuildAssist",
            Callback = IssueGuard,
            RequiresEntity = true,
            Redundancy = 1,
            ApplyAllOrders = true,
        },
        [10] = {
            Type = "Attack",
            Callback = IssueAttack,
            RequiresEntity = false,
            Redundancy = 3,
            ApplyAllOrders = true,
            BatchOrders = true,
            FullRedundancy = true,
        },
        [11] = {
            Type = "FormAttack",
            Callback = IssueAttack,
            RequiresEntity = false,
            Redundancy = 3,
            ApplyAllOrders = true,
        },
        [12] = {
            Type = "Nuke",
            Callback = IssueNuke,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = true,
        },
        [13] = {
            Type = "Tactical",
            Callback = IssueTactical,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = true,
        },
        [14] = {
            Type = "Teleport",
            Callback = IssueTeleport,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [15] = {
            Type = "Guard",
            Callback = IssueGuard,
            RequiresEntity = true,
            Redundancy = 1,
            ApplyAllOrders = false,
            BatchOrders = true,
            FullRedundancy = true,
        },
        [16] = {
            Type = "Patrol",
            Callback = IssuePatrol,
            RequiresEntity = false,
            Redundancy = 3,
            ApplyAllOrders = true,
        },
        [17] = {
            Type = "Ferry",
            Callback = nil,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [18] = {
            Type = "FormPatrol",
            Callback = IssuePatrol,
            RequiresEntity = false,
            Redundancy = 3,
            ApplyAllOrders = true,
        },
        [19] = {
            Type = "Reclaim",
            Callback = IssueReclaim,
            RequiresEntity = true,
            Redundancy = 1,
            ApplyAllOrders = true,
            BatchOrders = true,
            FullRedundancy = true,
        },
        [20] = {
            Type = "Repair",
            Callback = IssueRepair,
            RequiresEntity = true,
            Redundancy = 1,
            ApplyAllOrders = true,
            BatchOrders = true,
            FullRedundancy = true,
        },
        [21] = {
            Type = "Capture",
            Callback = IssueCapture,
            RequiresEntity = true,
            Redundancy = 1,
            ApplyAllOrders = true,
            BatchOrders = true,
            FullRedundancy = true,
        },
        [22] = {
            Type = "TransportLoadUnits",
            Callback = nil,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [23] = {
            Type = "TransportReverseLoadUnits",
            Callback = nil,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [24] = {
            Type = "TransportUnloadUnits",
            Callback = IssueTransportUnload,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [25] = {
            Type = "TransportUnloadSpecificUnits",
            Callback = nil,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [26] = {
            Type = "DetachFromTransport",
            Callback = nil,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [27] = {
            Type = "Upgrade",
            Callback = nil,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [28] = {
            Type = "Script",
            Callback = nil,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [29] = {
            Type = "AssistCommander",
            Callback = IssueGuard,
            RequiresEntity = true,
            Redundancy = 1,
            ApplyAllOrders = true,
        },
        [30] = {
            Type = "KillSelf",
            Callback = nil,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [31] = {
            Type = "DestroySelf",
            Callback = nil,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [32] = {
            Type = "Sacrifice",
            Callback = IssueSacrifice,
            RequiresEntity = true,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [33] = {
            Type = "Pause",
            Callback = nil,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [34] = {
            Type = "OverCharge",
            Callback = nil,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [35] = {
            Type = "AggressiveMove",
            Callback = IssueAggressiveMove,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = true,
        },
        [36] = {
            Type = "FormAggressiveMove",
            Callback = IssueAggressiveMove,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = true,
        },
        [37] = {
            Type = "AssistMove",
            Callback = nil,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = true,
        },
        [38] = {
            Type = "SpecialAction",
            Callback = nil,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
        [39] = {
            Type = "Dock",
            Callback = nil,
            RequiresEntity = false,
            Redundancy = 1,
            ApplyAllOrders = false,
        },
    }

    --- Constructs `l` batches of roughly even size such that when combined they sum up to `h`.
    --- As an example, the output is `{3, 3, 2, 2}` when `h = 10` and `l = 4`. The cache parameter
    --- allows us to re-use memory
    ---@param h number          # Higher number
    ---@param l number          # Lower number 
    ---@param cache number[]    # Table with as many elements as `l`, such as 
    ---@return number[]
    local function ComputeBatchCounts(h, l, cache)

        -- clear out the cache
        for k, _ in cache do
            cache[k] = nil
        end

        for k = 1, l do
            local count = math.ceil(h / l)
            cache[k] = count
            h = h - count
            l = l - 1
        end

        return cache
    end

    --- Populates a small batch of units. The cache parameter allows us to re-use memory
    ---@param start number  # Start index, element is included in the output
    ---@param count number  # Number of elements to include
    ---@param array Unit[]  # Array to take elements from
    ---@param cache Unit[]  # Cache to store the elements in
    ---@return Unit[]
    local function PopulateBatch(start, count, array, cache)
        -- clear out the cache
        for k, _ in cache do
            cache[k] = nil
        end

        local head = 1
        for k = start, start + count do
            cache[head] = array[k]
            head = head + 1
        end

        return cache
    end

    ---@param order any
    ---@param cache Vector
    ---@return Vector
    local function PopulateLocation(order, cache)
        cache[1] = order.x
        cache[2] = order.y
        cache[3] = order.z
        return cache
    end

    --- Processes the orders and re-distributes them over the units
    ---@param data any
    ---@param units Unit[]
    Callbacks.DistributeOrders = function(data, units)

        local start = GetSystemTimeSecondsOnlyForProfileUse()

        -- prevent cheating
        local units = SecureUnits(units)
        if not (units and units[1]) then
            return
        end

        -----------------------------------------------------------------------
        -- bundle the orders

        ---@type table<EntityId, boolean>
        local seen = {}

        ---@type number | nil
        local px = nil

        ---@type number | nil
        local pz = nil

        ---@type UnitCommand[][]
        local groups = { {} }

        ---@type UnitCommand[]
        local orders = units[1]:GetCommandQueue()
        for k, order in orders do

            -- find the first order that represents a position

            local ox = order.x
            local oz = order.z
            if (not px) and (ox > 0) and (oz > 0) then
                px = ox
                pz = oz
            end

            -- find the last group
            local group = groups[table.getn(groups)]

            -- try and remove duplicated orders
            local targetId = order.targetId
            if targetId then
                if seen[targetId] then
                    continue
                end
                seen[targetId] = true
            end

            -- edge case: group has no orders, so we add this order and
            -- call it a day
            if not group[1] then
                table.insert(group, order)
                -- usual case: check if the current group is of the same
                -- type of order, if so add to the group otherwise create
                -- a new group
            else
                if group[1].commandType == order.commandType then
                    table.insert(group, order)
                else
                    table.insert(groups, { order })

                    -- the 'seen' table is per group of orders
                    seen = {}
                    if targetId then
                        seen[targetId] = true
                    end
                end
            end
        end

        -----------------------------------------------------------------------
        -- sorting units

        -- we sort the selection to make the order more intuitive. By default
        -- the order is defined by the entityId, which is essentially random in
        -- the average case

        if px and pz then
            for _, unit in units do
                local ux, _, uz = unit:GetPositionXYZ()
                local dx = ux - px
                local dz = uz - pz
                unit.DistributeOrdersDistance = dx * dx + dz * dz
            end

            table.sort(
                units,
                function(a, b)
                    return a.DistributeOrdersDistance < b.DistributeOrdersDistance
                end
            )

            for _, unit in units do
                unit.DistributeOrdersDistance = nil
            end
        end

        -----------------------------------------------------------------------
        -- clear existing orders

        IssueClearCommands(units)

        -----------------------------------------------------------------------
        -- assign orders

        ---@type number[]
        local dummyBatches = {}

        ---@type Unit[]
        local dummyBatchTable = {}

        ---@type table
        local dummyEmptyTable = {}

        ---@type { [1]: Unit }
        local dummyUnitTable = {}

        ---@type { [1]: number, [2]: number, [3]: number }
        local dummyVectorTable = {}

        local offset = 0
        local unitCount = table.getn(units)
        for k, group in groups do
            local orderCount = table.getn(group)

            -- extract info on how to apply these orders
            local commandInfo = CommandInfo[group[1].commandType]
            local commandType = commandInfo.Type
            local issueOrder = commandInfo.Callback
            local redundantOrders = commandInfo.Redundancy
            local applyAllOrders = commandInfo.ApplyAllOrders
            local batchOrders = commandInfo.BatchOrders
            local fullRedundancy = commandInfo.FullRedundancy

            -- increase redundancy to guarantee all orders are applied at least once
            if applyAllOrders and (unitCount * redundantOrders < orderCount) then
                redundantOrders = math.ceil(orderCount / (unitCount * redundantOrders))
            end

            if issueOrder then

                -- special snowflake implementation for the mobile build order. There's
                -- many ways to break the game when distributing this order therefore
                -- we limit the functionality to make it as least game breaking as possible

                -- assuming that the user didn't do something odd, the order of the order
                -- table and the unit table match up: the 1st unit is close to the 1st
                -- order, the 2nd unit is close to the 2nd order, etc

                if commandType == 'BuildMobile' then
                    if orderCount == unitCount then

                        -- this case is simple: assing each unit an order

                        for k, _ in units do
                            local unit = units[k]
                            local order = group[k]
                            dummyUnitTable[1] = unit
                            dummyVectorTable[1] = order.x
                            dummyVectorTable[2] = order.y
                            dummyVectorTable[3] = order.z
                            issueOrder(dummyUnitTable, dummyVectorTable, order.blueprintId, dummyEmptyTable)
                        end
                    elseif orderCount > unitCount then

                        -- this is the usual case, we look over the units and assign each unit
                        -- to multiple orders

                        local start = 1
                        local batches = ComputeBatchCounts(orderCount, unitCount, dummyBatches)
                        for k, batch in batches do
                            dummyUnitTable[1] = units[k]
                            local orderBatch = PopulateBatch(start, batch - 1, group, dummyBatchTable)
                            start = start + batch
                            for _, order in orderBatch do
                                dummyVectorTable[1] = order.x
                                dummyVectorTable[2] = order.y
                                dummyVectorTable[3] = order.z
                                issueOrder(dummyUnitTable, dummyVectorTable, order.blueprintId, dummyEmptyTable)
                            end
                        end
                    else

                        -- this is an odd case, we look over the orders and assign multiple
                        -- units the same order

                        local start = 1
                        local batches = ComputeBatchCounts(unitCount, orderCount, dummyBatches)
                        for k, batch in batches do
                            local order = group[k]
                            dummyVectorTable[1] = order.x
                            dummyVectorTable[2] = order.y
                            dummyVectorTable[3] = order.z

                            local unitBatch = PopulateBatch(start, batch - 1, units, dummyBatchTable)
                            start = start + batch
                            for _, unit in unitBatch do
                                dummyUnitTable[1] = unit
                                issueOrder(dummyUnitTable, dummyVectorTable, order.blueprintId, dummyEmptyTable)
                            end
                        end
                    end
                elseif batchOrders then
                    LOG("Batching orders")

                    local ordersApplied = 0
                    if fullRedundancy then

                        -- in this case we want to introduce as much redundancy as possible

                        LOG(" - Full redundancy")

                        -- prepare orders
                        for _, order in group do
                            order.Entity = order.target
                            order.Location = { order.x, order.y, order.z }
                        end

                        local unitsPerBatch = math.ceil(unitCount / orderCount)
                        local redundancy = orderCount
                        LOG(string.format(" - Units per batch: %d", unitsPerBatch))
                        LOG(string.format(" - Redundancy: %d", redundancy))

                        -- issue orders
                        for b = 1, redundancy do
                            for o, _ in group do
                                -- give an offset to each order
                                local order = group[math.mod(o + b, orderCount) + 1]

                                -- compute the batch of units
                                local batch = {}
                                for k = 1, unitsPerBatch do
                                    local unit = units[k + (b - 1) * unitsPerBatch]
                                    if unit then
                                        table.insert(batch, unit)
                                    end
                                end

                                -- LOG(string.format("Apply order at: (%s)", repru(order.Location)))
                                -- for k, unit in batch do
                                --     LOG(unit.EntityId)
                                -- end

                                ordersApplied = ordersApplied + 1

                                if order.Entity then
                                    issueOrder(batch, order.Entity)
                                elseif commandInfo.Type == 'BuildMobile' then
                                    issueOrder(batch, order.Location, order.blueprintId, {})
                                elseif not commandInfo.RequiresEntity then
                                    issueOrder(batch, order.Location)
                                end
                            end
                        end
                    else
                        LOG(" - No redundancy")

                        if orderCount >= unitCount then

                            -- strange situation where we have more orders than units

                            local start = 1
                            local batches = ComputeBatchCounts(orderCount, unitCount, dummyBatches)
                            for k, batch in batches do
                                dummyUnitTable[1] = units[k]
                                local orderBatch = PopulateBatch(start, batch - 1, group, dummyBatchTable)
                                start = start + batch
                                for _, order in orderBatch do
                                    issueOrder(dummyUnitTable, order.target or PopulateLocation(order, dummyVectorTable))
                                    ordersApplied = ordersApplied + 1
                                end
                            end
                        else

                            -- usual situation where we have equal or more orders than units

                            local start = 1
                            local batches = ComputeBatchCounts(unitCount, orderCount, dummyBatches)
                            for k, batch in batches do
                                local order = group[k]
                                local unitBatch = PopulateBatch(start, batch - 1, units, dummyBatchTable)
                                start = start + batch
                                issueOrder(unitBatch, order.target or PopulateLocation(order, dummyVectorTable))
                                ordersApplied = ordersApplied + 1
                            end
                        end
                    end

                    LOG(string.format(" - Orders applied: %d", ordersApplied))
                else
                    -- apply individual orders
                    for _, unit in units do
                        -- apply orders
                        for redundancy = 1, math.min(orderCount, redundantOrders) do
                            local order = group[math.mod(offset, orderCount) + 1]
                            local candidate = order.target
                            if candidate then
                                issueOrder({ unit }, candidate)
                                offset = offset + 1
                            else
                                -- at this point we may need an entity, so we check and bail if we do need one
                                if not commandInfo.RequiresEntity then
                                    issueOrder({ unit }, { order.x, order.y, order.z })
                                    offset = offset + 1
                                end
                            end
                        end
                    end
                end
            end
        end

        LOG(string.format("Processing time: %f", GetSystemTimeSecondsOnlyForProfileUse() - start))
    end

    
end

--#endregion

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
