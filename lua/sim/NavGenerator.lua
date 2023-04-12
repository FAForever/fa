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
local MarkerGenerator = import("/lua/sim/markergenerator.lua")

---@alias NavTerrainCache number[][]
---@alias NavDepthCache number[][]
---@alias NavAverageDepthCache number[][]
---@alias NavHorizontalPathCache boolean[][]
---@alias NavVerticalPathCache boolean[][]
---@alias NavPathCache boolean[][]
---@alias NavTerrainBlockCache boolean[][]
---@alias NavLabelCache number[][]

--- TODO: should this be dynamic, based on playable area?
--- Number of blocks that encompass the map, per axis
---@type number
local LabelCompressionTreesPerAxis = 16

--- Maximum height difference that is considered to be pathable, within a single oGrid
---@type number
local MaxHeightDifference = 0.75

--- Maximum depth that amphibious units consider to be pathable
---@type number
local MaxWaterDepthAmphibious = 25

--- Minimum dept that Naval units consider to be pathable
---@type number
local MinWaterDepthNaval = 1.5

local TableInsert = table.insert
local HashCache = {}

-- Generated data

---@class NavGrids
---@field Land? NavGrid
---@field Water? NavGrid
---@field Hover? NavGrid
---@field Amphibious? NavGrid
---@field Air? NavGrid
NavGrids = {}

---@class NavLabelMetadata
---@field Node CompressedLabelTreeLeaf
---@field Area number
---@field Layer NavLayers
---@field NumberOfExtractors number
---@field NumberOfHydrocarbons number
---@field ExtractorMarkers MarkerResource[]
---@field HydrocarbonMarkers MarkerResource[]

---@type table<number, NavLabelMetadata>
NavLabels = {}

local Generated = false
---@return boolean
function IsGenerated()
    return Generated
end

local LabelIdentifier = 0
---@return number
local function GenerateLabelIdentifier()
    LabelIdentifier = LabelIdentifier + 1
    return LabelIdentifier
end

-- Shared data with UI

---@type NavLayerData
NavLayerData = Shared.CreateEmptyNavLayerData()

local tl = { 0, 0, 0 }
local tr = { 0, 0, 0 }
local bl = { 0, 0, 0 }
local br = { 0, 0, 0 }

--- Draws a square on the map
---@param px number
---@param pz number
---@param c number
---@param color string
function DrawSquare(px, pz, c, color, inset)
    inset = inset or 0
    tl[1], tl[2], tl[3] = px + inset, GetSurfaceHeight(px + inset, pz + inset), pz + inset
    tr[1], tr[2], tr[3] = px + c - inset, GetSurfaceHeight(px + c - inset, pz + inset), pz + inset
    bl[1], bl[2], bl[3] = px + inset, GetSurfaceHeight(px + inset, pz + c - inset), pz + c - inset
    br[1], br[2], br[3] = px + c - inset, GetSurfaceHeight(px + c - inset, pz + c - inset), pz + c - inset

    DrawLine(tl, tr, color)
    DrawLine(tl, bl, color)
    DrawLine(br, bl, color)
    DrawLine(br, tr, color)
end

local FactoryNavGrid = {
    __call = function(self, layer, treeSize)
        local instance = {&3 &0}
        setmetatable(instance, self)
        instance:OnCreate(layer, treeSize)
        return instance
    end
}

---@generic T: fa-class
---@param specs T
---@return T
local ClassNavGrid = function(specs)
    specs.__index = specs
    return setmetatable(specs, FactoryNavGrid)
end

---@class NavGrid
---@field Layer NavLayers
---@field TreeSize number
---@field Trees CompressedLabelTreeNode[][]
NavGrid = ClassNavGrid {

    ---@param self NavGrid
    ---@param layer NavLayers
    OnCreate = function(self, layer, treeSize)
        self.Layer = layer
        self.TreeSize = treeSize
        self.Trees = {&0 &16}
        for z = 0, LabelCompressionTreesPerAxis - 1 do
            self.Trees[z] = {&0 &16}
        end
    end,

    Simplify = function(self)
        for z = 0, LabelCompressionTreesPerAxis - 1 do
            for x = 0, LabelCompressionTreesPerAxis - 1 do
                self.Trees[z][x]:Simplify()
            end
        end
    end,

    --- Adds a compressed label tree to the navigational grid
    ---@param self NavGrid
    ---@param z number index
    ---@param x number index
    ---@param labelTree CompressedLabelTreeNode
    AddTree = function(self, z, x, labelTree)
        self.Trees[z][x] = labelTree
    end,

    --- Returns the leaf that encompasses the position, or nil if no leaf does
    ---@param self NavGrid
    ---@param position Vector A position in world space
    ---@return CompressedLabelTreeLeaf?
    FindLeaf = function(self, position)
        return self:FindLeafXZ(position[1], position[3])
    end,

    --- Returns the leaf that encompasses the x / z coordinates, or nil if no leaf does
    ---@param self NavGrid
    ---@param x number x-coordinate, in world space
    ---@param z number z-coordinate, in world space
    ---@return CompressedLabelTreeLeaf?
    FindLeafXZ = function(self, x, z)
        if x > 0 and z > 0 then

            local size = self.TreeSize
            local trees = self.Trees

            local bx = (x / size) ^ 0
            local bz = (z / size) ^ 0
            local labelTree = trees[bz][bx]
            if labelTree then
                return labelTree:FindLeafXZ(bx * size, bz * size, 0, 0, size, x, z)
            end
        end

        return nil
    end,

    ---@param self NavGrid
    GenerateNeighbors = function(self)
        local size = self.TreeSize
        local trees = self.Trees
        for z = 0, LabelCompressionTreesPerAxis - 1 do
            for x = 0, LabelCompressionTreesPerAxis - 1 do
                trees[z][x]:GenerateDirectNeighbors(x * size, z * size, 0, 0, size, self, self.Layer)
            end
        end
    end,

    ---@param self NavGrid
    GenerateLabels = function(self)
        local labelStart = LabelIdentifier
        local stack = {}
        for z = 0, LabelCompressionTreesPerAxis - 1 do
            for x = 0, LabelCompressionTreesPerAxis - 1 do
                self.Trees[z][x]:GenerateLabels(stack, self.Layer)
            end
        end

        local labelEnd = LabelIdentifier
        NavLayerData[self.Layer].Labels = labelEnd - labelStart
    end,

    ---@param self NavGrid
    Precompute = function(self)
        local size = self.TreeSize
        local trees = self.Trees
        for z = 0, LabelCompressionTreesPerAxis - 1 do
            for x = 0, LabelCompressionTreesPerAxis - 1 do
                trees[z][x]:ComputeCenter(x * size, z * size, 0, 0, size)
            end
        end
    end,

    --- Draws all trees with the correct layer color
    ---@param self NavGrid
    Draw = function(self)
        local size = self.TreeSize
        for z = 0, LabelCompressionTreesPerAxis - 1 do
            for x = 0, LabelCompressionTreesPerAxis - 1 do
                self.Trees[z][x]:Draw(Shared.LayerColors[self.Layer], 0, x * size, z * size, 0, 0, size)
            end
        end
    end,

    --- Draws all trees with their corresponding labels
    ---@param self NavGrid
    DrawLabels = function(self, inset)
        local size = self.TreeSize
        for z = 0, LabelCompressionTreesPerAxis - 1 do
            for x = 0, LabelCompressionTreesPerAxis - 1 do
                self.Trees[z][x]:DrawLabels(inset, x * size, z * size, 0, 0, size)
            end
        end
    end,
}

