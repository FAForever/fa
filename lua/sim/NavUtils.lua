
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

local Shared = import("/lua/shared/navgenerator.lua")
local Colors = import("/lua/shared/color.lua")
local NavGenerator = import("/lua/sim/navgenerator.lua")
local NavDatastructures = import("/lua/sim/navdatastructures.lua")

-- upvalue scope for performance
local TableGetn = table.getn

local MathSqrt = math.sqrt

-------------------------------------------------------------------------------
--#region Debugging functionality

local Debug = false
function EnableDebugging()
    Debug = true
end

function DisableDebugging()
    Debug = false
end

---@type { PathTo: { Tick: number, Path: Vector[], Origin: Vector, Destination: Vector }[] , PathToWithThreatThreshold: { Tick: number, Path: Vector[], Origin: Vector, Destination: Vector }[] }
local paths = {
    PathTo = { },
    PathToWithThreatThreshold = { }
}

---@param path Vector[]
---@param type 'PathTo' | 'PathToWithThreatThreshold'
function DebugRegisterPath(type, path, origin, destination)
    if Debug then
        ---@type { Tick: number, Path: Vector[], Origin: Vector, Destination: Vector }[]
        local cache = paths[type]
        if cache then
            local n = TableGetn(cache)
            cache[n + 1] = {
                Tick = GetGameTick(),
                Path = path,
                Origin = origin,
                Destination = destination,
            }
        end
    end
end

function DebugPathRender()
    local DrawCircle = DrawCircle
    local DrawLinePop = DrawLinePop
    local GetGameTick = GetGameTick
    local TableGetn = TableGetn
    local ColorsRGB = Colors.ColorRGB

    local duration = 150

    while true do
        local tick = GetGameTick()
        for type, cache in paths do
            for id, info in cache do
                local fraction = (tick - info.Tick) / (duration)
                if fraction > 1 then
                    fraction = 1
                elseif fraction < 0 then
                    fraction = 0
                end

                local color = ColorsRGB(1 - fraction, 1 - fraction, 1 - fraction)

                -- draw start
                DrawCircle(info.Origin, 1.9, '000000')
                DrawCircle(info.Origin, 2, color)
                DrawCircle(info.Origin, 2.1, '000000')

                -- draw end
                DrawCircle(info.Destination, 1.9, '000000')
                DrawCircle(info.Destination, 2, color)
                DrawCircle(info.Destination, 2.1, '000000')

                -- draw path
                local path = info.Path
                local n = TableGetn(path)
                if n >= 2 then
                    local last = path[1]
                    for k = 2, n do
                        DrawLinePop(last, path[k], color)
                        last = path[k]
                    end
                end

                -- remove paths we're no longer interested in
                if info.Tick + duration < tick then
                    cache[id] =  nil
                end
            end
        end

        WaitTicks(1)
    end
end

local DebugPathRenderThread = ForkThread(DebugPathRender)

--- Called by the module manager when this module is dirty due to a disk change
function __moduleinfo.OnDirty()
    if DebugPathRenderThread then
        DebugPathRenderThread:Destroy()
    end
end

--#endregion Debugging functionality
-------------------------------------------------------------------------------

--- Returns true if the navigational mesh is generated
---@return boolean
function IsGenerated()
    return NavGenerator.IsGenerated()
end

--- Generates the navigational mesh if it is not generated yet
function Generate()
    if not IsGenerated() then
        NavGenerator.Generate()
    end
end

--- Converts a world distance into grid distance
---@param distance number
---@return number
function ToGridDistance(distance)
    local sizeOfCell = NavGenerator.SizeOfCell()
    return math.floor(distance / sizeOfCell) + 1
end

---@param layer NavLayers
---@return NavGrid?
---@return 'InvalidLayer'?
local function FindGrid(layer)
    local grid = NavGenerator.NavGrids[layer] --[[@as NavGrid]]
    if not grid then
        return nil, 'InvalidLayer'
    end

    return grid
end

---@param grid NavGrid
---@param position Vector
---@return NavLeaf | nil
---@return 'OutsideMap' | nil
local function FindLeaf(grid, position)
    -- check position argument
    local leaf = grid:FindLeafXZ(position[1], position[3])
    if not leaf then
        return nil, 'OutsideMap'
    end

    if leaf.Label == -1 then
        local distance = 1048576
        local nearest = nil
        local px = position[1]
        local pz = position[3]

        -- try and find nearest valid neighbor
        for k = 1, TableGetn(leaf) do
            local neighbor = NavGenerator.NavCells[leaf[k]]
            if neighbor.Label > 0 then
                local size = 2 * neighbor.Size
                size = size * size

                local dx = px - neighbor.px
                local dz = pz - neighbor.pz
                local d = dx * dx + dz * dz
                if d < distance and d < size then
                    distance = d
                    nearest = neighbor
                end
            end
        end

        return nearest or leaf
    end

    return leaf
