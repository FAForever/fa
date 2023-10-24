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
local TableGetn = table.getn

local MathFloor = math.floor

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

---@type table<number, CompressedLabelTreeNode | CompressedLabelTreeLeaf>
NavCells = {}

local Generated = false
---@return boolean
function IsGenerated()
    return Generated
end

local CellIdentifier = 0
---@return number
local function GenerateCellIdentifier()
    CellIdentifier = CellIdentifier + 1
    return CellIdentifier
end

local LabelIdentifier = 0
---@return number
local function GenerateLabelIdentifier()
    LabelIdentifier = LabelIdentifier + 1
    return LabelIdentifier
end

--- Returns the size of a cell in oGrids
---@return number
function SizeOfCell()
    ---@type number
    local MapSize = math.max(ScenarioInfo.size[1], ScenarioInfo.size[2])

    ---@type number
    return MapSize / LabelCompressionTreesPerAxis
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
        local instance = {}
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
        self.Trees = {}
        for z = 0, LabelCompressionTreesPerAxis - 1 do
            self.Trees[z] = {}
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

    ---@param self NavGrid
    ---@param position Vector A position in world space
    ---@return number?
    ---@return number?
    ToGridSpace = function(self, position)
        return self:ToGridSpaceXZ(position[1], position[3])
    end,

    ---@param self NavGrid
    ---@param x number x-coordinate, in world space
    ---@param z number z-coordinate, in world space
    ---@return number?
    ---@return number?
    ToGridSpaceXZ = function(self, x, z)
        if x > 0 and z > 0 then
            local size = self.TreeSize
            local trees = self.Trees

            local bx = math.floor(x / size)
            local bz = math.floor(z / size)
            if trees[bz][bx] then
                return bx, bz
            else
                return nil, nil
            end
        end

        return nil, nil
    end,

    ---@param self NavGrid
    ---@param position Vector A position in world space
    ---@return CompressedLabelTreeRoot?
    FindRoot = function(self, position)
        return self:FindRootXZ(position[1], position[3])
    end,

    ---@param self NavGrid
    ---@param x number x-coordinate, in world space
    ---@param z number z-coordinate, in world space
    ---@return CompressedLabelTreeRoot?
    FindRootXZ = function(self, x, z)
        if x > 0 and z > 0 then
            local size = self.TreeSize
            local trees = self.Trees

            local bx = math.floor(x / size)
            local bz = math.floor(z / size)
            local root = trees[bz][bx] --[[@as CompressedLabelTreeRoot]]
            return root
        end

        return nil
    end,

    ---@param self NavGrid
    ---@param gx number x-coordinate, in grid space
    ---@param gz number z-coordinate, in grid space
    ---@return CompressedLabelTreeRoot?
    FindRootGridspaceXZ = function(self, gx, gz)
        return self.Trees[gz][gx] --[[@as CompressedLabelTreeRoot]]
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

            local bx = MathFloor(x / size)
            local bz = MathFloor(z / size)
            local labelTree = trees[bz][bx]
            if labelTree then
                return labelTree:FindLeafXZ(bx * size, bz * size, size, x, z)
            end
        end

        return nil
    end,

    ---@param self NavGrid
    GenerateNeighbors = function(self)
        local size = self.TreeSize
        local trees = self.Trees
        local layer = self.Layer
        for z = 0, LabelCompressionTreesPerAxis - 1 do
            for x = 0, LabelCompressionTreesPerAxis - 1 do
                trees[z][x]:GenerateDirectNeighbors(self, layer)
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
    __call = function(self)
        return setmetatable({}, self)
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

---@class CompressedLabelTreeRoot : CompressedLabelTreeNode
---@field Labels table<number, number>      # Table that tells us which labels are part of this compression tree. The key represents as the label, the value represents as the fractional area that the label consumes. A value of 1 means the label tree entirely consists of one value.
---@field Seen number | nil                 # Used during navigating
---@field Threat number | nil               # Used during navigating