local FactoryCompressedLabelTree = {
    __call = function(self, layer, treeSize)
        return setmetatable({&0 &4}, self)
    end
}

---@generic T: fa-class
---@param specs T
---@return T
local ClassCompressedLabelTree = function(specs)
    specs.__index = specs
    return setmetatable(specs, FactoryCompressedLabelTree)
end

-- defined here, as it is a recursive class
local CompressedLabelTree

--- The leaf of the compression tree, with additional properties used during path finding
---@class CompressedLabelTreeLeaf : CompressedLabelTreeNode
---@field [1] CompressedLabelTreeLeaf?
---@field [2] CompressedLabelTreeLeaf?
---@field [3] CompressedLabelTreeLeaf?
---@field [4] CompressedLabelTreeLeaf?
---@field [5] CompressedLabelTreeLeaf?
---@field [6] CompressedLabelTreeLeaf?
---@field [7] CompressedLabelTreeLeaf?
---@field [8] CompressedLabelTreeLeaf?
---@field [9] CompressedLabelTreeLeaf?
---@field Root CompressedLabelTreeNode | CompressedLabelTreeLeaf    
---@field Size number                       # Element count starting at { bx + ox, bz + oz }, used as a parameter during path finding to determine if a unit can pass
---@field Label number                      # Label for efficient `CanPathTo` check
---@field px number                         # x-coordinate of center in world space
---@field pz number                         # z-coordinate of center in world space
---@field From CompressedLabelTreeLeaf      # Populated during path finding
---@field AcquiredCosts number              # Populated during path finding
---@field TotalCosts number                 # Populated during path finding
---@field Seen number                       # Populated during path