end

---@param a NavLeaf
---@param b NavLeaf
---@return number
local SquaredDistanceTo = function(a, b)
    local dx = a.px - b.px
    local dz = a.pz - b.pz
    return dx * dx + dz * dz
end

---@param a NavLeaf
---@param b NavLeaf
---@return number
local DistanceTo = function(a, b)
    local dx = a.px - b.px
    local dz = a.pz - b.pz
    return MathSqrt(dx * dx + dz * dz)
end

---@param grid NavGrid
---@param position Vector A position in world space
---@return NavTree?
local FindRoot = function(grid, position)
    return grid:FindRootXZ(position[1], position[3])
end

---@param destination NavLeaf 
---@return Vector[]
---@return number   # Number of points in path
---@return number   # Distance of path
local function TracePath(destination)

    -- local scope for performance
    local GetSurfaceHeight = GetSurfaceHeight

    ---@type number
    local head = 1

    ---@type Vector[]
    local path = { }

    ---@type number
    local distance = 0

    ---@type NavLeaf | nil
    local leaf = destination.From

    -- trace path from destination
    while leaf and leaf.From and (leaf.From != destination) do
        local px = leaf.px
        local pz = leaf.pz
        path[head] = { px, GetSurfaceHeight(px, pz), pz }
        head = head + 1

        -- keep track of distance
        distance = distance + DistanceTo(leaf, leaf.From)

        leaf = leaf.From
    end

    -- reverse the path
    for k = 1, (0.5 * head) ^ 0 do
        local temp = path[k]
        path[k] = path[head - k]
        path[head - k] = temp
    end

    -- include destination into path
    local px = destination.px
    local pz = destination.pz
    path[head] = { px, GetSurfaceHeight(px, pz), pz }

    return path, head, distance
end

--- Returns true when you can path from the origin to the destination
---@param layer NavLayers
---@param origin Vector
---@param destination Vector
---@return boolean?
---@return ('SystemError' | 'NotGenerated' | 'InvalidLayer' | 'OutsideMap' | 'OriginOutsideMap' | 'OriginUnpathable' | 'DestinationOutsideMap' | 'DestinationUnpathable' | 'Unpathable')?
function CanPathTo(layer, origin, destination)
    -- check if generated
    if not NavGenerator.IsGenerated() then
        return nil, 'NotGenerated'
    end

    -- check layer argument
    local grid = FindGrid(layer)
    if not grid then
        return nil, 'InvalidLayer'
    end

    -- check origin argument
    local originLeaf = FindLeaf(grid, origin)
    if not originLeaf then
        return nil, 'OriginOutsideMap'
    end

    if originLeaf.Label == -1 then
        return nil, 'OriginUnpathable'
    end

    if originLeaf.Label == 0 then
        return nil, 'SystemError'
    end

    -- check destination argument
    local destinationLeaf = FindLeaf(grid, destination)
    if not destinationLeaf then
        return nil, 'DestinationOutsideMap'
    end

    if destinationLeaf.Label == -1 then
        return nil, 'DestinationUnpathable'
    end

    if destinationLeaf.Label == 0 then
        return nil, 'SystemError'
    end

    if originLeaf.Label == destinationLeaf.Label then
        return true
    else
        return false, 'Unpathable'
    end
end

--- A more generous version of `CanPathTo`. Returns true when the root cell of the destination has a label that matches the label of the origin. Is in general less accurate
---@param layer NavLayers
---@param origin Vector
---@param destination Vector
---@return boolean?
---@return ('SystemError' | 'NotGenerated' | 'InvalidLayer' | 'OutsideMap' | 'OriginOutsideMap' | 'OriginUnpathable' | 'DestinationOutsideMap' | 'Unpathable')?
function CanPathToCell (layer, origin, destination)
    -- check if generated
    if not NavGenerator.IsGenerated() then
        return nil, 'NotGenerated'
    end

    -- check layer argument
    local grid = FindGrid(layer)
    if not grid then
        return nil, 'InvalidLayer'
    end

    -- check origin argument
    local originLeaf = FindLeaf(grid, origin)
    if not originLeaf then
        return nil, 'OriginOutsideMap'
    end

    if originLeaf.Label == -1 then
        return nil, 'OriginUnpathable'
    end

    if originLeaf.Label == 0 then
        return nil, 'SystemError'
    end

    -- check destination argument
    local destinationRoot = FindRoot(grid, destination)
    if not destinationRoot then
        return nil, 'DestinationOutsideMap'
    end

    if destinationRoot.Labels[originLeaf.Label] then
        return true
    else
        return false, 'Unpathable'
    end
end

---@type NavHeap
local PathToHeap = NavDatastructures.NavHeap()

---@type number
local PathToIdentifier = 1