--- A simplified quad tree that acts as a compression of the pathing capabilities of a section of the heightmap
---@class CompressedLabelTreeNode
---@field Identifier number
---@field [1] CompressedLabelTreeNode?
---@field [2] CompressedLabelTreeNode?
---@field [3] CompressedLabelTreeNode?
---@field [4] CompressedLabelTreeNode?
CompressedLabelTree = ClassCompressedLabelTree {

    ---@param self CompressedLabelTreeNode
    ---@param x number
    ---@param z number
    ---@param s number
    ---@param rCache NavLabelCache
    CompressArea = function(self, x, z, s, rCache)
        local value = rCache[z + 1][x + 1]
        for lz = z + 1, z + s do
            for lx = x + 1, x + s do
                if value ~= rCache[lz][lx] then
                    return false, -2
                end
            end
        end

        return true, value
    end,

    ---@param self any
    ---@param bx number
    ---@param bz number
    ---@param ox number
    ---@param oz number
    ---@param size number
    ---@param label number
    ---@return table
    CreateArea = function(self, bx, bz, ox, oz, size, label, statistics)
        -- statistics
        if label >= 0 then
            statistics.PathableLeafs = statistics.PathableLeafs + 1
        else
            statistics.UnpathableLeafs = statistics.UnpathableLeafs + 1
        end

        local identifier = GenerateCellIdentifier()
        local instance = {
            Identifier = identifier,
            Size = size,
            Label = label,
            px = bx + ox + 0.5 * size,
            pz = bz + oz + 0.5 * size
        }

        -- required for navigation
        NavCells[identifier] = instance

        return instance
    end,

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

        -- localize for performance
        local CompressArea = self.CompressArea
        local CreateArea = self.CreateArea

        local statistics = NavLayerData[layer]

        -- caches used to have a structure-of-array type of approach
        local cox = { ox }
        local coz = { oz }
        local csize = { size }
        local cindex = { 1 }

        -- current index that we're processing in
        local curr = 1

        -- next free index when allocating for new nodes / leaves
        local next = 2

        repeat
            local lx = cox[curr]
            local lz = coz[curr]
            local ls = csize[curr]
            local lh = 0.5 * ls
            local ci = cindex[curr]
            curr = curr - 1

            -- determine whether they are uniform or not
            local uniformTopleft, labelTopLeft = CompressArea(self, lx, lz, lh, rCache)
            local uniformTopRight, labelTopRight = CompressArea(self, lx + lh, lz, lh, rCache)
            local uniformBottomleft, labelBottomLeft = CompressArea(self, lx, lz + lh, lh, rCache)
            local uniformBottomRight, labelBottomRight = CompressArea(self, lx + lh, lz + lh, lh, rCache)

            if (
                uniformTopleft and
                    uniformTopRight and
                    uniformBottomleft and
                    uniformBottomRight
                )
                and
                (
                labelTopLeft == labelTopRight and
                    labelTopLeft == labelBottomLeft and
                    labelTopLeft == labelBottomRight
                )
            then

                ---------------------------------------------------------------
                -- case 1: we're completely uniform with the same label

                self[ci] = CreateArea(self, bx, bz, lx, lz, ls, labelTopLeft, statistics)
            else

                ----------------------------------------------------------------
                -- case 2: we don't have the same label everywhere

                self[ci] = next

                local index

                index = next
                if uniformTopleft then
                    self[index] = CreateArea(self, bx, bz, lx, lz, lh, labelTopLeft, statistics)
                else
                    if lh <= compressionThreshold then
                        self[index] = CreateArea(self, bx, bz, lx, lz, lh, -1, statistics)
                    else
                        curr = curr + 1
                        cox[curr] = lx
                        coz[curr] = lz
                        csize[curr] = lh
                        cindex[curr] = index
                    end
                end

                local index = next + 1
                if uniformTopRight then
                    self[index] = CreateArea(self, bx, bz, lx + lh, lz, lh, labelTopRight, statistics)
                else

                    if lh <= compressionThreshold then
                        self[index] = CreateArea(self, bx, bz, lx + lh, lz, lh, -1, statistics)
                    else
                        curr = curr + 1
                        cox[curr] = lx + lh
                        coz[curr] = lz
                        csize[curr] = lh
                        cindex[curr] = index
                    end
                end

                index = next + 2
                if uniformBottomleft then
                    self[index] = CreateArea(self, bx, bz, lx, lz + lh, lh, labelBottomLeft, statistics)
                else
                    if lh <= compressionThreshold then
                        self[index] = CreateArea(self, bx, bz, lx, lz + lh, lh, -1, statistics)
                    else
                        curr = curr + 1
                        cox[curr] = lx
                        coz[curr] = lz + lh
                        csize[curr] = lh
                        cindex[curr] = index
                    end
                end

                index = next + 3
                if uniformBottomRight then
                    self[index] = CreateArea(self, bx, bz, lx + lh, lz + lh, lh, labelBottomRight, statistics)
                else
                    if lh <= compressionThreshold then
                        self[index] = CreateArea(self, bx, bz, lx + lh, lz + lh, lh, -1, statistics)
                    else
                        curr = curr + 1
                        cox[curr] = lx + lh
                        coz[curr] = lz + lh
                        csize[curr] = lh
                        cindex[curr] = index
                    end
                end

                next = next + 4

                -- statistics
                statistics.Subdivisions = statistics.Subdivisions + 1
            end

        until curr == 0

    end,


    --- Flattens the label tree into a leaf
    ---@see Compress
    ---@param self CompressedLabelTreeNode
    ---@param bx number             # Location of top-left corner, in world space
    ---@param bz number             # Location of top-left corner, in world space
    ---@param ox number             # Offset from top-left corner, in local space
    ---@param oz number             # Offset from top-left corner, in local space
    ---@param size number           # Element count starting at { bx + ox, bz + oz }
    ---@param label -1 | 0
    ---@param layer NavLayers
    Flatten = function(self, bx, bz, ox, oz, size, root, label, layer)
        self[1] = self:CreateArea(bx, bz, ox, oz, size, label, NavLayerData[layer])
    end,

    --- Generates the following neighbors, when they are valid:
    ---@param self CompressedLabelTreeLeaf
    ---@param grid NavGrid
    ---@param layer NavLayers
    GenerateDirectNeighbors = function(self, grid, layer)

        -- local scope for performance
        local type = type
        local seen = HashCache

        local FindLeafXZ = grid.FindLeafXZ
        local TableInsert = TableInsert

        for k = 1, TableGetn(self) do
            local instance = self[k]
            local isLeaf = type(instance) == "table"
            if isLeaf then

                local px = instance.px
                local pz = instance.pz
                local size = instance.Size

                local x1 = px - 0.5 * size
                local z1 = pz - 0.5 * size

                local x2 = px + 0.5 * size
                local z2 = pz + 0.5 * size

                local x1Outside, z1Outside = x1 - 0.5, z1 - 0.5
                local x2Outside, z2Outside = x2 + 0.5, z2 + 0.5

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
                    local neighbor = FindLeafXZ(grid, x, z1Outside)
                    if neighbor then
                        local identifier = neighbor.Identifier
                        k = k + neighbor.Size - 1
                        if not seen[identifier] then
                            seen[identifier] = true
                            TableInsert(instance, identifier)
                        end
                    else
                        break
                    end
                end

                -- scan bottom-left -> bottom-right
                for k = x1, x2 - 1 do
                    local x = k + 0.5
                    -- DrawCircle({x, GetSurfaceHeight(x, z2Outside), z2Outside}, 0.5, 'ff0000')
                    local neighbor = FindLeafXZ(grid, x, z2Outside)
                    if neighbor then
                        local identifier = neighbor.Identifier
                        k = k + neighbor.Size - 1
                        if not seen[identifier] then
                            seen[identifier] = true
                            TableInsert(instance, identifier)
                        end
                    else
                        break
                    end
                end

                -- scan left-top -> left-bottom
                for k = z1, z2 - 1 do
                    local z = k + 0.5
                    -- DrawCircle({x1Outside, GetSurfaceHeight(x1Outside, z), z}, 0.5, 'ff0000')
                    local neighbor = FindLeafXZ(grid, x1Outside, z)
                    if neighbor then
                        local identifier = neighbor.Identifier
                        k = k + neighbor.Size - 1
                        if not seen[identifier] then
                            seen[identifier] = true
                            TableInsert(instance, identifier)
                        end
                    else
                        break
                    end
                end

                -- scan right-top -> right-bottom
                for k = z1, z2 - 1 do
                    local z = k + 0.5
                    -- DrawCircle({x2Outside, GetSurfaceHeight(x2Outside, z), z}, 0.5, 'ff0000')
                    local neighbor = FindLeafXZ(grid, x2Outside, z)
                    if neighbor then
                        local identifier = neighbor.Identifier
                        k = k + neighbor.Size - 1
                        if not seen[identifier] then
                            seen[identifier] = true
                            TableInsert(instance, identifier)
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
                local neighbor = FindLeafXZ(grid, x1Outside, z1Outside)
                -- DrawCircle({x1Outside, GetSurfaceHeight(x1Outside, z1Outside), z1Outside}, 0.5, 'ff0000')
                if neighbor and not seen[neighbor] then
                    local identifier = neighbor.Identifier
                    seen[identifier] = true
                    a = FindLeafXZ(grid, x1Outside + 1, z1Outside)
                    b = FindLeafXZ(grid, x1Outside, z1Outside + 1)

                    if a and b and (a.Label == 0 or b.Label == 0) then
                        TableInsert(instance, identifier)
                    end
                end

                -- scan top-right
                neighbor = FindLeafXZ(grid, x2Outside, z1Outside)
                -- DrawCircle({x2Outside, GetSurfaceHeight(x2Outside, z1Outside), z1Outside}, 0.5, 'ff0000')
                if neighbor and not seen[neighbor] then
                    local identifier = neighbor.Identifier
                    seen[identifier] = true
                    a = FindLeafXZ(grid, x2Outside - 1, z1Outside)
                    b = FindLeafXZ(grid, x2Outside, z1Outside + 1)

                    if a and b and (a.Label == 0 or b.Label == 0) then
                        TableInsert(instance, identifier)
                    end
                end

                -- scan bottom-left
                -- DrawCircle({x1Outside, GetSurfaceHeight(x1Outside, z2Outside), z2Outside}, 0.5, 'ff0000')
                neighbor = FindLeafXZ(grid, x1Outside, z2Outside)
                if neighbor and not seen[neighbor] then
                    local identifier = neighbor.Identifier
                    seen[identifier] = true
                    a = FindLeafXZ(grid, x1Outside + 1, z2Outside)
                    b = FindLeafXZ(grid, x1Outside, z2Outside - 1)

                    if a and b and (a.Label == 0 or b.Label == 0) then
                        TableInsert(instance, identifier)
                    end
                end

                -- scan bottom-right
                -- DrawCircle({x2Outside, GetSurfaceHeight(x2Outside, z2Outside), z2Outside}, 0.5, 'ff0000')
                neighbor = FindLeafXZ(grid, x2Outside, z2Outside)
                if neighbor and not seen[neighbor] then
                    local identifier = neighbor.Identifier
                    seen[identifier] = true
                    a = FindLeafXZ(grid, x2Outside - 1, z2Outside)
                    b = FindLeafXZ(grid, x2Outside, z2Outside - 1)

                    if a and b and (a.Label == 0 or b.Label == 0) then
                        TableInsert(instance, identifier)
                    end
                end

                NavLayerData[layer].Neighbors = NavLayerData[layer].Neighbors + TableGetn(instance)
            end
        end
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
                for k = 1, TableGetn(self) do
                    local neighbor = NavCells[ self[k] ]
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
                    for k = 1, TableGetn(other) do
                        local neighbor = NavCells[ other[k] ]
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

    --- Returns all leaves in a table
    ---@param self CompressedLabelTreeNode
    ---@return CompressedLabelTreeLeaf[]
    ---@return number
    FindLeaves = function(self, cache)
        local head = 1
        cache = cache or {}
        cache, head = self:_FindLeaves(cache, head)

        -- clean up remainders
        for k = head, TableGetn(cache) do
            cache[k] = nil
        end

        return cache, head - 1
    end,

    --- Returns all leaves in a table
    ---@param self CompressedLabelTreeNode
    ---@return CompressedLabelTreeLeaf[]
    ---@return number
    _FindLeaves = function(self, cache, head)
        if not self.Label then
            cache, head = self[1]:_FindLeaves(cache, head)
            cache, head = self[2]:_FindLeaves(cache, head)
            cache, head = self[3]:_FindLeaves(cache, head)
            cache, head = self[4]:_FindLeaves(cache, head)
        else
            cache[head] = self
            head = head + 1
        end

        return cache, head
    end,


    --- Returns all traversable leaves in a table
    ---@param self CompressedLabelTreeNode | CompressedLabelTreeLeaf | CompressedLabelTreeRoot
    ---@return CompressedLabelTreeLeaf[]
    ---@return number
    FindTraversableLeaves = function(self, thresholdSize, cache, cacheQueue)

        -- localize for performance
        local TableGetn = TableGetn

        -- prepare (optionally) cached values
        local cacheHead = 1
        cache = cache or {}

        local queueHead = 1
        local queueTail = 1
        local queue = cacheQueue or {}

        -- use a breath-first search based search to find leaves
        queue[1] = self
        queueHead = queueHead + 1

        while queueTail < queueHead do
            local element = queue[queueTail]
            queueTail = queueTail + 1

            local label = element.Label
            if label then
                -- found a leaf
                if label > 0 and element.Size >= thresholdSize then
                    cache[cacheHead] = element
                    cacheHead = cacheHead + 1
                end
            else
                -- found a node
                for k = 1, TableGetn(element) do
                    queue[queueHead] = element[k]
                    queueHead = queueHead + 1
                end
            end
        end

        -- clean up remainders
        for k = cacheHead, TableGetn(cache) do
            cache[k] = nil
        end

        return cache, cacheHead - 1
    end,

    --- Returns the leaf that encompasses the position, or nil if no leaf does
    ---@param self CompressedLabelTreeNode
    ---@param bx number             # Location of top-left corner, in world space
    ---@param bz number             # Location of top-left corner, in world space
    ---@param size number           # Element count starting at { bx + ox, bz + oz }
    ---@param position Vector       # A position in world space
    ---@return CompressedLabelTreeLeaf?
    FindLeaf = function(self, bx, bz, size, position)
        return self:FindLeafXZ(bx, bz, size, position[1], position[3])
    end,

    --- Returns the leaf that encompasses the position, or nil if no leaf does
    ---@param self CompressedLabelTreeNode
    ---@param bx number             # Location of top-left corner, in world space
    ---@param bz number             # Location of top-left corner, in world space
    ---@param size number           # Element count starting at { bx + ox, bz + oz }
    ---@param x number              # x-coordinate, in world space
    ---@param z number              # z-coordinate, in world space
    ---@return CompressedLabelTreeLeaf?
    FindLeafXZ = function(self, bx, bz, size, x, z)
        -- check if we're inside in the area
        if x < bx or bx + size < x or z < bz or bz + size < z then
            return nil
        end

        -- local scope for performance
        local type = type

        -- we need to adjust these as we go
        local iox = 0
        local ioz = 0
        local hc = size

        local lx = x - bx
        local lz = z - bz

        local instance = self[1]
        while type(instance) != 'table' do
            hc = 0.5 * hc
            local hx = iox + hc
            local hz = ioz + hc

            if lz < hz then
                if lx < hx then
                    instance = self[instance]
                else
                    instance = self[instance + 1]
                    iox = hx
                end
            else
                if lx < hx then
                    instance = self[instance + 2]
                    ioz = hz
                else
                    instance = self[instance + 3]
                    iox = hx
                    ioz = hz
                end
            end
        end

        return instance --[[@as CompressedLabelTreeLeaf]]
    end;

    ---@param self CompressedLabelTreeNode
    ---@param color Color
    Draw = function(self, color, inset)

        -- local scope for performance
        local GetSurfaceHeight = GetSurfaceHeight
        local TableGetn = TableGetn
        local type = type

        for k = 1, TableGetn(self) do
            local instance = self[k]
            local isLeaf = type(instance) == "table"
            if isLeaf then
                local px = instance.px
                local pz = instance.pz
                local size = instance.Size

                -- DrawCircle({ px, GetSurfaceHeight(px, pz), pz }, 0.5, 'ffffff')

                if instance.Label >= 0 then
                    DrawSquare(px - 0.5 * size, pz - 0.5 * size, size, color, inset)
                else
                    DrawSquare(px - 0.5 * size, pz - 0.5 * size, size, 'ff0000', inset)
                end
            end
        end
    end,

    ---@param self CompressedLabelTreeNode
    DrawLabels = function(self, inset)

        -- local scope for performance
        local GetSurfaceHeight = GetSurfaceHeight
        local TableGetn = TableGetn
        local type = type

        for k = 1, TableGetn(self) do
            local instance = self[k]
            local isLeaf = type(instance) == "table"
            if isLeaf then
                local px = instance.px
                local pz = instance.pz
                local size = instance.Size
                DrawCircle({ px, GetSurfaceHeight(px, pz), pz }, 0.5, 'ffffff')
                DrawSquare(px - 0.5 * size, pz - 0.5 * size, size, Shared.LabelToColor(instance.Label), inset)
            end
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
---@return number   # minimum depth
---@return number   # maximum depth
---@return boolean  # all pathable
---@return boolean  # all free of blockers
function PopulateCaches(tCache, dCache, daCache, pxCache, pzCache, pCache, bCache, bx, bz, c)
    local MathAbs = math.abs
    local Mathmax = math.max
    local GetTerrainHeight = GetTerrainHeight
    local GetSurfaceHeight = GetSurfaceHeight
    local GetTerrainType = GetTerrainType

    -- scan / cache terrain and depth
    for z = 1, c + 1 do
        local absZ = bz + z - 1
        local tc = tCache[z]
        local dc = dCache[z]
        for x = 1, c + 1 do
            local absX = bx + x - 1
            local terrain = GetTerrainHeight(absX, absZ)
            local surface = GetSurfaceHeight(absX, absZ)

            tc[x] = terrain
            dc[x] = surface - terrain

            -- DrawSquare(x - 0.15, z - 0.15, 0.3, 'ff0000')
        end
    end

    -- scan / cache cliff walkability
    for z = 1, c + 1 do
        local pc = pxCache[z]
        for x = 1, c do
            pc[x] = MathAbs(tCache[z][x] - tCache[z][x + 1]) < MaxHeightDifference
        end
    end

    for z = 1, c do
        local pc = pzCache[z]
        for x = 1, c + 1 do
            pc[x] = MathAbs(tCache[z][x] - tCache[z + 1][x]) < MaxHeightDifference
        end
    end

    -- compute cliff walkability
    -- compute average depth
    local allPathable = true
    local minDepth = 0
    local maxDepth = 0
    for z = 1, c do
        local pxc = pxCache[z]
        local pzc = pzCache[z]
        local pxc1 = pxCache[z + 1]
        local pzc1 = pzCache[z]

        local dc = dCache[z]
        local dc1 = dCache[z + 1]

        local pc = pCache[z]
        local dac = daCache[z]
        for x = 1, c do
            local pathable = pxc[x] and pzc[x] and pxc1[x] and pzc1[x + 1]
            pc[x] = pathable
            local depth = (dc[x] + dc1[x] + dc[x + 1] + dc1[x + 1]) * 0.25
            dac[x] = depth

            -- pre-analyse the cell
            if depth < minDepth then
                minDepth = depth
            end

            if depth > maxDepth then
                maxDepth = depth
            end

            allPathable = allPathable and pathable
        end
    end

    -- determine playable area
    local playableArea = ScenarioInfo.MapData.PlayableRect
    local isSkirmish = ScenarioInfo.type == 'skirmish'

    local tlx, tlz, brx, brz
    if playableArea and isSkirmish then
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

    -- compute terrain path blockers
    local allBlockerFree = true
    for z = 1, c do
        local absZ = bz + z
        for x = 1, c do
            local absX = bx + x
            local blocked = (tlx <= absX and brx >= absX) and (tlz <= absZ and brz >= absZ) and
                (not GetTerrainType(absX, absZ).Blocking)
            bCache[z][x] = blocked

            -- pre-analyse the cell
            allBlockerFree = allBlockerFree and blocked
        end
    end

    return minDepth, maxDepth, allPathable, allBlockerFree
end

---@param size number
---@param daCache NavAverageDepthCache
---@param bCache NavTerrainBlockCache
---@param pCache NavPathCache
---@param rCache NavLabelCache
function ComputeLandPathingMatrix(size, daCache, pCache, bCache, rCache)
    for z = 1, size do
        for x = 1, size do
            local nonBlockingTerrainType = bCache[z][x]
            local isLand = daCache[z][x] <= 0
            local nonBlockingTerrainAngle = pCache[z][x]
            if isLand and nonBlockingTerrainType and nonBlockingTerrainAngle then
                rCache[z][x] = 0
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
            local nonBlockingTerrainType = bCache[z][x]
            local sufficientDepth = daCache[z][x] >= 1
            local nonBlockingTerrainAngle = pCache[z][x]

            if nonBlockingTerrainType and (sufficientDepth or nonBlockingTerrainAngle) then
                rCache[z][x] = 0
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
            local nonBlockingTerrainType = bCache[z][x]
            local sufficientDepth = daCache[z][x] >= MinWaterDepthNaval

            if sufficientDepth and nonBlockingTerrainType then
                rCache[z][x] = 0
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
function ComputeAmphPathingMatrix(size, daCache, pCache, bCache, rCache)
    for z = 1, size do
        for x = 1, size do
            local nonBlockingTerrainType = bCache[z][x]
            local notTooDeep = daCache[z][x] <= MaxWaterDepthAmphibious
            local nonBlockingTerrainAngle = pCache[z][x]

            if notTooDeep and nonBlockingTerrainType and nonBlockingTerrainAngle then
                rCache[z][x] = 0
            else
                rCache[z][x] = -1
            end
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

    local flattenedSections = 0
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
            local minDepth, maxDepth, allPathable, allBlockerFree = PopulateCaches(tCache, dCache, daCache, pxCache,
                pzCache, pCache, bCache, bx, bz, size)

            -- cell entirely consists of water
            if minDepth > MinWaterDepthNaval then
                -- flatten land
                flattenedSections = flattenedSections + 1
                labelTreeLand:Flatten(bx, bz, 0, 0, size, labelTreeLand, -1, 'Land')
                navLand:AddTree(z, x, labelTreeLand)

                -- try to flatten naval / hover
                if allBlockerFree then
                    flattenedSections = flattenedSections + 1
                    labelTreeNaval:Flatten(bx, bz, 0, 0, size, labelTreeNaval, 0, 'Water')
                    navWater:AddTree(z, x, labelTreeNaval)

                    flattenedSections = flattenedSections + 1
                    labelTreeHover:Flatten(bx, bz, 0, 0, size, labelTreeHover, 0, 'Hover')
                    navHover:AddTree(z, x, labelTreeHover)
                else
                    ComputeNavalPathingMatrix(size, daCache, pCache, bCache, rCache)
                    labelTreeNaval:Compress(bx, bz, 0, 0, size, labelTreeNaval, rCache, 2 * threshold, 'Water')
                    navWater:AddTree(z, x, labelTreeNaval)

                    ComputeHoverPathingMatrix(size, daCache, pCache, bCache, rCache)
                    labelTreeHover:Compress(bx, bz, 0, 0, size, labelTreeHover, rCache, threshold, 'Hover')
                    navHover:AddTree(z, x, labelTreeHover)
                end

                -- try to flatten amphibious
                if allPathable and allBlockerFree and maxDepth < MaxWaterDepthAmphibious then
                    flattenedSections = flattenedSections + 1
                    labelTreeAmph:Flatten(bx, bz, 0, 0, size, labelTreeAmph, 0, 'Amphibious')
                    navAmphibious:AddTree(z, x, labelTreeAmph)
                else
                    ComputeAmphPathingMatrix(size, daCache, pCache, bCache, rCache)
                    labelTreeAmph:Compress(bx, bz, 0, 0, size, labelTreeAmph, rCache, threshold, 'Amphibious')
                    navAmphibious:AddTree(z, x, labelTreeAmph)
                end

                -- cell entirely consists of land
            elseif maxDepth == 0 then
                -- flatten naval
                flattenedSections = flattenedSections + 1
                labelTreeNaval:Flatten(bx, bz, 0, 0, size, labelTreeNaval, -1, 'Water')
                navWater:AddTree(z, x, labelTreeNaval)

                -- try to flatten land
                if allPathable and allBlockerFree then
                    flattenedSections = flattenedSections + 1
                    labelTreeLand:Flatten(bx, bz, 0, 0, size, labelTreeLand, 0, 'Land')
                    navLand:AddTree(z, x, labelTreeLand)

                    flattenedSections = flattenedSections + 1
                    labelTreeHover:Flatten(bx, bz, 0, 0, size, labelTreeHover, 0, 'Hover')
                    navHover:AddTree(z, x, labelTreeHover)

                    flattenedSections = flattenedSections + 1
                    labelTreeAmph:Flatten(bx, bz, 0, 0, size, labelTreeAmph, 0, 'Amphibious')
                    navAmphibious:AddTree(z, x, labelTreeAmph)
                else
                    ComputeLandPathingMatrix(size, daCache, pCache, bCache, rCache)
                    labelTreeLand:Compress(bx, bz, 0, 0, size, labelTreeLand, rCache, threshold, 'Land')
                    navLand:AddTree(z, x, labelTreeLand)

                    ComputeHoverPathingMatrix(size, daCache, pCache, bCache, rCache)
                    labelTreeHover:Compress(bx, bz, 0, 0, size, labelTreeHover, rCache, threshold, 'Hover')
                    navHover:AddTree(z, x, labelTreeHover)

                    ComputeAmphPathingMatrix(size, daCache, pCache, bCache, rCache)
                    labelTreeAmph:Compress(bx, bz, 0, 0, size, labelTreeAmph, rCache, threshold, 'Amphibious')
                    navAmphibious:AddTree(z, x, labelTreeAmph)
                end

                -- cell consists of water and land, do the usual
            else
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
            end

            flattenedSections = flattenedSections + 1
            labelTreeAir:Flatten(bx, bz, 0, 0, size, labelTreeAir, 0, 'Air')
            navAir:AddTree(z, x, labelTreeAir)
        end
    end

    SPEW(string.format("NavGenerator - Flattened %d sections", flattenedSections))
end

--- Generates graphs that we can traverse, based on the compression grids
---@param processAmphibious boolean
---@param processHover boolean
local function GenerateGraphs(processAmphibious, processHover)
    local navLand = NavGrids['Land'] --[[@as NavGrid]]
    local navWater = NavGrids['Water'] --[[@as NavGrid]]
    local navHover = NavGrids['Hover'] --[[@as NavGrid]]
    local navAmphibious = NavGrids['Amphibious'] --[[@as NavGrid]]
    local navAir = NavGrids['Air'] --[[@as NavGrid]]

    navAir:GenerateNeighbors()
    -- navAir:GenerateLabels()
    -- navAir:Precompute()

    navLand:GenerateNeighbors()
    -- navLand:GenerateLabels()
    -- navLand:Precompute()

    navWater:GenerateNeighbors()
    -- navWater:GenerateLabels()
    -- navWater:Precompute()

    if processHover then
        navHover:GenerateNeighbors()
        -- navHover:GenerateLabels()
        -- navHover:Precompute()
    end

    if processAmphibious then
        navAmphibious:GenerateNeighbors()
        -- navAmphibious:GenerateLabels()
        -- navAmphibious:Precompute()
    end
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
local function GenerateMarkerMetadata(processAmphibious, processHover)
    local navLabels = NavLabels

    local grids = {
        NavGrids['Land'],
    }

    if processAmphibious then
        TableInsert(grids, NavGrids['Amphibious'])
    end

    if processHover then
        TableInsert(grids, NavGrids['Hover'])
    end

    local extractors = import("/lua/sim/markerutilities.lua").GetMarkersByType('Mass')
    for id, extractor in extractors do
        for _, grid in grids do
            local layer = grid.Layer
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

--- Computes various fields for the root nodes
local function GenerateRootInformation(processAmphibious, processHover)

    local cache = {}
    local size = ScenarioInfo.size[1] / LabelCompressionTreesPerAxis
    local area = ((0.01 * size) * (0.01 * size))

    local grids = {
        NavGrids['Land'],
        NavGrids['Water'],
        NavGrids['Air'],
    }

    if processAmphibious then
        TableInsert(grids, NavGrids['Amphibious'])
    end

    if processHover then
        TableInsert(grids, NavGrids['Hover'])
    end

    for _, grid in grids do
        for z = 0, LabelCompressionTreesPerAxis - 1 do
            for x = 0, LabelCompressionTreesPerAxis - 1 do
                ---@type CompressedLabelTreeRoot
                local tree = grid.Trees[z][x]

                if not tree.Labels then
                    local leaves, count = tree:FindLeaves(cache)

                    -- sum up area
                    local labels = {}
                    for k = 1, count do
                        local leaf = leaves[k]
                        local label = leaf.Label
                        if label > 0 then
                            local areaOfLeaf = ((0.01 * leaf.Size) * (0.01 * leaf.Size))
                            labels[label] = (labels[label] or 0) + areaOfLeaf
                        end
                    end

                    -- compute ratio of total area for each label
                    for label, areaOfLabel in labels do
                        labels[label] = areaOfLabel / area
                    end

                    tree.Labels = labels
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
    local MapSize = math.max(ScenarioInfo.size[1], ScenarioInfo.size[2])

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

    local processAmphibious = true
    if NavLayerData['Land'].PathableLeafs == NavLayerData['Amphibious'].PathableLeafs and
        NavLayerData['Land'].Subdivisions == NavLayerData['Amphibious'].Subdivisions and
        NavLayerData['Land'].UnpathableLeafs == NavLayerData['Amphibious'].UnpathableLeafs
    then
        SPEW(string.format("NavGenerator - replacing amphibious grid with land grid to conserve memory"))
        processAmphibious = false

        NavGrids['Amphibious'] = NavGrids['Land']
        NavLayerData['Amphibious'].Labels = 0
        NavLayerData['Amphibious'].Neighbors = 0
        NavLayerData['Amphibious'].PathableLeafs = 0
        NavLayerData['Amphibious'].Subdivisions = 0
        NavLayerData['Amphibious'].UnpathableLeafs = 0
    end

    local processHover = true
    if NavLayerData['Land'].PathableLeafs == NavLayerData['Hover'].PathableLeafs and
        NavLayerData['Land'].Subdivisions == NavLayerData['Hover'].Subdivisions and
        NavLayerData['Land'].UnpathableLeafs == NavLayerData['Hover'].UnpathableLeafs
    then
        SPEW(string.format("NavGenerator - replacing hover grid with land grid to conserve memory"))
        processHover = false

        NavGrids['Hover'] = NavGrids['Land']
        NavLayerData['Hover'].Labels = 0
        NavLayerData['Hover'].Neighbors = 0
        NavLayerData['Hover'].PathableLeafs = 0
        NavLayerData['Hover'].Subdivisions = 0
        NavLayerData['Hover'].UnpathableLeafs = 0
    end

    GenerateGraphs(processAmphibious, processHover)
    print(string.format("generated neighbors and labels: %f", GetSystemTimeSecondsOnlyForProfileUse() - start))

    -- GenerateMarkerMetadata(processAmphibious, processHover)
    -- print(string.format("generated marker metadata: %f", GetSystemTimeSecondsOnlyForProfileUse() - start))

    -- GenerateCullLabels()
    -- print(string.format("cleaning up generated data: %f", GetSystemTimeSecondsOnlyForProfileUse() - start))

    -- GenerateRootInformation(processAmphibious, processHover)

    SPEW(string.format("Generated navigational mesh in %f seconds", GetSystemTimeSecondsOnlyForProfileUse() - start))

    local allocatedSizeGrids = import('/lua/system/utils.lua').ToBytes(NavGrids) / (1024 * 1024)
    local allocatedSizeLabels = import('/lua/system/utils.lua').ToBytes(NavLabels, { Node = true }) / (1024 * 1024)

    SPEW(string.format("Allocated megabytes for navigational mesh: %f", allocatedSizeGrids))
    SPEW(string.format("Allocated megabytes for labels: %f", allocatedSizeLabels))
    SPEW(string.format("Number of labels: %f", LabelIdentifier))
    SPEW(string.format("Number of cells: %f", CellIdentifier))
    SPEW(reprs(NavLayerData))

    Sync.NavLayerData = NavLayerData
    Generated = true

    -- allows debugging tools to function
    import("/lua/sim/navdebug.lua")
end