--- A simplified quad tree that acts as a compression of the pathing capabilities of a section of the heightmap
---@class CompressedLabelTreeNode
---@field [1] CompressedLabelTreeNode?
---@field [2] CompressedLabelTreeNode?
---@field [3] CompressedLabelTreeNode?
---@field [4] CompressedLabelTreeNode?
CompressedLabelTree = ClassCompressedLabelTree {

    --- Compresses the cache using a quad tree, significantly reducing the amount of data stored. At this point
    --- the label cache only exists of 0s and -1s
    ---@param self CompressedLabelTreeNode
    ---@param bx number             # Location of top-left corner, in world space
    ---@param bz number             # Location of top-left corner, in world space
    ---@param ox number             # Offset from top-left corner, in local space
    ---@param oz number             # Offset from top-left corner, in local space
    ---@param size number           # Element count starting at { bx + ox, bz + oz }
    ---@param root CompressedLabelTreeNode | CompressedLabelTreeLeaf
    ---@param rCache NavLabelCache
    ---@param compressionThreshold number
    ---@param layer NavLayers
    Compress = function(self, bx, bz, ox, oz, size, root, rCache, compressionThreshold, layer)
        -- base case when we meet compression threshold, we skip the children and become very pessimistic
        if size <= compressionThreshold then
            local value = rCache[oz + 1][ox + 1]
            local uniform = true
            for z = oz + 1, oz + size do
                for x = ox + 1, ox + size do
                    uniform = uniform and (value == rCache[z][x])
                    if not uniform then
                        break
                    end
                end
            end

            self.Size = size
            self.Root = root

            if uniform then
                self.Label = value
                if self.Label >= 0 then
                    NavLayerData[layer].PathableLeafs = NavLayerData[layer].PathableLeafs + 1
                else
                    NavLayerData[layer].UnpathableLeafs = NavLayerData[layer].UnpathableLeafs + 1
                end
            else
                self.Label = -1
                NavLayerData[layer].UnpathableLeafs = NavLayerData[layer].UnpathableLeafs + 1
            end

            return
        end

        -- recursive case where we do make children
        local value = rCache[oz + 1][ox + 1]
        local uniform = true
        for z = oz + 1, oz + size do
            for x = ox + 1, ox + size do
                uniform = uniform and (value == rCache[z][x])
                if not uniform then
                    break
                end
            end
        end

        if uniform then
            -- we're uniform, so we're good
            self.Label = value
            self.Size = size
            self.Root = root

            if self.Label >= 0 then
                NavLayerData[layer].PathableLeafs = NavLayerData[layer].PathableLeafs + 1
            else
                NavLayerData[layer].UnpathableLeafs = NavLayerData[layer].UnpathableLeafs + 1
            end
        else
            -- we're not uniform, split up to children
            local hc = 0.5 * size
            self[1] = CompressedLabelTree(hc)
            self[2] = CompressedLabelTree(hc)
            self[3] = CompressedLabelTree(hc)
            self[4] = CompressedLabelTree(hc)

            self[1]:Compress(bx, bz, ox, oz, hc, root, rCache, compressionThreshold, layer)
            self[2]:Compress(bx, bz, ox + hc, oz, hc, root, rCache, compressionThreshold, layer)
            self[3]:Compress(bx, bz, ox, oz + hc, hc, root, rCache, compressionThreshold, layer)
            self[4]:Compress(bx, bz, ox + hc, oz + hc, hc, root, rCache, compressionThreshold, layer)

            NavLayerData[layer].Subdivisions = NavLayerData[layer].Subdivisions + 1
        end
    end,

    --- Generates the following neighbors, when they are valid:
    ---@param self CompressedLabelTreeLeaf
    ---@param bx number             # Location of top-left corner, in world space
    ---@param bz number             # Location of top-left corner, in world space
    ---@param ox number             # Offset from top-left corner, in local space
    ---@param oz number             # Offset from top-left corner, in local space
    ---@param size number           # Element count starting at { bx + ox, bz + oz }
    ---@param root NavGrid
    ---@param layer NavLayers
    GenerateDirectNeighbors = function(self, bx, bz, ox, oz, size, root, layer)

        local label = self.Label

        -- nodes do not have neighbors, only leafs do
        if not label then
            local hc = 0.5 * size
            self[1]:GenerateDirectNeighbors(bx, bz, ox, oz, hc, root, layer)
            self[2]:GenerateDirectNeighbors(bx, bz, ox + hc, oz, hc, root, layer)
            self[3]:GenerateDirectNeighbors(bx, bz, ox, oz + hc, hc, root, layer)
            self[4]:GenerateDirectNeighbors(bx, bz, ox + hc, oz + hc, hc, root, layer)
            return
        end

        -- we are a leaf, so find those neighbors!
        local x1 = bx + ox
        local z1 = bz + oz

        local x2 = x1 + size
        local z2 = z1 + size
        local x1Outside, z1Outside = x1 - 0.5, z1 - 0.5
        local x2Outside, z2Outside = x2 + 0.5, z2 + 0.5

        local seen = HashCache
        for k, v in seen do
            seen[k] = nil
        end

        --- 0 | 1 | 0
        --- 1 | x | 1
        --- 0 | 1 | 0

        -- scan top-left -> top-right
        for k = x1, x2 - 1 do
            local x = k + 0.5
            -- DrawCircle({x, GetSurfaceHeight(x, z1Outside), z1Outside}, 0.5, 'ff0000')
            local neighbor = root:FindLeafXZ(x, z1Outside)
            if neighbor then
                k = k + neighbor.Size - 1
                if not seen[neighbor] then
                    seen[neighbor] = true
                    TableInsert(self, neighbor)
                end
            else
                break
            end
        end

        -- scan bottom-left -> bottom-right
        for k = x1, x2 - 1 do
            local x = k + 0.5
            -- DrawCircle({x, GetSurfaceHeight(x, z2Outside), z2Outside}, 0.5, 'ff0000')
            local neighbor = root:FindLeafXZ(x, z2Outside)
            if neighbor then
                k = k + neighbor.Size - 1
                if not seen[neighbor] then
                    seen[neighbor] = true
                    TableInsert(self, neighbor)
                end
            else
                break
            end
        end

        -- scan left-top -> left-bottom
        for k = z1, z2 - 1 do
            local z = k + 0.5
            -- DrawCircle({x1Outside, GetSurfaceHeight(x1Outside, z), z}, 0.5, 'ff0000')
            local neighbor = root:FindLeafXZ(x1Outside, z)
            if neighbor then
                k = k + neighbor.Size - 1
                if not seen[neighbor] then
                    seen[neighbor] = true
                    TableInsert(self, neighbor)
                end
            else
                break
            end
        end

        -- scan right-top -> right-bottom
        for k = z1, z2 - 1 do
            local z = k + 0.5
            -- DrawCircle({x2Outside, GetSurfaceHeight(x2Outside, z), z}, 0.5, 'ff0000')
            local neighbor = root:FindLeafXZ(x2Outside, z)
            if neighbor then
                k = k + neighbor.Size - 1
                if not seen[neighbor] then
                    seen[neighbor] = true
                    TableInsert(self, neighbor)
                end
            else
                break
            end
        end

        --- 1 | 0 | 1
        --- 0 | x | 0
        --- 1 | 0 | 1

        -- scan top-left
        local a, b
        local neighbor = root:FindLeafXZ(x1Outside, z1Outside)
        -- DrawCircle({x1Outside, GetSurfaceHeight(x1Outside, z1Outside), z1Outside}, 0.5, 'ff0000')
        if neighbor and not seen[neighbor] then
            seen[neighbor] = true
            a = root:FindLeafXZ(x1Outside + 1, z1Outside)
            b = root:FindLeafXZ(x1Outside, z1Outside + 1)

            if a and b and (a.Label == 0 or b.Label == 0) then
                TableInsert(self, neighbor)
            end
        end

        -- scan top-right
        neighbor = root:FindLeafXZ(x2Outside, z1Outside)
        -- DrawCircle({x2Outside, GetSurfaceHeight(x2Outside, z1Outside), z1Outside}, 0.5, 'ff0000')
        if neighbor and not seen[neighbor] then
            seen[neighbor] = true
            a = root:FindLeafXZ(x2Outside - 1, z1Outside)
            b = root:FindLeafXZ(x2Outside, z1Outside + 1)

            if a and b and (a.Label == 0 or b.Label == 0) then
                TableInsert(self, neighbor)
            end
        end

        -- scan bottom-left
        -- DrawCircle({x1Outside, GetSurfaceHeight(x1Outside, z2Outside), z2Outside}, 0.5, 'ff0000')
        neighbor = root:FindLeafXZ(x1Outside, z2Outside)
        if neighbor and not seen[neighbor] then
            seen[neighbor] = true
            a = root:FindLeafXZ(x1Outside + 1, z2Outside)
            b = root:FindLeafXZ(x1Outside, z2Outside - 1)

            if a and b and (a.Label == 0 or b.Label == 0) then
                TableInsert(self, neighbor)
            end
        end

        -- scan bottom-right
        -- DrawCircle({x2Outside, GetSurfaceHeight(x2Outside, z2Outside), z2Outside}, 0.5, 'ff0000')
        neighbor = root:FindLeafXZ(x2Outside, z2Outside)
        if neighbor and not seen[neighbor] then
            seen[neighbor] = true
            a = root:FindLeafXZ(x2Outside - 1, z2Outside)
            b = root:FindLeafXZ(x2Outside, z2Outside - 1)

            if a and b and (a.Label == 0 or b.Label == 0) then
                TableInsert(self, neighbor)
            end
        end

        NavLayerData[layer].Neighbors = NavLayerData[layer].Neighbors + table.getn(self)
    end,

    ---@param self CompressedLabelTreeNode
    ---@param stack table
    ---@param layer NavLayers
    GenerateLabels = function(self, stack, layer)
        -- leaf case
        if self.Label then

            -- check if we are unassigned (labels start at 1)
            if self.Label == 0 then

                -- we can hit a stack overflow if we do this recursively, therefore we do a
                -- depth first search using a stack that we re-use for better performance
                local free = 1
                local label = GenerateLabelIdentifier()

                NavLabels[label] = {
                    Area = 0,
                    Node = self --[[@as CompressedLabelTreeLeaf]] ,
                    Layer = layer,
                    NumberOfExtractors = 0,
                    NumberOfHydrocarbons = 0,
                    ExtractorMarkers = {},
                    HydrocarbonMarkers = {},
                }

                local metadata = NavLabels[label]

                -- assign the label, and then search through our neighbors to assign the same label to them
                self.Label = label
                metadata.Area = metadata.Area + ((0.01 * self.Size) * (0.01 * self.Size))

                -- add our pathable neighbors to the stack
                for k = 1, table.getn(self) do
                    local neighbor = self[k]
                    if neighbor.Label == 0 then
                        stack[free] = neighbor
                        free = free + 1
                    end

                    if neighbor.Label > 0 then
                        WARN("Something fishy happened")
                    end
                end

                -- do depth first search
                while free > 1 do

                    -- retrieve from stack
                    local other = stack[free - 1]
                    free = free - 1

                    -- assign label, manage metadata
                    other.Label = label
                    metadata.Area = metadata.Area + ((0.01 * other.Size) * (0.01 * other.Size))

                    -- add unlabelled neighbors
                    for k = 1, table.getn(other) do
                        local neighbor = other[k]
                        if neighbor.Label == 0 then
                            stack[free] = neighbor
                            free = free + 1
                        end
                    end
                end
            end

            return
        end

        -- node case
        self[1]:GenerateLabels(stack, layer)
        self[2]:GenerateLabels(stack, layer)
        self[3]:GenerateLabels(stack, layer)
        self[4]:GenerateLabels(stack, layer)
    end,

    ---@param self CompressedLabelTreeLeaf
    ---@param bx number             # Location of top-left corner, in world space
    ---@param bz number             # Location of top-left corner, in world space
    ---@param ox number             # Offset from top-left corner, in local space
    ---@param oz number             # Offset from top-left corner, in local space
    ---@param size number           # Element count starting at { bx + ox, bz + oz }
    ComputeCenter = function(self, bx, bz, ox, oz, size)
        if not self.Label then
            local hc = 0.5 * size
            self[1]:ComputeCenter(bx, bz, ox, oz, hc)
            self[2]:ComputeCenter(bx, bz, ox + hc, oz, hc)
            self[3]:ComputeCenter(bx, bz, ox, oz + hc, hc)
            self[4]:ComputeCenter(bx, bz, ox + hc, oz + hc, hc)
        else
            self.px = bx + ox + 0.5 * size
            self.pz = bz + oz + 0.5 * size
        end
    end,

    ---@param self CompressedLabelTreeLeaf
    ---@param other CompressedLabelTreeLeaf
    ---@return number
    DistanceTo = function(self, other)
        local dx = self.px - other.px
        local dz = self.pz - other.pz
        return math.sqrt(dx * dx + dz * dz)
    end,

    ---@param self CompressedLabelTreeLeaf
    ---@param other CompressedLabelTreeLeaf
    ---@return number
    ---@return number
    DirectionTo = function(self, other)
        return self.px - other.px, self.pz - other.pz
    end,

    --- Returns the leaf that encompasses the position, or nil if no leaf does
    ---@param self CompressedLabelTreeNode
    ---@param bx number             # Location of top-left corner, in world space
    ---@param bz number             # Location of top-left corner, in world space
    ---@param ox number             # Offset from top-left corner, in local space
    ---@param oz number             # Offset from top-left corner, in local space
    ---@param size number           # Element count starting at { bx + ox, bz + oz }
    ---@param position Vector       # A position in world space
    ---@return CompressedLabelTreeLeaf?
    FindLeaf = function(self, bx, bz, ox, oz, size, position)
        return self:FindLeafXZ(bx, bz, ox, oz, size, position[1], position[3])
    end,

    --- Returns the leaf that encompasses the position, or nil if no leaf does
    ---@param self CompressedLabelTreeNode
    ---@param bx number             # Location of top-left corner, in world space
    ---@param bz number             # Location of top-left corner, in world space
    ---@param ox number             # Offset from top-left corner, in local space
    ---@param oz number             # Offset from top-left corner, in local space
    ---@param size number           # Element count starting at { bx + ox, bz + oz }
    ---@param x number              # x-coordinate, in world space
    ---@param z number              # z-coordinate, in world space
    ---@return CompressedLabelTreeLeaf?
    FindLeafXZ = function(self, bx, bz, ox, oz, size, x, z)
        local x1 = bx + ox
        local z1 = bz + oz
        -- Check if it's inside our rectangle the first time only
        if x < x1 or x1 + size < x or z < z1 or z1 + size < z then
            return nil
        end
        return self:_FindLeafXZ(bx, bz, ox, oz, size, x - bx, z - bz)
    end;

    ---@param self CompressedLabelTreeNode
    ---@param bx number             # Location of top-left corner, in world space
    ---@param bz number             # Location of top-left corner, in world space
    ---@param ox number             # Offset from top-left corner, in local space
    ---@param oz number             # Offset from top-left corner, in local space
    ---@param size number           # Element count starting at { bx + ox, bz + oz }
    ---@param x number              # x-coordinate, in world space
    ---@param z number              # z-coordinate, in world space
    ---@return CompressedLabelTreeLeaf?
    _FindLeafXZ = function(self, bx, bz, ox, oz, size, x, z)
        if not self.Label then
            local hc = size * 0.5
            local hx, hz = ox + hc, oz + hc
            if z < hz then
                if x < hx then
                    return self[1]:_FindLeafXZ(bx, bz, ox, oz, hc, x, z) -- top left
                else
                    return self[2]:_FindLeafXZ(bx, bz, ox + hc, oz, hc, x, z) -- top right
                end
            else
                if x < hx then
                    return self[3]:_FindLeafXZ(bx, bz, ox, oz + hc, hc, x, z) -- bottom left
                else
                    return self[4]:_FindLeafXZ(bx, bz, ox + hc, oz + hc, hc, x, z) -- bottom right
                end
            end
        else
            return self --[[@as CompressedLabelTreeLeaf]]
        end
    end;

    ---@param self CompressedLabelTreeNode
    ---@param color Color
    Draw = function(self, color, inset, bx, bz, ox, oz, size)
        if self.Label then
            if self.Label >= 0 then
                DrawSquare(bx + ox, bz + oz, size, color, inset)
            end
        else
            local hc = 0.5 * size
            self[1]:Draw(color, inset, bx, bz, ox, oz, hc)
            self[2]:Draw(color, inset, bx, bz, ox + hc, oz, hc)
            self[3]:Draw(color, inset, bx, bz, ox, oz + hc, hc)
            self[4]:Draw(color, inset, bx, bz, ox + hc, oz + hc, hc)
        end
    end,

    ---@param self CompressedLabelTreeNode
    DrawLabels = function(self, inset, bx, bz, ox, oz, size)
        if self.Label then
            if self.Label >= 0 then
                DrawSquare(bx + ox, bz + oz, size, Shared.LabelToColor(self.Label), inset)
            end
        else
            local hc = 0.5 * size
            self[1]:DrawLabels(inset, bx, bz, ox, oz, hc)
            self[2]:DrawLabels(inset, bx, bz, ox + hc, oz, hc)
            self[3]:DrawLabels(inset, bx, bz, ox, oz + hc, hc)
            self[4]:DrawLabels(inset, bx, bz, ox + hc, oz + hc, hc)
        end
    end,
}

