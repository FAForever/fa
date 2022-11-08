
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
local NavGenerator = import("/lua/sim/navgenerator.lua")
local NavDatastructures = import("/lua/sim/navdatastructures.lua")

--- Returns true if the navigational mesh is generated
---@return boolean
function IsGenerated()
    return NavGenerator.IsGenerated()
end

--- Returns true when you can path from the origin to the destination
---@param layer NavLayers
---@param origin Vector
---@param destination Vector
---@return boolean?
---@return string?
function CanPathTo(layer, origin, destination)

    -- check layer argument
    local root = NavGenerator.NavGrids[layer] --[[@as NavGrid]]
    if not root then
        return nil, 'Invalid layer type - this is likely a typo. The layer is case sensitive'
    end

    -- check origin argument
    local originLeaf = root:FindLeafXZ(origin[1], origin[3])
    if not originLeaf then
        return nil, 'Origin is not inside the map'
    end

    if originLeaf.label == -1 then
        return nil, 'Origin is unpathable'
    end

    if originLeaf.label == 0 then
        return nil, 'Origin has no label assigned, report to the maintainers. This should not be possible'
    end

    -- check destination argument
    local destinationLeaf = root:FindLeafXZ(destination[1], destination[3])
    if not destinationLeaf then
        return nil, 'Destination is not inside the map'
    end

    if destinationLeaf.label == -1 then
        return nil, 'Destination is unpathable'
    end

    if destinationLeaf.label == 0 then
        return nil, 'Destination has no label assigned, report to the maintainers. This should not be possible'
    end

    if originLeaf.label == destinationLeaf.label then
        return true
    else
        return false, 'Not reachable for this layer'
    end
end

---@type NavPathToHeap
local PathToHeap = NavDatastructures.NavPathToHeap()

---@type number
local PathToIdentifier = 1

---@return number
local function PathToGetUniqueIdentifier()
    PathToIdentifier = PathToIdentifier + 1
    return PathToIdentifier
end

---@class NavPathToOptions
local PathToOptions = {
    UseCache = false
}

--- Retrieves a shallow copy of the default options
---@return NavPathToOptions
function PathToDefaultOptions()
    PathToOptions.StepSize = 0
    PathToOptions.IncludeOrigin = false
    PathToOptions.IncludeDestination = true
    PathToOptions.Simplify = true

    return PathToOptions
end

--- Returns true when you can path from the origin to the destination
---@param layer NavLayers
---@param origin Vector
---@param destination Vector
---@param options NavPathToOptions
---@return Vector[]?            # List of positions
---@return (string | number)?   # Error message, or the number of positions
---@return number?              # Length of path
function PathTo(layer, origin, destination, options)

    -- check if we can path
    local ok, msg = CanPathTo(layer, origin, destination)
    if not ok then
        return nil, msg
    end

    -- setup pathing

    local seenIdentifier = PathToGetUniqueIdentifier()
    local root = NavGenerator.NavGrids[layer] --[[@as NavGrid]]
    local originLeaf = root:FindLeafXZ(origin[1], origin[3]) --[[@as CompressedLabelTreeLeaf]]
    local destinationLeaf = root:FindLeafXZ(destination[1], destination[3]) --[[@as CompressedLabelTreeLeaf]]

    -- 0th iteration of search

    originLeaf.From = nil
    originLeaf.AcquiredCosts = 0
    originLeaf.ExpectedCosts = originLeaf:DistanceTo(destinationLeaf)
    originLeaf.Seen = seenIdentifier
    PathToHeap:Insert(originLeaf)

    destinationLeaf.From = nil
    destinationLeaf.AcquiredCosts = 0
    destinationLeaf.ExpectedCosts = 0
    destinationLeaf.Seen = 0

    -- search iterations

    while not PathToHeap:IsEmpty() do

        local leaf = PathToHeap:ExtractMin() --[[@as CompressedLabelTreeLeaf]]

        -- final state
        if leaf == destinationLeaf then
            break
        end

        -- continue state
        for id, neighbor in leaf.neighbors do
            if neighbor.Seen != seenIdentifier then
                local preferLargeNeighbor = 0
                if leaf.c > neighbor.c then
                    preferLargeNeighbor = 100
                end
                neighbor.From = leaf
                neighbor.Seen = seenIdentifier
                neighbor.AcquiredCosts = leaf.AcquiredCosts + leaf.neighborDistances[id] + 2 + preferLargeNeighbor
                neighbor.ExpectedCosts = 0.25 * destinationLeaf:DistanceTo(neighbor)

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
        return nil, 'Did not manage to find the destination'
    end

    -- construct current path

    local head = 1
    local path = { }
    local distance = 0
    local leaf = destinationLeaf.From
    while leaf.From and leaf.From != leaf do

        -- add to path
        path[head] = {
            leaf.px,
            GetSurfaceHeight(leaf.px, leaf.pz),
            leaf.pz
        }
        head = head + 1

        -- keep track of distance
        distance = distance + leaf.From.neighborDistances[leaf.identifier]
        
        -- continue down the tree
        leaf = leaf.From
    end

    -- reverse the path

    for k = 1, (0.5 * head) ^ 0 do
        local temp = path[k]
        path[k] = path[head - k]
        path[head - k] = temp
    end

    -- add destination to the path

    path[head] = destination

    -- clear up after ourselves

    PathToHeap:Clear()

    -- return all the goodies!!

    return path, head, distance
end

--- Returns a label that indicates to what sub-graph it belongs to, these graphs can be visualised using the Nav UI
---@param layer NavLayers
---@param position Vector
---@return number? 
---@return string?
function GetLabel(layer, position)
    -- check layer argument
    local root = NavGenerator.NavGrids[layer] --[[@as NavGrid]]
    if not root then
        return nil, 'Invalid layer type - this is likely a typo. The layer is case sensitive'
    end

    -- check position argument
    local leaf = root:FindLeafXZ(position[1], position[3])
    if not leaf then
        return nil, 'Position is not inside the map'
    end

    if leaf.label == 0 then
        return nil, 'Position has no label assigned, report to the maintainers. This should not be possible'
    end

    if leaf.label == -1 then
        return nil, 'Position is unpathable'
    end

    return leaf.label, nil
end