---@return number
local function PathToGetUniqueIdentifier()
    PathToIdentifier = PathToIdentifier + 1
    return PathToIdentifier
end

---@param layer NavLayers
---@param origin Vector
---@param destination Vector
---@return Vector[]?            # List of positions
---@return ('SystemError' | 'NotGenerated' | 'InvalidLayer' | 'OutsideMap' | 'OriginOutsideMap' | 'OriginUnpathable' | 'DestinationOutsideMap' | 'DestinationUnpathable' | 'Unpathable') | number   # Error message, or the number of positions
---@return number?              # Length of path
function PathTo(layer, origin, destination)
    -- check if generated
    if not NavGenerator.IsGenerated() then
        return nil, 'NotGenerated'
    end

    -- check if we can path
    local ok, msg = CanPathTo(layer, origin, destination)
    if not ok then
        return nil, msg
    end

    -- setup pathing
    local seenIdentifier = PathToGetUniqueIdentifier()
    local grid = FindGrid(layer)                        --[[@as NavGrid]]
    local originLeaf = FindLeaf(grid, origin)           --[[@as NavLeaf]]
    local destinationLeaf = FindLeaf(grid, destination) --[[@as NavLeaf]]

    -- 0th iteration of search
    originLeaf.From = nil
    originLeaf.AcquiredCosts = 0
    originLeaf.TotalCosts = DistanceTo(originLeaf, destinationLeaf)
    originLeaf.Seen = seenIdentifier

    -- start using the navigational heap
    PathToHeap:Clear()
    PathToHeap:Insert(originLeaf)

    destinationLeaf.From = nil
    destinationLeaf.AcquiredCosts = 0
    destinationLeaf.TotalCosts = 0
    destinationLeaf.Seen = 0

    -- search iterations
    while not PathToHeap:IsEmpty() do

        local leaf = PathToHeap:ExtractMin() --[[@as NavLeaf]]

        -- final state
        if leaf == destinationLeaf then
            break
        end

        -- continue state
        for k = 1, TableGetn(leaf) do
            local neighbor = NavGenerator.NavCells[leaf[k]]
            if neighbor.Label > 0 and neighbor.Seen != seenIdentifier then
                local preferLargeNeighbor = 0
                if leaf.Size > neighbor.Size then
                    preferLargeNeighbor = 100
                end
                neighbor.From = leaf
                neighbor.Seen = seenIdentifier
                neighbor.AcquiredCosts = leaf.AcquiredCosts + DistanceTo(leaf, neighbor) + 2 + preferLargeNeighbor
                neighbor.TotalCosts = neighbor.AcquiredCosts + 0.25 * DistanceTo(destinationLeaf, neighbor)

                PathToHeap:Insert(neighbor)
            else 
                -- if neighbor.AcquiredCosts > leaf.AcquiredCosts + leaf.neighborDistances[id] then
                --     neighbor.From = leaf
                -- end
            end
        end
    end

    -- check if we found a path
    if not destinationLeaf.Seen == seenIdentifier then
        return nil, 'SystemError'
    end

    local path, head, distance = TracePath(destinationLeaf)

    -- debugging!
    DebugRegisterPath('PathTo', path, origin, destination)

    -- return all the goodies!!
    return path, head, distance
end

ThreatFunctions = Shared.ThreatFunctions