---@param cells number
---@return NavTerrainCache
---@return NavDepthCache
---@return NavAverageDepthCache
---@return NavHorizontalPathCache
---@return NavVerticalPathCache
---@return NavPathCache
---@return NavTerrainBlockCache
---@return NavLabelCache
function InitCaches(cells)
    local tCache, dCache, daCache, pxCache, pzCache, pCache, bCache, rCache = {}, {}, {}, {}, {}, {}, {}, {}

    -- these need one additional element, as they represent the corners / sides of the cell we're evaluating
    for z = 1, cells + 1 do
        tCache[z] = {}
        dCache[z] = {}
        pxCache[z] = {}
        pzCache[z] = {}
        for x = 1, cells + 1 do
            tCache[z][x] = -1
            dCache[z][x] = -1
            pxCache[z][x] = true
            pzCache[z][x] = true
        end
    end

    -- these represent the cell as a whole, and therefore do not need an additional element
    for z = 1, cells do
        pCache[z] = {}
        bCache[z] = {}
        rCache[z] = {}
        daCache[z] = {}
        for x = 1, cells do
            pCache[z][x] = false
            bCache[z][x] = false
            rCache[z][x] = -1
            daCache[z][x] = -1
        end
    end

    return tCache, dCache, daCache, pxCache, pzCache, pCache, bCache, rCache
