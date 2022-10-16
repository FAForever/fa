
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

local Shared = import('/lua/shared/NavGenerator.lua')
local NavGenerator = import('/lua/sim/NavGenerator.lua')
local NavDatastructures = import('/lua/sim/NavDatastructures.lua')

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
    StepSize = 0,

    IncludeOrigin = false,
    IncludeDestination = true,
    Simplify = true,
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
---@return boolean?
---@return string?
function PathTo(layer, origin, destination, options)

    -- check if we can path
    local ok, msg = CanPathTo(layer, origin, destination)
    if not ok then
        return ok, msg
    end

    -- setup pathing
    local seenIdentifier = PathToGetUniqueIdentifier()
    local root = NavGenerator.NavGrids[layer] --[[@as NavGrid]]
    local originLeaf = root:FindLeafXZ(origin[1], origin[3]) --[[@as LabelTree]]
    local destinationLeaf = root:FindLeafXZ(destination[1], destination[3]) --[[@as LabelTree]]

    return false

end