---@param layer NavLayers
---@param origin Vector
---@param destination Vector
---@param aibrain AIBrain
---@param threatFunc fun(aiBrain: AIBrain, position: Vector, radius: number) : number
---@param threatThreshold number
---@param threatRadius number
---@return Vector[]?            # List of positions
---@return (('SystemError' | 'NotGenerated' | 'InvalidLayer' | 'OutsideMap' | 'OriginOutsideMap' | 'OriginUnpathable' | 'DestinationOutsideMap' | 'DestinationUnpathable' | 'Unpathable') | number)?   # Error message, or the number of positions
---@return number?              # Length of path
function PathToWithThreatThreshold(layer, origin, destination, aibrain, threatFunc, threatThreshold, threatRadius)
    -- check if generated
    if not NavGenerator.IsGenerated() then
        return nil, 'NotGenerated'
    end

    -- check if we can path
    local ok, msg = CanPathTo(layer, origin, destination)
    if not ok then
        return nil, msg
    end

    -- setup pathing
    local seenIdentifier = PathToGetUniqueIdentifier()
    local grid = FindGrid(layer)                        --[[@as NavGrid]]
    local originLeaf = FindLeaf(grid, origin)           --[[@as NavLeaf]]
    local destinationLeaf = FindLeaf(grid, destination) --[[@as NavLeaf]]

    -- 0th iteration of search
    originLeaf.From = nil
    originLeaf.AcquiredCosts = 0
    originLeaf.TotalCosts = DistanceTo(originLeaf, destinationLeaf)
    originLeaf.Seen = seenIdentifier

    -- start using the navigational heap
    PathToHeap:Clear()
    PathToHeap:Insert(originLeaf)

    destinationLeaf.From = nil
    destinationLeaf.AcquiredCosts = 0
    destinationLeaf.TotalCosts = 0
    destinationLeaf.Seen = 0

    -- search iterations
    while not PathToHeap:IsEmpty() do

        local leaf = PathToHeap:ExtractMin() --[[@as NavLeaf]]

        -- did we reach the destination?
        if leaf == destinationLeaf then
            break
        end

        -- search through neighbors
        for k = 1, TableGetn(leaf) do
            local neighbor = NavGenerator.NavCells[leaf[k]]
            if neighbor.Label > 0 and neighbor.Seen != seenIdentifier then
                local preferLargeNeighbor = 0
                if leaf.Size > neighbor.Size then
                    preferLargeNeighbor = 100
                end

                -- update threat state
                local root = neighbor.Root
                if neighbor.Seen != seenIdentifier then
                    root.Threat = threatFunc(aibrain, {neighbor.px, 0, neighbor.pz}, threatRadius)
                end

                -- update pathing state
                neighbor.From = leaf
                neighbor.Seen = seenIdentifier
                neighbor.AcquiredCosts = leaf.AcquiredCosts + DistanceTo(leaf, neighbor) + 2 + preferLargeNeighbor
                neighbor.TotalCosts = neighbor.AcquiredCosts + 0.25 * DistanceTo(destinationLeaf, neighbor)

                -- include in search when threat is low enough
                if root.Threat <= threatThreshold then
                    PathToHeap:Insert(neighbor)
                end
            end
        end
    end

    -- check if we found a path
    if not destinationLeaf.Seen == seenIdentifier then
        return nil, 'SystemError'
    end

    local path, head, distance = TracePath(destinationLeaf)

    DebugRegisterPath('PathToWithThreatThreshold', path, origin, destination)

    -- return all the goodies!!
    return path, head, distance
end

--- Returns a label that indicates to what sub-graph it belongs to. Unlike `GetTerrainLabel` this function will try to find the nearest valid neighbor
---@see GetTerrainLabel
---@param layer NavLayers
---@param position Vector
---@return number? 
---@return ('NotGenerated' | 'InvalidLayer' | 'OutsideMap' | 'SystemError' | 'Unpathable')?
function GetLabel(layer, position)
    -- check if generated
    if not NavGenerator.IsGenerated() then
        return nil, 'NotGenerated'
    end

    -- check layer argument
    local grid = FindGrid(layer)
    if not grid then
        return nil, 'InvalidLayer'
    end

    -- check position argument
    local leaf = FindLeaf(grid, position)
    if not leaf then
        return nil, 'OutsideMap'
    end

    if leaf.Label == 0 then
        return nil, 'SystemError'
    end

    if leaf.Label == -1 then
        return nil, 'Unpathable'
    end

    return leaf.Label, nil
end

--- Returns a table with all labels in the current iMAP cell. The keys represent the labels. The values represent the ratio of area it occupies in the cell
---@param layer NavLayers
---@param gx number
---@param gz number
---@return table<number, number>? 
---@return ('NotGenerated' | 'InvalidLayer' | 'OutsideMap' | 'SystemError' | 'Unpathable')?
function GetLabelsofIMAP(layer, gx, gz)
    -- check if generated
    if not NavGenerator.IsGenerated() then
        return nil, 'NotGenerated'
    end

    -- check layer argument
    local grid = FindGrid(layer)
    if not grid then
        return nil, 'InvalidLayer'
    end

    -- check position argument
    local root = grid:FindRootGridspaceXZ(gx - 1, gz - 1)
    if not root then
        return nil, 'OutsideMap'
    end

    if not root.Labels then
        return nil, 'SystemError'
    end

    return root.Labels, nil
end

--- Returns a label that indicates to what sub-graph it belongs to. Unlike `GetLabel` this function does not try to find valid neighbors
---@see GetLabel
---@param layer NavLayers
---@param position Vector
---@return number? 
---@return ('NotGenerated' | 'InvalidLayer' | 'OutsideMap' | 'SystemError' | 'Unpathable')?
function GetTerrainLabel(layer, position)
    -- check if generated
    if not NavGenerator.IsGenerated() then
        return nil, 'NotGenerated'
    end

    -- check layer argument
    local grid = FindGrid(layer)
    if not grid then
        return nil, 'InvalidLayer'
    end

    -- check position argument
    local leaf = grid:FindLeaf(position)
    if not leaf then
        return nil, 'OutsideMap'
    end

    if leaf.Label == 0 then
        return nil, 'SystemError'
    end

    if leaf.Label == -1 then
        return nil, 'Unpathable'
    end

    return leaf.Label, nil
end