end

--- Populates the caches for the given label tree,
--- Heavily inspired by the code written by Softles
---@param labelTree CompressedLabelTreeNode
---@param tCache NavTerrainCache
---@param dCache NavDepthCache
---@param daCache NavAverageDepthCache
---@param pxCache NavHorizontalPathCache
---@param pzCache NavVerticalPathCache
---@param pCache NavPathCache
---@param bCache NavTerrainBlockCache
function PopulateCaches(tCache, dCache, daCache, pxCache, pzCache, pCache, bCache, bx, bz, c)
    local MathAbs = math.abs
    local Mathmax = math.max
    local GetTerrainHeight = GetTerrainHeight
    local GetSurfaceHeight = GetSurfaceHeight
    local GetTerrainType = GetTerrainType

    -- scan / cache terrain and depth
    for z = 1, c + 1 do
        local absZ = bz + z - 1
        for x = 1, c + 1 do
            local absX = bx + x - 1
            local terrain = GetTerrainHeight(absX, absZ)
            local surface = GetSurfaceHeight(absX, absZ)

            tCache[z][x] = terrain
            dCache[z][x] = surface - terrain

            -- DrawSquare(x - 0.15, z - 0.15, 0.3, 'ff0000')
        end
    end

    -- scan / cache cliff walkability
    for z = 1, c + 1 do
        for x = 1, c do
            pxCache[z][x] = MathAbs(tCache[z][x] - tCache[z][x + 1]) < MaxHeightDifference
        end
    end

    for z = 1, c do
        for x = 1, c + 1 do
            pzCache[z][x] = MathAbs(tCache[z][x] - tCache[z + 1][x]) < MaxHeightDifference
        end
    end

    -- compute cliff walkability
    -- compute average depth
    -- compute terrain type
    for z = 1, c do
        local absZ = bz + z
        for x = 1, c do
            local absX = bx + x
            pCache[z][x] = pxCache[z][x] and pzCache[z][x] and pxCache[z + 1][x] and pzCache[z][x + 1]
            daCache[z][x] = (dCache[z][x] + dCache[z + 1][x] + dCache[z][x + 1] + dCache[z + 1][x + 1]) * 0.25
            bCache[z][x] = not GetTerrainType(absX, absZ).Blocking


        end
    end
