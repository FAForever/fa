--******************************************************************************************************
--** Copyright (c) 2024 FAForever
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
local TableGetn = table.getn
local TableSort = table.sort
local TableSetn = table.setn
local TableInsert = table.insert
local TableRemove = table.remove

local StringFormat = string.format

local IssueReclaim = IssueReclaim

---@type table<EntityId, boolean>
local distances = { }

---@type table<EntityId, boolean>
local seen = { }

---@type Unit[]
local stack = { }

---@param a Prop
---@param b Prop
---@return boolean
local lambdaSortProps = function(a, b)
    return distances[a.EntityId] < distances[b.EntityId]
end

--- Applies a reclaim order to all adjacent units of the same type
---@param units Unit[]
---@param target StructureUnit
---@param doPrint boolean
local function ReclaimAdjacentUnits (units, target, doPrint)
    -- clean up previous iterations
    TableSetn(stack, 0)
    for entityId, _ in seen do
        seen[entityId] = nil
    end

    -- prepare the stack
    seen[target.EntityId] = true
    TableInsert(stack, target)

    local processed = 0

    -- exclude the expansion (u/x) and faction identifier (a/e/s/r)
    local blueprintIdPostfix = string.sub(target.Blueprint.BlueprintId, 2)
    while TableGetn(stack) > 0 do
        local current = TableRemove(stack)
        if current != target then
            IssueReclaim(units, current)
        end

        local adjacentUnits = current.AdjacentUnits
        if adjacentUnits then
            for _, unit in adjacentUnits do
                if blueprintIdPostfix == string.sub(unit.Blueprint.BlueprintId, 2) then
                    if not seen[unit.EntityId] then
                        seen[unit.EntityId] = true
                        TableInsert(stack, unit)
                        processed = processed + 1
                    end
                end
            end
        end
    end

    if doPrint and processed > 0 and (GetFocusArmy() == GetCurrentCommandSource()) then
        print(StringFormat("Reclaiming %d adjacent units", processed))
    end
end

--- Applies a reclaim order to all nearby props
---@param units Unit[]
---@param target Prop
---@param doPrint boolean
---@param areaRadius? number
local function ReclaimNearbyProps (units, target, doPrint, areaRadius)
    local processed = 0
    local radius = areaRadius or 4.0
    local px, _, pz = target:GetPositionXYZ()
    local adjacentReclaim = GetReclaimablesInRect(px - radius, pz - radius, px + radius, pz + radius)

    if adjacentReclaim then
        -- clean up previous iterations
        for entityId, _ in distances do
            distances[entityId] = nil
        end

        -- compute distances
        for k = 1, TableGetn(adjacentReclaim) do
            local entity = adjacentReclaim[k] --[[@as Prop]]
            local ex, _, ez = entity:GetPositionXYZ()
            local dx, dz = px - ex, pz - ez
            distances[entity.EntityId] = dx * dx + dz * dz
        end

        -- sort the props by distance
        TableSort(adjacentReclaim, lambdaSortProps)

        for k = 1, TableGetn(adjacentReclaim) do
            local entity = adjacentReclaim[k] --[[@as Prop]]
            if target != entity and IsProp(entity) and
                entity.MaxMassReclaim > 0 and
                entity.IsTree == target.IsTree and
                distances[entity.EntityId] <= radius * radius
            then
                IssueReclaim(units, entity)
                processed = processed + 1
            end

            -- limit the number of props to add so that we do not create too many reclaim orders. The command queue
            -- is limited to 501 commands, this limit exists to make it very difficult to reach the cap.
            if (processed >= 6 and not areaRadius) or processed >= 400 then
                break
            end
        end
    end

    if doPrint and processed > 0 and (GetFocusArmy() == GetCurrentCommandSource()) then
        print(StringFormat("Reclaiming %d nearby props", processed))
    end
end

