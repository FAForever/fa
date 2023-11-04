
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
local function DebugRegisterPath(type, path, origin, destination)
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

local function DebugPathRender()
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

---@type NavHeap
local PathToHeap = NavDatastructures.NavHeap()

---@type number
local PathToIdentifier = 1

---@return number
local function PathToGetUniqueIdentifier()
    PathToIdentifier = PathToIdentifier + 1
    return PathToIdentifier
end

---@param a NavSection
---@param b NavSection
---@return number
local SquaredDistanceTo = function(a, b)
    local dx = a.Center[1] - b.Center[1]
    local dz = a.Center[3] - b.Center[3]
    return dx * dx + dz * dz
end

---@param a NavSection
---@param b NavSection
---@return number
local DistanceTo = function(a, b)
    local dx = a.Center[1] - b.Center[1]
    local dz = a.Center[3] - b.Center[3]
    return MathSqrt(dx * dx + dz * dz)
end

---@param grid NavGrid
---@param position Vector A position in world space
---@return NavTree?
local FindRoot = function(grid, position)
    return grid:FindRootXZ(position[1], position[3])
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
---@param x number
---@param z number
---@return boolean | nil
---@return 'OutsideMap' | nil
local function FreeOfObstaclesXZ(grid, label, x, z)
    -- check position argument
    local leaf = grid:FindLeafXZ(x, z)
    if not leaf then
        return nil, 'OutsideMap'
    end

    -- we're an obstacle
    if leaf.Label == -1 then
        return false
    end

    -- we're very close to an obstacle
    if leaf.Size <= 4 then
        return false
    end

    -- we're big and therefore likely far away from an obstacle
    if leaf.Size >= 32 then
        return true
    end

    -- find obstacles nearby
    local NavLeaves = NavGenerator.NavLeaves
    for k = 1, TableGetn(leaf) do
        local neighbor = NavLeaves[leaf[k]]

        -- confirm we're nearby the neighbor
        local dx = neighbor.px - x
        local dz = neighbor.pz - z
        if dx * dx + dz * dz < 256 then
            -- neighbor is an obstacle
            if neighbor.Label == -1 then
                return false
            end

            -- small neighbor therefore an obstacle is nearby
            if neighbor.Size <= 4 then
                return false
            end
        end
    end

    return true
end

---@param grid NavGrid
---@param position Vector
---@return boolean | nil
---@return 'OutsideMap' | nil
local function FreeOfObstacles(grid, label, position)
    return FreeOfObstaclesXZ(grid, label, position[1], position[3])
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
            local neighbor = NavGenerator.NavLeaves[leaf[k]]
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

---@param grid NavGrid
---@param position Vector
---@return NavSection | nil
---@return 'OutsideMap' | nil
local function FindSection(grid, position)
    local leaf, msg = FindLeaf(grid, position)
    if not leaf then
        return nil, msg
    end

    return NavGenerator.NavSections[leaf.Section]
end

---@param grid NavGrid
---@param position Vector
---@param distance number
---@return Vector[] | nil
---@return number | ('NotGenerated'| 'OutsideMap' | 'NoResults')?
local function FindSections(grid, position, distance)
    -- check if generated
    if not NavGenerator.IsGenerated() then
        return nil, 'NotGenerated'
    end

    -- setup pathing
    local seenIdentifier = PathToGetUniqueIdentifier()
    local sectionOrigin = FindSection(grid, position)

    -- sanity check
    if not sectionOrigin then
        return nil, 'OutsideMap'
    end

    -- local scope for performance
    -- local scope for performance
    local NavSections = NavGenerator.NavSections
    local ox = position[1]
    local oz = position[3]

    -- 0th iteration of search
    sectionOrigin.HeapIdentifier = seenIdentifier

    local current = 1
    local stack = { sectionOrigin }
    local candidates = { sectionOrigin.Center }

    while current > 0 do
        local section = stack[current]
        current = current - 1

        -- look for the neighbors
        local neighbors = section.Neighbors
        for k = 1, TableGetn(neighbors) do
            local neighbor = NavSections[neighbors[k]]
            if neighbor.HeapIdentifier != seenIdentifier then
                neighbor.HeapIdentifier = seenIdentifier

                candidates[neighbor.Identifier] = neighbor.Center

                -- if neighbor exceeds the distance then we pick the neighbor
                local dx = ox - neighbor.Center[1]
                local dz = oz - neighbor.Center[3]
                if MathSqrt(dx * dx + dz * dz) < distance then
                    -- always include it
                    current = current + 1
                    stack[current] = neighbor
                end
            end
        end
    end

    local head = 1

    ---@type Vector[]
    local positions = { }
    for _, center in candidates do
        positions[head] = center
        head = head + 1
    end

    if head == 1 then
        return nil, 'NoResults'
    end

    return positions, head - 1