end

---@param size number
---@param daCache NavAverageDepthCache
---@param bCache NavTerrainBlockCache
---@param pCache NavPathCache
---@param rCache NavLabelCache
function ComputeLandPathingMatrix(size, daCache, pCache, bCache, rCache)
    for z = 1, size do
        for x = 1, size do
            if daCache[z][x] <= 0 and -- should be on land
                bCache[z][x] and -- should have accessible terrain type
                pCache[z][x] -- should be flat enough
            then
                rCache[z][x] = 0
                --DrawSquare(labelTree.bx + x + 0.3, labelTree.bz + z + 0.3, 0.4, '00ff00')
            else
                rCache[z][x] = -1
            end
        end
    end
end

---@param size number
---@param daCache NavAverageDepthCache
---@param bCache NavTerrainBlockCache
---@param pCache NavPathCache
---@param rCache NavLabelCache
function ComputeHoverPathingMatrix(size, daCache, pCache, bCache, rCache)
    for z = 1, size do
        for x = 1, size do
            if bCache[z][x] and (-- should have accessible terrain type
                daCache[z][x] >= 1 or -- can either be on water
                    pCache[z][x]-- or on flat enough terrain
                ) then
                rCache[z][x] = 0
                --DrawSquare(labelTree.bx + x + 0.4, labelTree.bz + z + 0.4, 0.2, '00b3b3')
            else
                rCache[z][x] = -1
            end
        end
    end
end

---@param size number
---@param daCache NavAverageDepthCache
---@param bCache NavTerrainBlockCache
---@param pCache NavPathCache
---@param rCache NavLabelCache
function ComputeNavalPathingMatrix(size, daCache, pCache, bCache, rCache)
    for z = 1, size do
        for x = 1, size do
            if daCache[z][x] >= MinWaterDepthNaval and -- should be deep enough
                bCache[z][x] -- should have accessible terrain type
            then
                rCache[z][x] = 0
                --DrawSquare(labelTree.bx + x + 0.45, labelTree.bz + z + 0.45, 0.1, '0000ff')
            else -- this is inaccessible
                rCache[z][x] = -1
            end
        end
    end
end

---@param size number
---@param daCache NavAverageDepthCache
---@param bCache NavTerrainBlockCache
---@param pCache NavPathCache
---@param rCache NavLabelCache
function ComputeAmphPathingMatrix(size, daCache, pCache, bCache, rCache)
    for z = 1, size do
        for x = 1, size do
            if daCache[z][x] <= MaxWaterDepthAmphibious and -- should be on land
                bCache[z][x] and -- should have accessible terrain type
                pCache[z][x] -- should be flat enough
            then
                rCache[z][x] = 0
                --DrawSquare(labelTree.bx + x + 0.35, labelTree.bz + z + 0.35, 0.3, 'ffa500')
            else -- this is inaccessible
                rCache[z][x] = -1
            end
        end
    end
end

