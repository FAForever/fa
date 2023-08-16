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
---@param units Unit[]
DistributeOrders = function(units)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

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

                    local start = 1
                    local batches = ComputeBatchCounts(unitCount, orderCount, dummyBatches)

                    for k, batch in batches do
                        local direction = 1
                        if math.mod(k, 2) == 0 then
                            direction = -1
                        end

                        for o = 1, orderCount do
                            local index = math.mod((direction * (o - 1) + k) + orderCount, orderCount) + 1
                            local order = group[index]
                            local unitBatch = PopulateBatch(start, batch - 1, units, dummyBatchTable)
                            local targetOrEntity = order.target or PopulateLocation(order, dummyVectorTable)
                            issueOrder(unitBatch, targetOrEntity)
                            ordersApplied = ordersApplied + 1
                        end

                        start = start + batch
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