---@type NavTree[]
local GetPositionsInRadiusCandidates = {}
local GenericResultsCache = { }
local GenericQueueCache = { }

---@param layer NavLayers
---@param position Vector
---@param thresholdDistance number
---@param thresholdSize? number
---@return { [1]: number, [2]: number, [3]: number }?
---@return number | ('NotGenerated' | 'InvalidLayer' | 'OutsideMap' | 'SystemError' | 'Unpathable' | 'NoData')?
function GetPositionsInRadius(layer, position, thresholdDistance, thresholdSize, cache)
    -- check if generated
    if not NavGenerator.IsGenerated() then
        return nil, 'NotGenerated'
    end

    -- check layer argument
    local grid = FindGrid(layer)
    if not grid then
        return nil, 'InvalidLayer'
    end

    -- local scope for performance
    local TableEmpty = table.empty
    local TableGetn = table.getn
    local FindRootGridspaceXZ = grid.FindRootGridspaceXZ

    ---------------------------------------------------------------------------
    -- find candidates that we can search for traversable leaves

    local candidatesHead = 1
    local candidates = GetPositionsInRadiusCandidates
    local gx, gz = grid:ToGridSpace(position)
    if not (gx and gz) then
        return nil, 'OutsideMap'
    end

    local distanceInCells = ToGridDistance(thresholdDistance)
    for lz = -distanceInCells, distanceInCells do
        for lx = -distanceInCells, distanceInCells do
            local neighbor = FindRootGridspaceXZ(grid, gx + lz, gz + lx)
            if neighbor and not TableEmpty(neighbor.Labels) then
                candidates[candidatesHead] = neighbor
                candidatesHead = candidatesHead + 1
            end
        end
    end

    -- no neighboring cells found
    if candidatesHead == 1 then
        return nil, 'NoData'
    end

    ---------------------------------------------------------------------------
    -- convert candidates to positions

    -- local scope for performance
    local GetSurfaceHeight = GetSurfaceHeight
    local FindTraversableLeaves = candidates[1].FindTraversableLeaves

    -- convert to a series of positions
    local cacheHead = 1
    cache = cache or { }
    for k = 1, candidatesHead - 1 do
        local candidate = candidates[k]

        -- check if we have at least one traversable leaf
        local leaves, leafCount = FindTraversableLeaves(candidate, thresholdSize, GenericResultsCache, GenericQueueCache)
        local largest = leaves[1]
        if not largest then
            continue
        end

        for l = 1, leafCount do
            local leaf = leaves[l]
            local px = leaf.px
            local pz = leaf.pz
            local size = leaf.Size
            local position = cache[cacheHead] or { }
            position[1] = px 
            position[2] = GetSurfaceHeight(px, pz)
            position[3] = pz

            -- this is useful information, but it causes issues with functions such as `IssueMove`
            -- position[4] = size

            cache[cacheHead] = position
            cacheHead = cacheHead + 1
        end
    end

    -- no traversable leaves found
    if cacheHead == 1 then
        return nil, 'NoData'
    end

    -- clean up cache
    for k = cacheHead, TableGetn(cache) do
        cache[k] = nil
    end

    return cache, cacheHead - 1
end

--- Returns the metadata of a label.
---@param id number
---@return NavLabelMetadata?
---@return ('NotGenerated' | 'InvalidLayer' | 'OutsideMap' | 'SystemError' | 'Unpathable' | 'NoData' )?
function GetLabelMetadata(id)
    -- check if generated
    if not NavGenerator.IsGenerated() then
        return nil, 'NotGenerated'
    end

    -- check id argument
    if id == 0 then
        return nil, 'SystemError'
    end

    if id == -1 then
        return nil, 'Unpathable'
    end

    local meta = NavGenerator.NavLabels[id]
    if not meta then
        return nil, 'NoData'
    end

    return meta, nil
end

local DirectionsFromCandidates = { }
local DirectionsFromFound = { }