---@param size number
---@param daCache NavAverageDepthCache
---@param bCache NavTerrainBlockCache
---@param pCache NavPathCache
---@param rCache NavLabelCache
function ComputeAirPathingMatrix(size, daCache, pCache, bCache, rCache)
    for z = 1, size do
        for x = 1, size do
            rCache[z][x] = 0
        end
    end
end

--- Generates the compression grids based on the heightmap
---@param size number (square) size of each cell of the compression grid
---@param threshold number (square) size of the smallest acceptable leafs, used for culling
local function GenerateCompressionGrids(size, threshold)

    local navLand = NavGrids['Land'] --[[@as NavGrid]]
    local navWater = NavGrids['Water'] --[[@as NavGrid]]
    local navHover = NavGrids['Hover'] --[[@as NavGrid]]
    local navAmphibious = NavGrids['Amphibious'] --[[@as NavGrid]]
    local navAir = NavGrids['Air'] --[[@as NavGrid]]

    local tCache, dCache, daCache, pxCache, pzCache, pCache, bCache, rCache = InitCaches(size)

    for z = 0, LabelCompressionTreesPerAxis - 1 do
        local bz = z * size
        for x = 0, LabelCompressionTreesPerAxis - 1 do
            local bx = x * size
            local labelTreeLand = CompressedLabelTree()
            local labelTreeNaval = CompressedLabelTree()
            local labelTreeHover = CompressedLabelTree()
            local labelTreeAmph = CompressedLabelTree()
            local labelTreeAir = CompressedLabelTree()

            -- pre-computing the caches is irrelevant layer-wise, so we just pick the Land layer
            PopulateCaches(tCache, dCache, daCache, pxCache, pzCache, pCache, bCache, bx, bz, size)

            ComputeLandPathingMatrix(size, daCache, pCache, bCache, rCache)
            labelTreeLand:Compress(bx, bz, 0, 0, size, labelTreeLand, rCache, threshold, 'Land')
            navLand:AddTree(z, x, labelTreeLand)

            ComputeNavalPathingMatrix(size, daCache, pCache, bCache, rCache)
            labelTreeNaval:Compress(bx, bz, 0, 0, size, labelTreeNaval, rCache, 2 * threshold, 'Water')
            navWater:AddTree(z, x, labelTreeNaval)

            ComputeHoverPathingMatrix(size, daCache, pCache, bCache, rCache)
            labelTreeHover:Compress(bx, bz, 0, 0, size, labelTreeHover, rCache, threshold, 'Hover')
            navHover:AddTree(z, x, labelTreeHover)

            ComputeAmphPathingMatrix(size, daCache, pCache, bCache, rCache)
            labelTreeAmph:Compress(bx, bz, 0, 0, size, labelTreeAmph, rCache, threshold, 'Amphibious')
            navAmphibious:AddTree(z, x, labelTreeAmph)

            ComputeAirPathingMatrix(size, daCache, pCache, bCache, rCache)
            labelTreeAir:Compress(bx, bz, 0, 0, size, labelTreeAir, rCache, threshold, 'Air')
            navAir:AddTree(z, x, labelTreeAir)
        end
    end
end

--- Generates graphs that we can traverse, based on the compression grids
local function GenerateGraphs()
    local navLand = NavGrids['Land'] --[[@as NavGrid]]
    local navWater = NavGrids['Water'] --[[@as NavGrid]]
    local navHover = NavGrids['Hover'] --[[@as NavGrid]]
    local navAmphibious = NavGrids['Amphibious'] --[[@as NavGrid]]
    local navAir = NavGrids['Air'] --[[@as NavGrid]]

    navLand:GenerateNeighbors()
    navWater:GenerateNeighbors()
    navHover:GenerateNeighbors()
    navAmphibious:GenerateNeighbors()
    navAir:GenerateNeighbors()

    navLand:GenerateLabels()
    navWater:GenerateLabels()
    navAmphibious:GenerateLabels()
    navHover:GenerateLabels()
    navAir:GenerateLabels()

    navLand:Precompute()
    navWater:Precompute()
    navHover:Precompute()
    navAmphibious:Precompute()
    navAir:Precompute()
end

--- Culls generated labels that are too small and have no meaning
local function GenerateCullLabels()
    local navLabels = NavLabels

    local culledLabels = 0

    ---@type CompressedLabelTreeLeaf[]
    local stack = {}
    local count = 1
    for k, _ in navLabels do
        local metadata = navLabels[k]
        if metadata.Area < 0.16 and metadata.NumberOfExtractors == 0 and metadata.NumberOfHydrocarbons == 0 then
            culledLabels = culledLabels + 1

            -- cull node
            local node = metadata.Node
            node.Label = -1

            -- find all neighbors and cull those too
            count = 1
            stack[1] = metadata.Node
            while count > 0 do
                node = stack[count]
                count = count - 1
                for k = 1, table.getn(node) do
                    local neighbor = node[k]
                    if neighbor.Label > 0 then
                        neighbor.Label = -1
                        count = count + 1
                        stack[count] = neighbor
                    end
                end
            end
        end
    end

    SPEW(string.format("NavGenerator - culled %d labels", culledLabels))
end

