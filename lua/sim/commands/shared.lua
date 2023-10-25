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

-- upvalue scope for performance
local MathCeil = math.ceil
local TableSort = table.sort

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
        Callback = IssueBuildAllMobile,
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
        Callback = function(units, positionOrEntity)
            if IsDestroyed(positionOrEntity) then
                return
            end

            pcall(IssueReclaim, units, positionOrEntity)
        end,
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

---@param a Unit
---@param b Unit
---@return boolean
local function SortByDistance(a, b)
    return a.Distance < b.Distance
end

--- Sorts the unit in-place by distance to the given coordinates
---@param units Unit[]
---@param px number
---@param pz number
function SortUnitsByDistanceToPoint(units, px, pz)
    -- compute distance
    for _, unit in units do
        local ux, _, uz = unit:GetPositionXYZ()
        local dx = ux - px
        local dz = uz - pz
        unit.Distance = dx * dx + dz * dz
    end

    -- sort the units
    TableSort(units,SortByDistance)

    -- remove distance field
    for _, unit in units do
        unit.Distance = nil
    end
end

---@param a Unit
---@param b Unit
---@return boolean
local function SortBytech(a, b)
    return a.Blueprint.TechCategory > b.Blueprint.TechCategory
end

--- Sorts the units in-place by tech
---@param units Unit[]
function SortUnitsByTech(units)
    TableSort(units,SortBytech)
end

---@param offsets {[1]: number, [2]: number}
---@param cx number
---@param cz number
---@param tx number
---@param tz number
function SortOffsetsByDistanceToPoint(offsets, cx, cz, tx, tz)
    -- compute distance
    for _, offset in offsets do
        local dx = offset[1] + cx - tx
        local dz = offset[2] + cz - tz
        offset.Distance = dx * dx + dz * dz
    end

    -- sort it all
    TableSort(offsets, SortByDistance)

    -- remove distance field
    for _, offset in offsets do
        offset.Distance = nil
    end
end

--- Computes the average x / z coordinates of a table of units
---@param units Unit[]
function AveragePositionOfUnitsXZ(units)
    local unitCount = table.getn(units)

    local px = 0
    local pz = 0
    for k = 1, unitCount do
        local ux, _, uz = units[k]:GetPositionXYZ()
        px = px + ux
        pz = pz + uz
    end

    return (px / unitCount), (pz / unitCount)
end

--- Computes the average x / z coordinates of a table of units
---@param units Unit[]
---@return Vector
function AveragePositionOfUnits(units)
    local unitCount = table.getn(units)

    local px = 0
    local pz = 0
    for k = 1, unitCount do
        local ux, _, uz = units[k]:GetPositionXYZ()
        px = px + ux
        pz = pz + uz
    end

    px = px / unitCount
    pz = pz / unitCount

    return {
        px,
        GetSurfaceHeight(px, pz),
        pz
    }
end

---@param px number
---@param pz number
---@param radius number
---@param degrees number
---@return Vector
function PointOnUnitCircle(px, pz, radius, degrees)
    local cx = px + radius * math.cos( (degrees + 90) * 3.14 / 180 );
    local cz = pz + radius * math.sin( (degrees + 90) * 3.14 / 180 );
    return {
        cx,
        GetSurfaceHeight(cx, cz),
        cz
    }
end


---@param units Unit[]
---@param px number
---@param pz number
---@return Unit | nil
function FindNearestUnit(units, px, pz)
    local nearest = units[1]
    local distance = 4193 * 4193
    for k = 1, table.getn(units) do
        local unit = units[k]
        local ux, _, uz = unit:GetPositionXYZ()
        local dx = px - ux
        local dz = pz - uz
        local d = dx * dx + dz * dz
        if d < distance then
            nearest = unit
            distance = d
        end
    end

    return nearest
end