end


---@param destination NavSection 
---@param cache? NavSection[]
---@return Vector[]
---@return number   # Number of points in path
local function TracePath(destination, cache)

    -- local scope for performance
    local NavSections = NavGenerator.NavSections

    ---@type number
    local head = 1

    ---@type NavSection[]
    local cache = cache or { }

    ---@type NavSection | nil
    local section = NavSections[destination.HeapFrom]

    -- trace path from destination
    while true do
        if not section then
            break
        end

        local sectionFrom = NavSections[section.HeapFrom]
        if sectionFrom and sectionFrom == destination then
            break
        end

        cache[head] = section
        head = head + 1

        section = sectionFrom
    end

    -- reverse the path
    for k = 1, (0.5 * head) ^ 0 do
        local temp = cache[k]
        cache[k] = cache[head - k]
        cache[head - k] = temp
    end

    cache[head] = destination

    return cache, head
end

---@param grid NavGrid
---@param label NavLabelIdentifier
---@param origin NavSection
---@param destination Vector
---@param sections NavSection[]
---@param count number
local function PathToPositions(grid, label, origin, destination, sections, count)
    ---@type number
    local distance = 0

    ---@type Vector[]
    local positions = {  }

    -- turn the path into positions
    local sectionLast = origin
    for k = 2, count do
        local sectionNext = sections[k]
        distance = distance + DistanceTo(sectionLast, sectionNext)

        if k > 1 then
            positions[k - 1] = { unpack(sectionNext.Center) }
        end
    end

    -- add in the destination
    local count = count - 1
    positions[count] = destination

    -- basic path smoothing
    if count > 3 then
        for k = 2, count - 1 do
            local positionPrev = positions[k - 1]
            local positionCurr = positions[k]
            local positionNext = positions[k + 1]

            local pax = 0.5 * (positionPrev[1] + positionNext[1])
            local paz = 0.5 * (positionPrev[3] + positionNext[3])

            if FreeOfObstaclesXZ(grid, label, pax, paz) then
                positionCurr[1] = pax
                positionCurr[2] = GetSurfaceHeight(pax, paz)
                positionCurr[3] = paz
            else
                local px = 0.5 * pax + 0.5 * positionCurr[1]
                local pz = 0.5 * paz + 0.5 * positionCurr[3]

                if FreeOfObstaclesXZ(grid, label, px, pz) then
                    positionCurr[1] = px
                    positionCurr[2] = GetSurfaceHeight(px, pz)
                    positionCurr[3] = pz
                end
            end
        end
    end

    return positions, count, distance
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

    -- local scope for performance
    local NavSections = NavGenerator.NavSections

    -- setup pathing
    local seenIdentifier = PathToGetUniqueIdentifier()
    local grid = FindGrid(layer)                                --[[@as NavGrid]]
    local originSection = FindSection(grid, origin)             --[[@as NavSection]]
    local destinationSection = FindSection(grid, destination)   --[[@as NavSection]]

    -- 0th iteration of search
    originSection.HeapFrom = nil
    originSection.HeapAcquiredCosts = 0
    originSection.HeapTotalCosts = DistanceTo(originSection, destinationSection)
    originSection.HeapIdentifier = seenIdentifier

    -- start using the navigational heap
    PathToHeap:Clear()
    PathToHeap:Insert(originSection)

    destinationSection.HeapFrom = nil
    destinationSection.HeapAcquiredCosts = 0
    destinationSection.HeapTotalCosts = 0
    destinationSection.HeapIdentifier = 0

    -- search iterations
    while not PathToHeap:IsEmpty() do

        local section = PathToHeap:ExtractMin() --[[@as NavSection]]

        -- final state
        if section == destinationSection then
            break
        end

        local neighbors = section.Neighbors

        -- continue state
        for k = 1, TableGetn(neighbors) do
            local neighbor = NavSections[neighbors[k]]
            if neighbor.Label > 0 and neighbor.HeapIdentifier != seenIdentifier then
                neighbor.HeapIdentifier = seenIdentifier
                neighbor.HeapFrom = section.Identifier
                neighbor.HeapAcquiredCosts = section.HeapAcquiredCosts + DistanceTo(section, neighbor)
                neighbor.HeapTotalCosts = neighbor.HeapAcquiredCosts + DistanceTo(destinationSection, neighbor)
                PathToHeap:Insert(neighbor)
            end
        end
    end

    -- check if we found a path
    if not destinationSection.HeapIdentifier == seenIdentifier then
        return nil, 'SystemError'
    end

    local sections, sectionCount = TracePath(destinationSection)
    local positions, positionCount, distance = PathToPositions(grid, originSection.Label, originSection, destination, sections, sectionCount)

    -- debugging!
    DebugRegisterPath('PathTo', positions, origin, destination)

    -- return all the goodies!!
    return positions, positionCount, distance
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
---@return (number | ('SystemError' | 'NotGenerated' | 'InvalidLayer' | 'OutsideMap' | 'OriginOutsideMap' | 'OriginUnpathable' | 'DestinationOutsideMap' | 'DestinationUnpathable' | 'Unpathable' | 'NoResults' | 'TooMuchThreat')?   # Error message, or the number of positions
---@return number?  # Length of path
---@return BrainPositionThreat[]? # all locations with their threat that is at least the threat threshold
---@return number? # number of threat found
function PathToWithThreatThreshold(layer, origin, destination, aibrain, threatFunc, threatThreshold, threatRadius)
    -- check if generated
    if not NavGenerator.IsGenerated() then
        return nil, 'NotGenerated', nil, nil, nil
    end

    -- check if we can path
    local ok, msg = CanPathTo(layer, origin, destination)
    if not ok then
        return nil, msg, nil, nil, nil
    end

    -- local scope for performance
    local NavSections = NavGenerator.NavSections

    -- setup pathing
    local seenIdentifier = PathToGetUniqueIdentifier()
    local grid = FindGrid(layer)                                --[[@as NavGrid]]
    local originSection = FindSection(grid, origin)             --[[@as NavSection]]
    local destinationSection = FindSection(grid, destination)   --[[@as NavSection]]

    -- 0th iteration of search
    originSection.HeapFrom = nil
    originSection.HeapAcquiredCosts = 0
    originSection.HeapTotalCosts = DistanceTo(originSection, destinationSection)
    originSection.HeapIdentifier = seenIdentifier

    -- start using the navigational heap
    PathToHeap:Clear()
    PathToHeap:Insert(originSection)

    destinationSection.HeapFrom = nil
    destinationSection.HeapAcquiredCosts = 0
    destinationSection.HeapTotalCosts = 0
    destinationSection.HeapIdentifier = 0

    local tHead = 1
    ---@type BrainPositionThreat[]
    local threats = { }

    -- search iterations
    while not PathToHeap:IsEmpty() do

        local section = PathToHeap:ExtractMin() --[[@as NavSection]]

        -- final state
        if section == destinationSection then
            break
        end

        local neighbors = section.Neighbors

        -- continue state
        for k = 1, TableGetn(neighbors) do
            local neighbor = NavSections[neighbors[k]]
            local threat = threatFunc(aibrain, neighbor.Center, threatRadius)
            if neighbor.Label > 0 and neighbor.HeapIdentifier != seenIdentifier then
                if threat > threatThreshold then
                    neighbor.HeapIdentifier = seenIdentifier

                    threats[tHead] = { neighbor.Center[1], neighbor.Center[3], threat }
                    tHead = tHead + 1
                else
                    neighbor.HeapIdentifier = seenIdentifier
                    neighbor.HeapFrom = section.Identifier
                    neighbor.HeapAcquiredCosts = section.HeapAcquiredCosts + DistanceTo(section, neighbor)
                    neighbor.HeapTotalCosts = neighbor.HeapAcquiredCosts + DistanceTo(destinationSection, neighbor)
                    PathToHeap:Insert(neighbor)
                end
            end
        end
    end

    -- check if we found a path
    if destinationSection.HeapIdentifier ~= seenIdentifier then
        return nil, 'TooMuchThreat', nil, threats, tHead - 1
    end

    local sections, sectionCount = TracePath(destinationSection)
    local positions, positionCount, distance = PathToPositions(grid, originSection.Label, originSection, destination, sections, sectionCount)

    -- debugging!
    DebugRegisterPath('PathTo', positions, origin, destination)

    -- return all the goodies!!
    return positions, positionCount, distance, threats, tHead - 1
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
---@param x number
---@param z number
---@return number? 
---@return ('NotGenerated' | 'InvalidLayer' | 'OutsideMap' | 'SystemError' | 'Unpathable')?
function GetTerrainLabelXZ(layer, x, z)
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
    local leaf = grid:FindLeafXZ(x, z)
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

--- Returns a label that indicates to what sub-graph it belongs to. Unlike `GetLabel` this function does not try to find valid neighbors
---@see GetLabel
---@param layer NavLayers
---@param position Vector
---@return number? 
---@return ('NotGenerated' | 'InvalidLayer' | 'OutsideMap' | 'SystemError' | 'Unpathable')?
function GetTerrainLabel(layer, position)
    return GetTerrainLabelXZ(layer, position[1], position[3])
end

---@type NavTree[]
local GetPositionsInRadiusCandidates = {}
local GenericResultsCache = { }
local GenericQueueCache = { }

---@param layer NavLayers
---@param position Vector
---@param distance number
---@param thresholdSize? number
---@return Vector[] | nil
---@return number | ('NotGenerated' | 'InvalidLayer' | 'OutsideMap' | 'SystemError' | 'Unpathable' | 'NoData')?
function GetPositionsInRadius(layer, position, distance, thresholdSize, cache)

    -- check layer argument
    local grid = FindGrid(layer)
    if not grid then
        return nil, 'InvalidLayer'
    end

    local gridAir = FindGrid('Air')
    if not gridAir then
        return nil, 'SystemError'
    end

    -- find surrounding points of interest
    local points, count = FindSections(gridAir, position, distance)
    if not points then
        local msg = count --[[@as string]]
        return nil, msg
    end

    -- use the cache
    local head = 1
    cache = cache or { }

    for k, point in points do
        local section = FindSection(grid, point)
        if not section then
            continue
        end

        cache[head] = section.Center
        head = head + 1
    end

    -- clean up remainder of the cache
    for k = head, TableGetn(cache) do
        cache[k] = nil
    end

    if head == 1 then
        return nil, 'NoResults'
    end

    return cache, head - 1
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

--- Computes a list of waypoints that represent random directions that we can navigate to
---@param layer NavLayers
---@param origin Vector
---@param distance number
---@return Vector[] | nil
---@return number | ('NotGenerated' | 'OutsideMap' | 'NoResults' | 'InvalidLayer')
function DirectionsFrom(layer, origin, distance)
    -- check if generated
    if not NavGenerator.IsGenerated() then
        return nil, 'NotGenerated'
    end

    -- sanity check on the grid
    local grid = FindGrid(layer)
    if not grid then
        return nil, 'InvalidLayer'
    end

    -- compute directions
    local points, count = FindSections(grid, origin, distance)
    if not points then
        local msg = count --[[@as string]]
        return nil, msg
    end

    -- only keep those at the edge
    local ox = origin[1]
    local oz = origin[3]
    local ds = distance * distance
    local head = 1
    for k = 1, count do

        local point = points[k]
        local dx = ox - point[1]
        local dz = oz - point[3]

        if dx * dx + dz * dz > ds then
            points[head] = point
            head = head + 1
        end
    end

    if head == 1 then
        return nil, 'NoResults'
    end

    -- clear out remaining points
    for k = count, head, -1 do
        points[k] = nil
    end

    return points, head - 1
end

--- Computes a list of waypoints that represent random directions that we can navigate to
---@param layer NavLayers
---@param origin Vector
---@param distance number
---@param aibrain AIBrain
---@param threatFunc fun(aiBrain: AIBrain, position: Vector, radius: number) : number
---@param threatThreshold number
---@param threatRadius number
---@return Vector[] | nil
---@return number | ('NotGenerated' | 'OutsideMap' | 'NoResults' | 'InvalidLayer' | 'TooMuchThreat')
---@return BrainPositionThreat[]? # all locations with their threat that is at least the threat threshold
---@return number? # number of threat found
function DirectionsFromWithThreatThreshold(layer, origin, distance, aibrain, threatFunc, threatThreshold, threatRadius)
    -- check if generated
    if not NavGenerator.IsGenerated() then
        return nil, 'NotGenerated', nil, nil
    end

    -- sanity check on the grid
    local grid = FindGrid(layer)
    if not grid then
        return nil, 'InvalidLayer', nil, nil
    end

    -- compute directions
    local points, count = FindSections(grid, origin, distance)
    if not points then
        local msg = count --[[@as string]]
        return nil, msg, nil, nil
    end

    -- no locations found
    if count == 0 then
        return nil, 'NoResults', nil, nil
    end

    local tHead = 1
    ---@type BrainPositionThreat[]
    local threats = { }

    local head = 1
    for k = 1, count do
        local point = points[k]
        local threat = threatFunc(aibrain, point, threatRadius)
        if threat < threatThreshold then
            points[head] = point
            head = head + 1
        else
            threats[tHead] = { point[1], point[3], threat }
            tHead = tHead + 1
        end
    end

    -- clear out remaining points
    if head == 1 then
        return nil, 'TooMuchThreat', threats, tHead - 1
    end

    for k = head, count do
        points[k] = nil
    end

    return points, head - 1, threats, tHead - 1
end

--- Computes a waypoint that represents a random direction that we can navigate to
---@param layer NavLayers
---@param origin Vector
---@param distance number
---@return Vector | nil
---@return ('NotGenerated' | 'OutsideMap' | 'NoResults')?
function RandomDirectionFrom(layer, origin, distance)
    -- TODO: use a cache as we're not interested in all the positions
    local positions, count = DirectionsFrom(layer, origin, distance)

    if not positions then
        local msg = count --[[@as ('NotGenerated' | 'OutsideMap' | 'NoResults')]]
        return nil, msg
    end

    local total = count --[[@as number]]
    return positions[Random(1, total)]
end

--- Computes a waypoint that represents a retreat direction that is a valid location to path to
---@param layer NavLayers
---@param origin Vector
---@param threat Vector
---@param distance number
---@return Vector | nil
---@return ('NotGenerated' | 'OutsideMap' | 'NoResults')?
function RetreatDirectionFrom(layer, origin, threat, distance)
    -- TODO: use a cache as we're not interested in all the positions
    local positions, count = DirectionsFrom(layer, origin, distance)

    if not positions then
        local msg = count --[[@as ('NotGenerated' | 'OutsideMap' | 'NoResults')]]
        return nil, msg
    end

    -- find best retreat direction
    local ox = origin[1]
    local oz = origin[3]

    local tx = threat[1] - ox
    local tz = threat[3] - oz

    local dt = 1 / MathSqrt(tx * tx + tz * tz)
    tx = tx * dt
    tz = tz * dt

    local lowest = 1000
    local result = positions[1]

    for k, position in positions do
        local px = position[1]
        local pz = position[3]

        local dx = px - ox
        local dz = pz - oz

        local d = MathSqrt(dx * dx + dz * dz)
        local di = 1 / d

        local nx = di * dx
        local nz = di * dz

        local radians = nx * tx + nz * tz
        if radians < lowest then
            lowest = radians
            result = position
        end
    end

    return result
end

--- Computes a waypoint that represents the direction towards a destination
---@param layer NavLayers
---@param origin Vector
---@param destination Vector
---@return Vector?              
---@return ('SystemError' | 'NotGenerated' | 'InvalidLayer' | 'OutsideMap' | 'OriginOutsideMap' | 'OriginUnpathable' | 'DestinationOutsideMap' | 'DestinationUnpathable' | 'Unpathable') | number      
function DirectionTo(layer, origin, destination, distance)
    local path, count, length = PathTo(layer, origin, destination)

    if not path then
        return nil, count
    end

    -- too close to the destination
    if length < distance then
        return destination, length
    end

    -- try to match the distance that we intend to move
    local toTravel = distance
    local curr = origin
    for k = 1, count do
        local next = path[k]
        local dx = curr[1] - next[1]
        local dz = curr[3] - next[3]
        local d = MathSqrt(dx * dx + dz * dz)

        if toTravel > d then
            toTravel = toTravel - d
        else
            local factor = toTravel / d
            local px = (1 - factor) * curr[1] + (factor) * next[1]
            local pz = (1 - factor) * curr[3] + (factor) * next[3]
            return {
                px,
                GetSurfaceHeight(px, pz),
                pz
            }, distance
        end

        curr = next
    end

    -- fallback that should never happen
    return destination, distance
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