--- Generates metadata for markers for quick access
local function GenerateMarkerMetadata()
    local navLabels = NavLabels

    local grids = {
        Land = NavGrids['Land'],
        Amphibious = NavGrids['Amphibious'],
        Hover = NavGrids['Hover'],

        -- also tackled with amphibious layer 
        -- Naval = NavGrids['Naval'],
    }

    local extractors = import("/lua/sim/markerutilities.lua").GetMarkersByType('Mass')
    for id, extractor in extractors do
        for layer, grid in grids do
            local label = grid:FindLeaf(extractor.position).Label

            if label > 0 then
                navLabels[label].NumberOfExtractors = navLabels[label].NumberOfExtractors + 1
                table.insert(navLabels[label].ExtractorMarkers, extractor)

                if not extractor.NavLabel then
                    extractor.NavLabel = label
                    extractor.NavLayer = layer
                end
            end
        end
    end

    local hydrocarbons = import("/lua/sim/markerutilities.lua").GetMarkersByType('Hydrocarbon')
    for id, hydro in hydrocarbons do
        for layer, grid in grids do
            local label = grid:FindLeaf(hydro.position).Label

            if label > 0 then
                navLabels[label].NumberOfExtractors = navLabels[label].NumberOfExtractors + 1
                table.insert(navLabels[label].ExtractorMarkers, hydro)

                if not hydro.NavLabel then
                    hydro.NavLabel = label
                    hydro.NavLayer = layer
                end
            end
        end
    end
end



--- Generates a navigational mesh based on the heightmap
function Generate()

    -- reset state
    NavGrids = {}
    NavLabels = {}
    LabelIdentifier = 0

    local start = GetSystemTimeSecondsOnlyForProfileUse()
    print(string.format(" -- Navigational mesh generator -- "))

    NavLayerData = Shared.CreateEmptyNavLayerData()

    ---@type number
    local MapSize = ScenarioInfo.size[1]

    ---@type number
    local CompressionTreeSize = MapSize / LabelCompressionTreesPerAxis

    ---@type number
    local compressionThreshold = 1

    -- 20x20+
    if MapSize >= 1024 then
        compressionThreshold = 2 * compressionThreshold
    end

    -- 40x40+
    if MapSize >= 2048 then
        compressionThreshold = 2 * compressionThreshold
    end

    NavGrids['Land'] = NavGrid('Land', CompressionTreeSize)
    NavGrids['Water'] = NavGrid('Water', CompressionTreeSize)
    NavGrids['Hover'] = NavGrid('Hover', CompressionTreeSize)
    NavGrids['Amphibious'] = NavGrid('Amphibious', CompressionTreeSize)
    NavGrids['Air'] = NavGrid('Air', CompressionTreeSize)

    GenerateCompressionGrids(CompressionTreeSize, compressionThreshold)
    print(string.format("generated compression trees: %f", GetSystemTimeSecondsOnlyForProfileUse() - start))

    GenerateGraphs()
    print(string.format("generated neighbors and labels: %f", GetSystemTimeSecondsOnlyForProfileUse() - start))

    GenerateMarkerMetadata()
    print(string.format("generated marker metadata: %f", GetSystemTimeSecondsOnlyForProfileUse() - start))

    GenerateCullLabels()
    print(string.format("cleaning up generated data: %f", GetSystemTimeSecondsOnlyForProfileUse() - start))

    -- ditch hover / amphibious if they are identical to land
    if  NavLayerData['Land'].Labels == NavLayerData['Hover'].Labels and
        NavLayerData['Land'].Neighbors == NavLayerData['Hover'].Neighbors and
        NavLayerData['Land'].PathableLeafs == NavLayerData['Hover'].PathableLeafs and
        NavLayerData['Land'].Subdivisions == NavLayerData['Hover'].Subdivisions and
        NavLayerData['Land'].UnpathableLeafs == NavLayerData['Hover'].UnpathableLeafs
    then
        SPEW("Hover grid equals land grid - ditching hover grid")
        NavGrids['Hover'] = NavGrids['Land']
        NavLayerData['Hover'].Labels = 0
        NavLayerData['Hover'].Neighbors = 0
        NavLayerData['Hover'].PathableLeafs = 0
        NavLayerData['Hover'].Subdivisions = 0
        NavLayerData['Hover'].UnpathableLeafs = 0
    end

    if  NavLayerData['Land'].Labels == NavLayerData['Amphibious'].Labels and
        NavLayerData['Land'].Neighbors == NavLayerData['Amphibious'].Neighbors and
        NavLayerData['Land'].PathableLeafs == NavLayerData['Amphibious'].PathableLeafs and
        NavLayerData['Land'].Subdivisions == NavLayerData['Amphibious'].Subdivisions and
        NavLayerData['Land'].UnpathableLeafs == NavLayerData['Amphibious'].UnpathableLeafs
    then
        SPEW("Amphibious grid equals land grid - ditching amphibious grid")
        NavGrids['Amphibious'] = NavGrids['Land']
        NavLayerData['Amphibious'].Labels = 0
        NavLayerData['Amphibious'].Neighbors = 0
        NavLayerData['Amphibious'].PathableLeafs = 0
        NavLayerData['Amphibious'].Subdivisions = 0
        NavLayerData['Amphibious'].UnpathableLeafs = 0
    end

    SPEW(string.format("Generated navigational mesh in %f seconds", GetSystemTimeSecondsOnlyForProfileUse() - start))

    local allocatedSizeGrids = import('/lua/system/utils.lua').ToBytes(NavGrids) / (1024 * 1024)
    local allocatedSizeLabels = import('/lua/system/utils.lua').ToBytes(NavLabels, { Node = true }) / (1024 * 1024)

    SPEW(string.format("Allocated megabytes for navigational mesh: %f", allocatedSizeGrids))
    SPEW(string.format("Allocated megabytes for labels: %f", allocatedSizeLabels))

    Sync.NavLayerData = NavLayerData
    Generated = true

    -- allows debugging tools to function
    import("/lua/sim/navdebug.lua")
end

function GenerateMarkers()
    MarkerGenerator.GenerateExpansions()
end