--- Computes a list of waypoints that represent random directions that we can navigate to
---@param layer NavLayers
---@param origin Vector
---@param distance number
---@param sizeThreshold number
---@return Vector[] | nil
---@return number | ('NotGenerated' | 'OutsideMap' | 'NoResults')
function DirectionsFrom(layer, origin, distance, sizeThreshold)

    -- check if generated
    if not NavGenerator.IsGenerated() then
        return nil, 'NotGenerated'
    end

    -- setup pathing
    local seenIdentifier = PathToGetUniqueIdentifier()
    local grid = FindGrid(layer)                        --[[@as NavGrid]]
    local originLeaf = FindLeaf(grid, origin)           --[[@as NavLeaf]]

    -- sanity check
    if not originLeaf then
        return nil, 'OutsideMap'
    end

    -- local scope for performance
    local ox = origin[1]
    local oz = origin[3]
    local found = DirectionsFromFound
    local candidates = DirectionsFromCandidates
    local head = 1

    -- 0th iteration of search
    originLeaf.From = nil
    originLeaf.AcquiredCosts = 0
    originLeaf.TotalCosts = distance
    originLeaf.Seen = seenIdentifier

    -- start using the navigational heap
    PathToHeap:Clear()
    PathToHeap:Insert(originLeaf)

    while not PathToHeap:IsEmpty() do
        local leaf = PathToHeap:ExtractMin() --[[@as NavLeaf]]

        -- do not take into account small leafs as they clutter the results
        if leaf.Size < sizeThreshold then
            continue
        end

        -- threshold for when we accept a leaf
        local px = leaf.px
        local pz = leaf.pz

        local dx = px - ox
        local dz = pz - oz

        local d2 = dx * dx + dz * dz

        if d2 > distance * distance then
            if not found[leaf] then
                found[leaf] = true
                candidates[head] = leaf
                head = head + 1
            end

            continue
        end

        -- search neighbors for more leafs
        for k = 1, TableGetn(leaf) do
            local neighbor = NavGenerator.NavCells[leaf[k]]
            if neighbor.Label > 0 and neighbor.Seen != seenIdentifier then
                neighbor.From = leaf
                neighbor.Seen = seenIdentifier
                neighbor.AcquiredCosts = leaf.AcquiredCosts + DistanceTo(leaf, neighbor)
                neighbor.TotalCosts = 0

                PathToHeap:Insert(neighbor)
            end
        end
    end

    -- convert to a series of positions
    if head <= 1 then
        return nil, 'NoResults'
    end

    -- convert to a series of positions
    local positions = { }
    for k = 1, head - 1 do
        local candidate = candidates[k]
        local px = candidate.px
        local pz = candidate.pz

        local dx = px - ox
        local dz = pz - oz

        local d = MathSqrt(dx * dx + dz * dz)

        local x = ox + distance / d * dx
        local z = oz + distance / d * dz

        positions[k] = {
            x,
            GetSurfaceHeight(x, z),
            z,
        }
    end

    for k, _ in found do
        found[k] = nil
    end

    for k , _ in candidates do
        candidates[k] = nil
    end

    return positions, head - 1
end

local RandomDirectionFromFound = { }
local RandomDirectionFromCandidates = { }

--- Computes a waypoint that represents a random direction that we can navigate to
---@param layer NavLayers
---@param origin Vector
---@param distance number
---@return Vector | nil
---@return ('NotGenerated' | 'OutsideMap' | 'NoResults')?
function RandomDirectionFrom(layer, origin, distance, sizeThreshold)

    -- check if generated
    if not NavGenerator.IsGenerated() then
        return nil, 'NotGenerated'
    end

    -- setup pathing
    local seenIdentifier = PathToGetUniqueIdentifier()
    local grid = FindGrid(layer)                        --[[@as NavGrid]]
    local originLeaf = FindLeaf(grid, origin)           --[[@as NavLeaf]]

    -- sanity check
    if not originLeaf then
        return nil, 'OutsideMap'
    end

    -- local scope for performance
    local ox = origin[1]
    local oz = origin[3]
    local found = RandomDirectionFromFound
    local candidates = RandomDirectionFromCandidates
    local head = 1

    -- 0th iteration of search
    originLeaf.From = nil
    originLeaf.AcquiredCosts = 0
    originLeaf.TotalCosts = distance
    originLeaf.Seen = seenIdentifier

    -- start using the navigational heap
    PathToHeap:Clear()
    PathToHeap:Insert(originLeaf)

    while not PathToHeap:IsEmpty() do
        local leaf = PathToHeap:ExtractMin() --[[@as NavLeaf]]

        -- do not take into account small leafs as they clutter the results
        if leaf.Size < sizeThreshold then
            continue
        end

        -- threshold for when we accept a leaf
        local px = leaf.px
        local pz = leaf.pz

        local dx = px - ox
        local dz = pz - oz

        local d2 = dx * dx + dz * dz

        if d2 > distance * distance then
            if not found[leaf] then
                found[leaf] = true
                candidates[head] = leaf
                head = head + 1
            end

            continue
        end

        -- search neighbors for more leafs
        for k = 1, TableGetn(leaf) do
            local neighbor = NavGenerator.NavCells[leaf[k]]
            if neighbor.Label > 0 and neighbor.Seen != seenIdentifier then
                neighbor.From = leaf
                neighbor.Seen = seenIdentifier
                neighbor.AcquiredCosts = leaf.AcquiredCosts + DistanceTo(leaf, neighbor)
                neighbor.TotalCosts = 0

                PathToHeap:Insert(neighbor)
            end
        end
    end

    -- convert to a series of positions
    if head <= 1 then
        return nil, 'NoResults'
    end

    -- retrieve a random candidate
    local candidate = candidates[Random(1, TableGetn(candidates))]

    local px = candidate.px
    local pz = candidate.pz

    local dx = px - ox
    local dz = pz - oz

    local d = MathSqrt(dx * dx + dz * dz)

    local x = ox + distance / d * dx
    local z = oz + distance / d * dz

    local waypoint = { 
        x,
        GetSurfaceHeight(x, z),
        z
    }

    for k, _ in found do
        found[k] = nil
    end

    for k , _ in candidates do
        candidates[k] = nil
    end

    return waypoint