--- Applies additional reclaim orders to nearby similar entities that are similar to the target
---@param units Unit[]
---@param ps Unit | 
---@param doPrint boolean           # if true, prints information about the order
function AreaReclaimOrder(units, ps, pe, width, doPrint)
    local unitCount = TableGetn(units)
    if unitCount == 0 then
        return
    end

    if IsUnit(target) and EntityCategoryContains(categories.STRUCTURE, target) then
        return ReclaimAdjacentUnits(units, target, doPrint)
    elseif IsProp(target) then
        return ReclaimNearbyProps(units, target, doPrint, radius)
    end
end

---@param units Unit[]
---@param ps Vector
---@param pe Vector
---@param width number
---@param doPrint boolean
function AreaReclaimProps(units, ps, pe, width, doPrint)

    local processed = 0

    -- determine the direction from ps to pe
    local dx = ps[1] - pe[1]
    local dz = ps[3] - pe[3]
    local distance = math.sqrt(dx * dx + dz * dz)

    local nx = (1 / distance) * dx
    local nz = (1 / distance) * dz

    -- orthogonal normalized direction
    local ox = nz
    local oz = -nx

    -- determine edge points
    local ps1 = { ps[1] + width * ox, ps[2], ps[3] + width * oz }
    local ps2 = { ps[1] - width * ox, ps[2], ps[3] - width * oz }

    local pe1 = { pe[1] + width * ox, pe[2], pe[3] + width * oz }
    local pe2 = { pe[1] - width * ox, pe[2], pe[3] - width * oz }

    -- determine bounding box
    local minX = math.min(ps1[1], ps2[1], pe1[1], pe2[1])
    local minZ = math.min(ps1[3], ps2[3], pe1[3], pe2[3])
    local maxX = math.max(ps1[1], ps2[1], pe1[1], pe2[1])
    local maxZ = math.max(ps1[3], ps2[3], pe1[3], pe2[3])

    local reclaim = GetReclaimablesInRect(minX, minZ, maxX, maxZ)
    if reclaim then

        -- clean up previous iterations
        for entityId, _ in distances do
            distances[entityId] = nil
        end

        -- compute squared distances for sorting
        for k = 1, TableGetn(reclaim) do
            local entity = reclaim[k] --[[@as Prop]]
            local ex, _, ez = entity:GetPositionXYZ()
            local dx, dz = ps[1] - ex, ps[3] - ez
            distances[entity.EntityId] = dx * dx + dz * dz
        end

        -- sort the props by distance
        TableSort(reclaim, lambdaSortProps)

        -- compute squared distances for filtering
        for k = 1, TableGetn(reclaim) do
            local entity = reclaim[k] --[[@as Prop]]
            local ex, _, ez = entity:GetPositionXYZ()

            -- project onto the line segment
            -- https://stackoverflow.com/questions/849211/shortest-distance-between-a-point-and-a-line-segment

            local pvx = ex - ps[1]
            local pvz = ez - ps[3]
            local wvx = pe[1] - ps[1]
            local wvz = pe[3] - ps[3]
            local dot = pvx * wvx + pvz * wvz
            local t = math.max(0, math.min(1, dot / (distance * distance)))
            local prx = ps[1] + t * wvx
            local prz = ps[3] + t * wvz

            -- compute squared distance of projected vector
            local dx = ex - prx
            local dz = ez - prz
            distances[entity.EntityId] = dx * dx + dz * dz
        end

        -- filter the props by distance
        for k = 1, TableGetn(reclaim) do
            local entity = reclaim[k] --[[@as Prop]]
            if IsProp(entity) and
                entity.MaxMassReclaim > 1 and
                (not entity.IsTree) and
                distances[entity.EntityId] <= width * width
            then
                IssueReclaim(units, entity)
                processed = processed + 1
            end
        end
    end

    if doPrint and processed > 0 and (GetFocusArmy() == GetCurrentCommandSource()) then
        print(StringFormat("Reclaiming %d additional props", processed))
    end
end