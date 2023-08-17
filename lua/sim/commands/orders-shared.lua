--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

---@class DistributeOrderInfo
---@field Callback? fun(units: Unit[], target: Vector | Entity, arg3?: any, arg4?: any)
---@field Type string                   # Describes the intended order, useful for debugging
---@field BatchOrders boolean           # When set, assigns orders to groups of units
---@field FullRedundancy boolean        # When set, attempts to add full redundancy when reasonable by assigning multiple orders to each group
---@field Redundancy number             # When set, assigns orders to individual units. Number of orders assigned is equal to the redundancy factor

--- The order of this list is determined in the engine, see also the files in:
--- - https://github.com/FAForever/FA-Binary-Patches/pull/22
---@type DistributeOrderInfo[]
UnitQueueDataToCommand = {
    [1] = { Type = "Stop", },
    [2] = {
        Type = "Move",
        Callback = IssueMove,
        BatchOrders = true,
    },
    [3] = { Type = "Dive", },
    [4] = {
        Type = "FormMove",
        Callback = IssueMove,
        BatchOrders = true,
    },
    [5] = { Type = "BuildSiloTactical", },
    [6] = { Type = "BuildSiloNuke", },
    [7] = { Type = "BuildFactory", },
    [8] = {
        Type = "BuildMobile",
        Callback = IssueBuildMobile,
        Redundancy = 1,
    },
    [9] = {
        Type = "BuildAssist",
        Callback = IssueGuard,
        BatchOrders = true,
    },
    [10] = {
        Type = "Attack",
        Callback = IssueAttack,
        BatchOrders = true,
        FullRedundancy = true,
    },
    [11] = {
        Type = "FormAttack",
        Callback = IssueAttack,
        BatchOrders = true,
        FullRedundancy = true,
    },
    [12] = {
        Type = "Nuke",
        Callback = IssueNuke,
        Redundancy = 1,
    },
    [13] = {
        Type = "Tactical",
        Callback = IssueTactical,
        Redundancy = 1,
    },
    [14] = {
        Type = "Teleport",
        Callback = IssueTeleport,
        Redundancy = 1,
    },
    [15] = {
        Type = "Guard",
        Callback = IssueGuard,
        BatchOrders = true,
    },
    [16] = {
        Type = "Patrol",
        Callback = IssuePatrol,
        Redundancy = 3,
    },
    [17] = { Type = "Ferry", },
    [18] = {
        Type = "FormPatrol",
        Callback = IssuePatrol,
        Redundancy = 3,
    },
    [19] = {
        Type = "Reclaim",
        Callback = IssueReclaim,
        BatchOrders = true,
        FullRedundancy = true,
    },
    [20] = {
        Type = "Repair",
        Callback = IssueRepair,
        BatchOrders = true,
        FullRedundancy = true,
    },
    [21] = {
        Type = "Capture",
        Callback = IssueCapture,
        BatchOrders = true,
        FullRedundancy = true,
    },
    [22] = { Type = "TransportLoadUnits", },
    [23] = { Type = "TransportReverseLoadUnits", },
    [24] = {
        Type = "TransportUnloadUnits",
        Callback = IssueTransportUnload,
        Redundancy = 1,
    },
    [25] = { Type = "TransportUnloadSpecificUnits", },
    [26] = { Type = "DetachFromTransport", },
    [27] = { Type = "Upgrade", },
    [28] = { Type = "Script", },
    [29] = {
        Type = "AssistCommander",
        Callback = IssueGuard,
        BatchOrders = true,
    },
    [30] = { Type = "KillSelf", },
    [31] = { Type = "DestroySelf", },
    [32] = {
        Type = "Sacrifice",
        Callback = IssueSacrifice,
        BatchOrders = true,
    },
    [33] = { Type = "Pause", },
    [34] = { Type = "OverCharge", },
    [35] = {
        Type = "AggressiveMove",
        Callback = IssueAggressiveMove,
        BatchOrders = true,
    },
    [36] = {
        Type = "FormAggressiveMove",
        Callback = IssueAggressiveMove,
        BatchOrders = true,
    },
    [37] = { Type = "AssistMove", },
    [38] = { Type = "SpecialAction", },
    [39] = { Type = "Dock", },
}

--- Constructs `l` batches of roughly even size such that when combined they sum up to `h`.
--- As an example, the output is `{3, 3, 2, 2}` when `h = 10` and `l = 4`. The cache parameter
--- allows us to re-use memory
---@param h number          # Higher number
---@param l number          # Lower number
---@param cache number[]    # Table with as many elements as `l`, such as
---@return number[]
function ComputeBatchCounts(h, l, cache)

    -- clear out the cache
    for k, _ in cache do
        cache[k] = nil
    end

    for k = 1, l do
        local count = MathCeil(h / l)
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
function PopulateBatch(start, count, array, cache)
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
function PopulateLocation(order, cache)
    cache[1] = order.x
    cache[2] = order.y
    cache[3] = order.z
    return cache
end