end

local EscapeFromFound = { }
local EscapeFromCandidates = { }

--- Computes a waypoint that represents a retreat direction that is a valid location to path to
---@param layer NavLayers
---@param origin Vector
---@param threat Vector
---@param distance number
---@return Vector | nil
---@return ('NotGenerated' | 'OutsideMap' | 'NoResults')?
function RetreatDirectionFrom(layer, origin, threat, distance)

    -- check if generated
    if not NavGenerator.IsGenerated() then
        return nil, 'NotGenerated'
    end

    -- setup pathing
    local seenIdentifier = PathToGetUniqueIdentifier()
    local grid = FindGrid(layer)                        --[[@as NavGrid]]
    local originLeaf = FindLeaf(grid, origin)           --[[@as NavLeaf]]

    -- sanity check
    if not originLeaf then
        return nil, 'OutsideMap'
    end

    -- compute direction we're trying to threat
    local tx = threat[1] - origin[1]
    local tz = threat[3] - origin[3]
    local ed = 1 / (MathSqrt(tx * tx + tz * tz))
    tx = ed * tx
    tz = ed * tz

    -- local scope for performance
    local ox = origin[1]
    local oz = origin[3]
    local found = EscapeFromFound
    local candidates = EscapeFromCandidates
    local head = 1

    -- 0th iteration of search
    originLeaf.From = nil
    originLeaf.AcquiredCosts = 0
    originLeaf.TotalCosts = distance
    originLeaf.Seen = seenIdentifier

    -- start using the navigational heap
    PathToHeap:Clear()
    PathToHeap:Insert(originLeaf)

    while not PathToHeap:IsEmpty() do
        local leaf = PathToHeap:ExtractMin() --[[@as NavLeaf]]

        -- add neighbors of leaf that is too close to the origin
        if leaf.AcquiredCosts < distance then
            for k = 1, TableGetn(leaf) do
                local neighbor = NavGenerator.NavCells[leaf[k]]
                if neighbor.Label > 0 and neighbor.Seen != seenIdentifier then

                    px = neighbor.px
                    pz = neighbor.pz

                    dx = px - ox
                    dz = pz - oz

                    neighbor.From = leaf
                    neighbor.Seen = seenIdentifier
                    neighbor.AcquiredCosts = leaf.AcquiredCosts + DistanceTo(leaf, neighbor)
                    neighbor.TotalCosts = tx * dx + tz * dz

                    PathToHeap:Insert(neighbor)
                end
            end
        else
            found[leaf] = true
            candidates[head] = leaf
            head = head + 1
        end
    end

    if head <= 1 then
        return nil, 'NoResults'
    end

    -- find best retreat direction
    local lowest = 1000
    local result = candidates[1]

    for k, candidate in candidates do
        local px = candidate.px
        local pz = candidate.pz

        local dx = px - ox
        local dz = pz - oz

        local d = MathSqrt(dx * dx + dz * dz)
        local di = 1 / d

        local nx = di * dx
        local nz = di * dz

        local radians = nx * tx + nz * tz

        if 0.6 * d < distance then
            if radians < lowest then
                lowest = radians
                result = candidate
            end
        end
    end

    -- try to match the intended distance as best as we can
    local px = result.px
    local pz = result.pz

    local dx = px - ox
    local dz = pz - oz

    local d = MathSqrt(dx * dx + dz * dz)

    if d < distance then
        distance = d
    end

    local x = ox + distance / d * dx
    local z = oz + distance / d * dz

    local waypoint = { 
        x,
        GetSurfaceHeight(x, z),
        z
    }

    for k, _ in found do
        found[k] = nil
    end

    for k , _ in candidates do
        candidates[k] = nil
    end

    return waypoint
end

local DirectionToPath = { }

--- Computes a waypoint that represents the direction towards a destination
---@param layer NavLayers
---@param origin Vector
---@param destination Vector
---@return Vector?              
---@return ('SystemError' | 'NotGenerated' | 'InvalidLayer' | 'OutsideMap' | 'OriginOutsideMap' | 'OriginUnpathable' | 'DestinationOutsideMap' | 'DestinationUnpathable' | 'Unpathable') | number      
function DirectionTo(layer, origin, destination, distance)
    -- check if generated
    if not NavGenerator.IsGenerated() then
        return nil, 'NotGenerated'
    end

    -- check if we can path
    local ok, msg = CanPathTo(layer, origin, destination)
    if not ok then
        return nil, msg
    end

    -- setup pathing
    local seenIdentifier = PathToGetUniqueIdentifier()
    local grid = FindGrid(layer)                        --[[@as NavGrid]]
    local originLeaf = FindLeaf(grid, origin)           --[[@as NavLeaf]]
    local destinationLeaf = FindLeaf(grid, destination) --[[@as NavLeaf]]

    -- 0th iteration of search
    originLeaf.From = nil
    originLeaf.AcquiredCosts = 0
    originLeaf.TotalCosts = DistanceTo(originLeaf, destinationLeaf)
    originLeaf.Seen = seenIdentifier

    -- start using the navigational heap
    PathToHeap:Clear()
    PathToHeap:Insert(originLeaf)

    destinationLeaf.From = nil
    destinationLeaf.AcquiredCosts = 0
    destinationLeaf.TotalCosts = 0
    destinationLeaf.Seen = 0

    -- search iterations
    while not PathToHeap:IsEmpty() do

        local leaf = PathToHeap:ExtractMin() --[[@as NavLeaf]]

        -- final state
        if leaf == destinationLeaf then
            break
        end

        -- continue state
        for k = 1, TableGetn(leaf) do
            local neighbor = NavGenerator.NavCells[leaf[k]]
            if neighbor.Label > 0 and neighbor.Seen != seenIdentifier then
                local preferLargeNeighbor = 0
                if leaf.Size > neighbor.Size then
                    preferLargeNeighbor = 100
                end
                neighbor.From = leaf
                neighbor.Seen = seenIdentifier
                neighbor.AcquiredCosts = leaf.AcquiredCosts + DistanceTo(leaf, neighbor) + 2 + preferLargeNeighbor
                neighbor.TotalCosts = neighbor.AcquiredCosts + 0.25 * DistanceTo(destinationLeaf, neighbor)

                PathToHeap:Insert(neighbor)
            end
        end
    end

    -- check if we found a path
    if not destinationLeaf.Seen == seenIdentifier then
        return nil, 'SystemError'
    end

    -- construct current path
    local head = 1
    local path = DirectionToPath
    local length = 0
    local leaf = destinationLeaf
    while leaf.From and leaf.From != leaf do

        -- add to path
        local waypoint = path[head] or { }
        path[head] = waypoint
        head = head + 1

        waypoint[1] = leaf.px
        waypoint[2] = 0
        waypoint[3] = leaf.pz

        -- keep track of distance
        length = length + DistanceTo(leaf, leaf.From)

        -- continue down the tree
        leaf = leaf.From
    end

    -- add origin to the list
    local waypoint = path[head] or { }
    path[head] = waypoint
    waypoint[1] = originLeaf.px
    waypoint[2] = 0
    waypoint[3] = originLeaf.pz

    -- total path length is too short
    if length <= distance then
        return destination, length
    end

    -- not enough steps, likely a line
    if head <= 2 then
        return destination, length
    end

    -- determine waypoint to pass back
    local lastWaypoint = origin
    local taken = 0
    local output = { destination[1], destination[2], destination[3] }

    -- traverse the path
    for k = head, 2, -1 do

        local waypoint = path[k]
        local dx = waypoint[1] - lastWaypoint[1]
        local dz = waypoint[3] - lastWaypoint[3]
        local d = MathSqrt(dx * dx + dz * dz)

        if d + taken < distance then
            taken = taken + d
            lastWaypoint = waypoint
        else
            output[1] = waypoint[1]
            output[3] = waypoint[3]
            output[2] = GetSurfaceHeight(output[1], output[3])

            break
        end

        lastWaypoint = waypoint
    end

    return output, distance
end

--- Returns true when the origin is in the playable area
---@param origin Vector
---@param offset number | nil
---@return boolean
function IsInPlayableArea(origin, offset)
    offset = offset or 0

    -- determine playable area
    local playableArea = ScenarioInfo.MapData.PlayableRect
    local tlx, tlz, brx, brz
    if playableArea then
        tlx = playableArea[1]
        tlz = playableArea[2]
        brx = playableArea[3]
        brz = playableArea[4]
    else
        tlx = 0
        tlz = 0
        brx = ScenarioInfo.size[1]
        brz = ScenarioInfo.size[2]
    end

    -- take into account offset
    tlx = tlx + offset
    tlz = tlz + offset
    brx = brx - offset
    brz = brz - offset

    local x = origin[1]
    local z = origin[3]

    return (tlx <= x and brx >= x) and (tlz <= z and brz >= z)
end

--- Returns true when the origin is in the buildable area
---@param origin Vector
---@return boolean
function IsInBuildableArea(origin)
    return IsInPlayableArea(origin, 8)
end

