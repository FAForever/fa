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
local MathMax = math.max
local MathAbs = math.abs

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
---@field Node NavLeaf
---@field Area number
---@field Layer NavLayers
---@field NumberOfExtractors number
---@field NumberOfHydrocarbons number
---@field ExtractorMarkers MarkerResource[]
---@field HydrocarbonMarkers MarkerResource[]

---@alias NavTreeIdentifier number
---@alias NavLeafIdentifier number
---@alias NavSectionIdentifier number 
---@alias NavLabelIdentifier number

---@type table<NavLabelIdentifier, NavLabelMetadata>
NavLabels = {}

---@type table<NavLeafIdentifier, NavLeaf>
NavLeaves = {}

---@type table<NavTreeIdentifier, NavTree>
NavTrees = {}

---@type table<NavSectionIdentifier, NavSection>
NavSections = {}

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

local SectionIdentifier = 0
---@return number
local function GenerateSectionIdentifier()
    SectionIdentifier = SectionIdentifier + 1
    return SectionIdentifier
end

local TreeIdentifier = 0
---@return number
local function GenerateTreeIdentifier()
    TreeIdentifier = TreeIdentifier + 1
    return TreeIdentifier
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
    local MapSize = MathMax(ScenarioInfo.size[1], ScenarioInfo.size[2])

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
---@field Trees NavTree[][]
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

    --- Adds a compressed label tree to the navigational grid
    ---@param self NavGrid
    ---@param z number index
    ---@param x number index
    ---@param labelTree NavTree
    AddTree = function(self, z, x, labelTree)
        self.Trees[z][x] = labelTree

        local treeSize = self.TreeSize
        local cx = (x + 0.5) * treeSize
        local cz = (z + 0.5) * treeSize
        labelTree.Center = {cx, GetSurfaceHeight(cx, cz), cz}
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

            local bx = MathFloor(x / size)
            local bz = MathFloor(z / size)
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
    ---@return NavTree?
    FindRoot = function(self, position)
        return self:FindRootXZ(position[1], position[3])
    end,

    ---@param self NavGrid
    ---@param x number x-coordinate, in world space
    ---@param z number z-coordinate, in world space
    ---@return NavTree?
    FindRootXZ = function(self, x, z)
        if x > 0 and z > 0 then
            local size = self.TreeSize
            local trees = self.Trees

            local bx = MathFloor(x / size)
            local bz = MathFloor(z / size)
            local root = trees[bz][bx] --[[@as NavTree]]
            return root
        end

        return nil
    end,

    ---@param self NavGrid
    ---@param gx number x-coordinate, in grid space
    ---@param gz number z-coordinate, in grid space
    ---@return NavTree?
    FindRootGridspaceXZ = function(self, gx, gz)
        return self.Trees[gz][gx] --[[@as NavTree]]
    end,

    --- Returns the leaf that encompasses the position, or nil if no leaf does
    ---@param self NavGrid
    ---@param position Vector A position in world space
    ---@return NavLeaf?
    FindLeaf = function(self, position)
        return self:FindLeafXZ(position[1], position[3])
    end,

    --- Returns the leaf that encompasses the x / z coordinates, or nil if no leaf does
    ---@param self NavGrid
    ---@param x number x-coordinate, in world space
    ---@param z number z-coordinate, in world space
    ---@return NavLeaf?
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

    --- Draws all trees with the correct layer color
    ---@param self NavGrid
    Draw = function(self)
        for z = 0, LabelCompressionTreesPerAxis - 1 do
            for x = 0, LabelCompressionTreesPerAxis - 1 do
                local tree = self.Trees[z][x]
                tree:Draw(Shared.LayerColors[self.Layer])

                -- draw connections
                for label, sections in tree.Sections do
                    for s = 1, TableGetn(sections) do
                        local section = sections[s] --[[@as (NavSection)]]
                        local neighbors = section.Neighbors
    
                        local color = Shared.LabelToColor(label)
                        for k = 1, TableGetn(neighbors) do
                            local neighbor = NavSections[neighbors[k]]
                            DrawLine(section.Center, neighbor.Center, color)
                        end
                    end
                end
            end
        end
    end,

    --- Draws all trees with their corresponding labels
    ---@param self NavGrid
    DrawLabels = function(self, inset)
        for z = 0, LabelCompressionTreesPerAxis - 1 do
            for x = 0, LabelCompressionTreesPerAxis - 1 do
                local tree = self.Trees[z][x]
                tree:DrawLabels(inset)
            end
        end
    end,
}

local FactoryCompressedLabelTree = {
    __call = function(self)
        local instance = {}
        setmetatable(instance, self)
        instance:OnCreate()
        return instance
    end
}

---@generic T: fa-class
---@param specs T
---@return T
local ClassCompressedLabelTree = function(specs)
    specs.__index = specs
    return setmetatable(specs, FactoryCompressedLabelTree)
end

---@class NavSection
---@field Area number
---@field Center Vector
---@field Identifier NavSectionIdentifier
---@field Label NavLabelIdentifier
---@field Leaves NavLeaf[]
---@field Neighbors NavSectionIdentifier[]
---@field Tree NavTreeIdentifier
---@field HeapFrom NavSectionIdentifier
---@field HeapIdentifier number
---@field HeapAcquiredCosts number
---@field HeapTotalCosts number

---@class NavLeaf 
---@field Root NavTree
---@field Identifier number
---@field Size number               # Element count starting at { bx + ox, bz + oz }, used as a parameter during path finding to determine if a unit can pass
---@field Label number              # Label for efficient `CanPathTo` check
---@field Section number            
---@field px number                 # x-coordinate of center in world space
---@field pz number                 # z-coordinate of center in world space
---@field From? NavLeaf             # Populated during path finding
---@field HeapAcquiredCosts? number     # Populated during path finding
---@field HeapTotalCosts? number        # Populated during path finding
---@field Seen? number              # Populated during path finding

--- A simplified quad tree that acts as a compression of the pathing capabilities of a section of the heightmap
---@class NavTree: table<number, NavLeaf | number>
---@field Identifier number
---@field Center Vector
---@field Labels table<number, number>      # Maps a label to the ratio of area that it occupies in this tree
---@field Leaves table <number, NavLeaf[]>  # Maps a label to the leaves that represent that label, sorted from largest to smallest
---@field Sections table <number, table<number, NavLeaf[]>>
---@field Seen number | nil                 # Used during navigating
---@field Threat number | nil               # Used during navigating
CompressedLabelTree = ClassCompressedLabelTree {

    ---@param self NavTree
    OnCreate = function(self)
        local identifier = GenerateTreeIdentifier()
        self.Identifier = identifier
        NavTrees[identifier] = self
    end,

    ---------------------------------------------------------------------------
    --#region Generation

    --- Scans the area to check whether the labels are uniform.
    ---@param self NavTree
    ---@param x number
    ---@param z number
    ---@param s number
    ---@param rCache NavLabelCache
    CheckArea = function(self, x, z, s, rCache)
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

    --- Creates all the information that is required for a leaf.
    ---@param self any
    ---@param bx number
    ---@param bz number
    ---@param ox number
    ---@param oz number
    ---@param size number
    ---@param label number
    ---@return table
    CreateLeaf = function(self, bx, bz, ox, oz, size,label, statistics)
        -- statistics
        if label >= 0 then
            statistics.PathableLeafs = statistics.PathableLeafs + 1
        else
            statistics.UnpathableLeafs = statistics.UnpathableLeafs + 1
        end

        local identifier = GenerateCellIdentifier()
        local instance = {
            Root = self,
            Identifier = identifier,
            Size = size,
            Label = label,
            px = bx + ox + 0.5 * size,
            pz = bz + oz + 0.5 * size
        }

        -- required for navigation
        NavLeaves[identifier] = instance

        return instance
    end,

    --- Compresses the cache using a quad tree, significantly reducing the amount of data stored. At this point
    --- the label cache only exists of 0s and -1s
    ---@param self NavTree
    ---@param bx number             # Location of top-left corner, in world space
    ---@param bz number             # Location of top-left corner, in world space
    ---@param ox number             # Offset from top-left corner, in local space
    ---@param oz number             # Offset from top-left corner, in local space
    ---@param size number           # Element count starting at { bx + ox, bz + oz }
    ---@param root NavTree
    ---@param rCache NavLabelCache
    ---@param compressionThreshold number
    ---@param layer NavLayers
    Compress = function(self, bx, bz, ox, oz, size, root, rCache, compressionThreshold, layer)

        -- localize for performance
        local CheckArea = self.CheckArea
        local CreateLeaf = self.CreateLeaf

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
            local uniformTopleft, labelTopLeft = CheckArea(self, lx, lz, lh, rCache)
            local uniformTopRight, labelTopRight = CheckArea(self, lx + lh, lz, lh, rCache)
            local uniformBottomleft, labelBottomLeft = CheckArea(self, lx, lz + lh, lh, rCache)
            local uniformBottomRight, labelBottomRight = CheckArea(self, lx + lh, lz + lh, lh, rCache)

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

                LOG("Heh!")

                self[ci] = CreateLeaf(self, bx, bz, lx, lz, ls, labelTopLeft, statistics)
            else

                ----------------------------------------------------------------
                -- case 2: we don't have the same label everywhere

                self[ci] = next

                local index

                index = next
                if uniformTopleft then
                    self[index] = CreateLeaf(self, bx, bz, lx, lz, lh, labelTopLeft, statistics)
                else
                    if lh <= compressionThreshold then
                        self[index] = CreateLeaf(self, bx, bz, lx, lz, lh, -1, statistics)
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
                    self[index] = CreateLeaf(self, bx, bz, lx + lh, lz, lh, labelTopRight, statistics)
                else

                    if lh <= compressionThreshold then
                        self[index] = CreateLeaf(self, bx, bz, lx + lh, lz, lh, -1, statistics)
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
                    self[index] = CreateLeaf(self, bx, bz, lx, lz + lh, lh, labelBottomLeft, statistics)
                else
                    if lh <= compressionThreshold then
                        self[index] = CreateLeaf(self, bx, bz, lx, lz + lh, lh, -1, statistics)
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
                    self[index] = CreateLeaf(self, bx, bz, lx + lh, lz + lh, lh, labelBottomRight, statistics)
                else
                    if lh <= compressionThreshold then
                        self[index] = CreateLeaf(self, bx, bz, lx + lh, lz + lh, lh, -1, statistics)
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

    --- Flattens the tree into a leaf.
    ---@see Compress
    ---@param self NavTree
    ---@param bx number             # Location of top-left corner, in world space
    ---@param bz number             # Location of top-left corner, in world space
    ---@param ox number             # Offset from top-left corner, in local space
    ---@param oz number             # Offset from top-left corner, in local space
    ---@param size number           # Element count starting at { bx + ox, bz + oz }
    ---@param label -1 | 0
    ---@param layer NavLayers
    Flatten = function(self, bx, bz, ox, oz, size, root, label, layer)
        self[1] = self:CreateLeaf(bx, bz, ox, oz, size, label, NavLayerData[layer])
    end,

    --- Generates the neighbors of all leaves.
    ---@param self NavLeaf
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

    ---@param self NavTree
    ---@param stack table
    ---@param layer NavLayers
    GenerateLabels = function(self, stack, layer)

        -- local scope for performance
        local type = type

        for k = 1, TableGetn(self) do
            local instance = self[k]
            local isLeaf = type(instance) == "table"
            if isLeaf then

            -- check if we are unassigned (labels start at 1)
            if instance.Label == 0 then

                -- we can hit a stack overflow if we do this recursively, therefore we do a
                -- depth first search using a stack that we re-use for better performance
                local free = 1
                local label = GenerateLabelIdentifier()

                NavLabels[label] = {
                    Area = 0,
                    Node = instance --[[@as NavLeaf]] ,
                    Layer = layer,
                    NumberOfExtractors = 0,
                    NumberOfHydrocarbons = 0,
                    ExtractorMarkers = {},
                    HydrocarbonMarkers = {},
                }

                local metadata = NavLabels[label]

                -- assign the label, and then search through our neighbors to assign the same label to them
                self.Label = label
                metadata.Area = metadata.Area + ((0.01 * instance.Size) * (0.01 * instance.Size))

                -- add our pathable neighbors to the stack
                for k = 1, TableGetn(instance) do
                    local neighbor = NavLeaves[ instance[k] ]
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
                        local neighbor = NavLeaves[ other[k] ]
                        if neighbor.Label == 0 then
                            stack[free] = neighbor
                            free = free + 1
                        end
                    end
                end
            end

            end
        end
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Functionality

    --- Returns all leaves in a table
    ---@param self NavTree
    ---@param cache? NavLeaf[]
    ---@return NavLeaf[]
    ---@return number
    FindLeaves = function(self, cache)
        local head = 1
        cache = cache or {}

        -- gather all the leaves
        for k = 1, TableGetn(self) do
            local instance = self[k]
            local isLeaf = type(instance) == "table"
            if isLeaf then
                cache[head] = instance
                head = head + 1
            end
        end

        -- clean up remaining entries in the cache
        for k = head, TableGetn(cache) do
            cache[k] = nil
        end

        return cache, head - 1
    end,

    --- Returns all traversable leaves in a table
    ---@param self NavTree
    ---@param cache? NavLeaf[]
    ---@return NavLeaf[]
    ---@return number
    FindTraversableLeaves = function(self, cache)
        local head = 1
        cache = cache or {}

        -- gather all the leaves
        for k = 1, TableGetn(self) do
            local instance = self[k]
            local isLeaf = type(instance) == "table"
            if isLeaf then
                if instance.Label >= 0 then
                    cache[head] = instance
                    head = head + 1
                end
            end
        end

        -- clean up remaining entries in the cache
        for k = head, TableGetn(cache) do
            cache[k] = nil
        end

        return cache, head - 1
    end,

    ---@param self NavTree
    ---@return NavLeaf?
    FindLeafOfLabel = function(self, label)

        if not self.Labels[label] then
            return nil
        end

        -- gather all the leaves
        for k = 1, TableGetn(self) do
            local instance = self[k]
            local isLeaf = type(instance) == "table"
            if isLeaf then
                if instance.Label >= 0 then
                    cache[head] = instance
                    head = head + 1
                end
            end
        end
    end,

    --- Returns the leaf that encompasses the position, or nil if no leaf does
    ---@param self NavTree
    ---@param bx number             # Location of top-left corner, in world space
    ---@param bz number             # Location of top-left corner, in world space
    ---@param size number           # Element count starting at { bx + ox, bz + oz }
    ---@param position Vector       # A position in world space
    ---@return NavLeaf?
    FindLeaf = function(self, bx, bz, size, position)
        return self:FindLeafXZ(bx, bz, size, position[1], position[3])
    end,

    --- Returns the leaf that encompasses the position, or nil if no leaf does
    ---@param self NavTree
    ---@param bx number             # Location of top-left corner, in world space
    ---@param bz number             # Location of top-left corner, in world space
    ---@param size number           # Element count starting at { bx + ox, bz + oz }
    ---@param x number              # x-coordinate, in world space
    ---@param z number              # z-coordinate, in world space
    ---@return NavLeaf?
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

        return instance --[[@as NavLeaf]]
    end;

    --#endregion

    ---------------------------------------------------------------------------
    --#region Debug functionality

    --- Draws the labels as colors. It can help visualize the state of the navigational mesh.
    ---
    --- Used for debugging
    ---@param self NavTree
    ---@param color Color
    Draw = function(self, color, inset)

        -- local scope for performance
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
                    -- DrawSquare(px - 0.5 * size, pz - 0.5 * size, size, color, inset)
                else
                    DrawSquare(px - 0.5 * size, pz - 0.5 * size, size, 'ff0000', inset)
                end
            end
        end
    end,

    --- Draws the labels as colors. It can help visualize the state of the navigational mesh.
    ---
    --- Used for debugging
    ---@param self NavTree
    DrawLabels = function(self, inset)

        -- local scope for performance
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
                    DrawSquare(px - 0.5 * size, pz - 0.5 * size, size, Shared.LabelToColor(instance.Label), inset)
                else
                    DrawSquare(px - 0.5 * size, pz - 0.5 * size, size, 'ff0000', inset)
                end
            end
        end
    end,

    --#endregion
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
---@param tCache NavTerrainCache
---@param dCache NavDepthCache
---@param daCache NavAverageDepthCache
---@param pxCache NavHorizontalPathCache
---@param pzCache NavVerticalPathCache
---@param pCache NavPathCache
---@param bCache NavTerrainBlockCache
function PopulateCaches(tCache, dCache, daCache, pxCache, pzCache, pCache, bCache, bx, bz, c)
    local MathAbs = MathAbs
    local GetTerrainHeight = GetTerrainHeight
    local GetSurfaceHeight = GetSurfaceHeight
    local GetTerrainType = GetTerrainType

    -- scan / cache terrain and depth
    for z = 1, c + 1 do
        local absZ = bz + z - 1

        -- local scope to pre-compute `GETTABLE`
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
        -- local scope to pre-compute `GETTABLE`
        local pc = pxCache[z]

        for x = 1, c do
            pc[x] = MathAbs(tCache[z][x] - tCache[z][x + 1]) < MaxHeightDifference
        end
    end

    for z = 1, c do
        -- local scope to pre-compute `GETTABLE`
        local pc = pzCache[z]
        
        for x = 1, c + 1 do
            pc[x] = MathAbs(tCache[z][x] - tCache[z + 1][x]) < MaxHeightDifference
        end
    end

    -- compute cliff walkability
    -- compute average depth
    for z = 1, c do

        -- local scope to pre-compute `GETTABLE`
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
    for z = 1, c do
        local absZ = bz + z
        for x = 1, c do
            local absX = bx + x
            local blocked = (tlx <= absX and brx >= absX) and (tlz <= absZ and brz >= absZ) and
                (not GetTerrainType(absX, absZ).Blocking)
            bCache[z][x] = blocked
        end
    end
end

---@param size number
---@param daCache NavAverageDepthCache
---@param bCache NavTerrainBlockCache
---@param pCache NavPathCache
---@param rCache NavLabelCache
---@return boolean # all blocking
---@return boolean # all pathable
function ComputeLandPathingMatrix(size, daCache, pCache, bCache, rCache)
    local allBlocking = true
    local allPathable = true

    for z = 1, size do
        -- local scope to pre-compute `GETTABLE`
        local bc = bCache[z]
        local dac = daCache[z]
        local pc = pCache[z]
        local rc = rCache[z]

        for x = 1, size do
            local nonBlockingTerrainType = bc[x]
            local isLand = dac[x] <= 0
            local nonBlockingTerrainAngle = pc[x]
            if isLand and nonBlockingTerrainType and nonBlockingTerrainAngle then
                rc[x] = 0
                allBlocking = false
            else
                rc[x] = -1
                allPathable = false
            end
        end
    end

    return allBlocking, allPathable
end

---@param size number
---@param daCache NavAverageDepthCache
---@param bCache NavTerrainBlockCache
---@param pCache NavPathCache
---@param rCache NavLabelCache
---@return boolean # all blocking
---@return boolean # all pathable
function ComputeHoverPathingMatrix(size, daCache, pCache, bCache, rCache)
    local allBlocking = true
    local allPathable = true

    for z = 1, size do
        -- local scope to pre-compute `GETTABLE`
        local bc = bCache[z]
        local dac = daCache[z]
        local pc = pCache[z]
        local rc = rCache[z]

        for x = 1, size do
            local nonBlockingTerrainType = bc[x]
            local sufficientDepth = dac[x] >= 1
            local nonBlockingTerrainAngle = pc[x]

            if nonBlockingTerrainType and (sufficientDepth or nonBlockingTerrainAngle) then
                rc[x] = 0
                allBlocking = false
            else
                rc[x] = -1
                allPathable = false
            end
        end
    end

    return allBlocking, allPathable
end

---@param size number
---@param daCache NavAverageDepthCache
---@param bCache NavTerrainBlockCache
---@param pCache NavPathCache
---@param rCache NavLabelCache
---@return boolean # all blocking
---@return boolean # all pathable
function ComputeNavalPathingMatrix(size, daCache, pCache, bCache, rCache)
    local allBlocking = true
    local allPathable = true

    for z = 1, size do
        -- local scope to pre-compute `GETTABLE`
        local bc = bCache[z]
        local dac = daCache[z]
        local rc = rCache[z]

        for x = 1, size do
            local nonBlockingTerrainType = bc[x]
            local sufficientDepth = dac[x] >= MinWaterDepthNaval

            if sufficientDepth and nonBlockingTerrainType then
                rc[x] = 0
                allBlocking = false
            else
                rc[x] = -1
                allPathable = false
            end
        end
    end

    return allBlocking, allPathable
end

---@param size number
---@param daCache NavAverageDepthCache
---@param bCache NavTerrainBlockCache
---@param pCache NavPathCache
---@param rCache NavLabelCache
---@return boolean # all blocking
---@return boolean # all pathable
function ComputeAmphPathingMatrix(size, daCache, pCache, bCache, rCache)
    local allBlocking = true
    local allPathable = true

    for z = 1, size do
        -- local scope to pre-compute `GETTABLE`
        local bc = bCache[z]
        local dac = daCache[z]
        local pc = pCache[z]
        local rc = rCache[z]

        for x = 1, size do
            local nonBlockingTerrainType = bc[x]
            local notTooDeep = dac[x] <= MaxWaterDepthAmphibious
            local nonBlockingTerrainAngle = pc[x]

            if notTooDeep and nonBlockingTerrainType and nonBlockingTerrainAngle then
                rc[x] = 0
                allBlocking = false
            else
                rc[x] = -1
                allPathable = false
            end
        end
    end

    return allBlocking, allPathable
end

--- Generates the compression grids based on the heightmap
---@param size number (square) size of each cell of the compression grid
---@param threshold number (square) size of the smallest acceptable leafs, used for culling
---@param mapHasWater boolean
local function GenerateCompressionGrids(size, threshold, mapHasWater)

    local navAir = NavGrids['Air'] --[[@as NavGrid]]
    local navLand = NavGrids['Land'] --[[@as NavGrid]]
    local navWater = NavGrids['Water'] --[[@as NavGrid]]
    local navHover = NavGrids['Hover'] --[[@as NavGrid]]
    local navAmphibious = NavGrids['Amphibious'] --[[@as NavGrid]]

    local tCache, dCache, daCache, pxCache, pzCache, pCache, bCache, rCache = InitCaches(size)

    for z = 0, LabelCompressionTreesPerAxis - 1 do
        local bz = z * size
        for x = 0, LabelCompressionTreesPerAxis - 1 do
            local bx = x * size

            local labelTreeAir = CompressedLabelTree()
            labelTreeAir:Flatten(bx, bz, 0, 0, size, labelTreeAir, 0, 'Air')
            navAir:AddTree(z, x, labelTreeAir)

            -- pre-computing the caches is irrelevant layer-wise, so we just pick the Land layer
            PopulateCaches(tCache, dCache, daCache, pxCache, pzCache, pCache, bCache, bx, bz, size)

            local labelTreeLand = CompressedLabelTree()
            navLand:AddTree(z, x, labelTreeLand)
            local allBlocked, allPathable = ComputeLandPathingMatrix(size, daCache, pCache, bCache, rCache)
            if allPathable then
                labelTreeLand:Flatten(bx, bz, 0, 0, size, labelTreeLand, 0, 'Land')
            elseif allBlocked then
                labelTreeLand:Flatten(bx, bz, 0, 0, size, labelTreeLand, -1, 'Land')
            else
                labelTreeLand:Compress(bx, bz, 0, 0, size, labelTreeLand, rCache, threshold, 'Land')
            end

            local labelTreeNaval = CompressedLabelTree()
            navWater:AddTree(z, x, labelTreeNaval)
            local allBlocked, allPathable = ComputeNavalPathingMatrix(size, daCache, pCache, bCache, rCache)
            if allPathable then
                labelTreeNaval:Flatten(bx, bz, 0, 0, size, labelTreeNaval, 0, 'Water')
            elseif allBlocked then
                labelTreeNaval:Flatten(bx, bz, 0, 0, size, labelTreeNaval, -1, 'Water')
            else
                labelTreeNaval:Compress(bx, bz, 0, 0, size, labelTreeNaval, rCache, 2 * threshold, 'Water')
            end

            if mapHasWater then
                local labelTreeHover = CompressedLabelTree()
                navHover:AddTree(z, x, labelTreeHover)
                local allBlocked, allPathable = ComputeHoverPathingMatrix(size, daCache, pCache, bCache, rCache)
                if allPathable then
                    labelTreeHover:Flatten(bx, bz, 0, 0, size, labelTreeHover, 0, 'Hover')
                elseif allBlocked then
                    labelTreeHover:Flatten(bx, bz, 0, 0, size, labelTreeHover, -1, 'Hover')
                else
                    labelTreeHover:Compress(bx, bz, 0, 0, size, labelTreeHover, rCache, threshold, 'Hover')
                end

                local labelTreeAmph = CompressedLabelTree()
                navAmphibious:AddTree(z, x, labelTreeAmph)
                local allBlocked, allPathable = ComputeAmphPathingMatrix(size, daCache, pCache, bCache, rCache)
                if allPathable then
                    labelTreeAmph:Flatten(bx, bz, 0, 0, size, labelTreeAmph, 0, 'Amphibious')
                elseif allBlocked then
                    labelTreeAmph:Flatten(bx, bz, 0, 0, size, labelTreeAmph, -1, 'Amphibious')
                else
                    labelTreeAmph:Compress(bx, bz, 0, 0, size, labelTreeAmph, rCache, threshold, 'Amphibious')
                end
            end
        end
    end
end

--- Generates graphs that we can traverse, based on the compression grids
---@param mapHasWater boolean
local function GenerateGraphs(mapHasWater)
    local navLand = NavGrids['Land'] --[[@as NavGrid]]
    local navWater = NavGrids['Water'] --[[@as NavGrid]]
    local navHover = NavGrids['Hover'] --[[@as NavGrid]]
    local navAmphibious = NavGrids['Amphibious'] --[[@as NavGrid]]
    local navAir = NavGrids['Air'] --[[@as NavGrid]]

    navAir:GenerateNeighbors()
    navAir:GenerateLabels()

    navLand:GenerateNeighbors()
    navLand:GenerateLabels()

    navWater:GenerateNeighbors()
    navWater:GenerateLabels()

    if mapHasWater then
        navHover:GenerateNeighbors()
        navHover:GenerateLabels()

        navAmphibious:GenerateNeighbors()
        navAmphibious:GenerateLabels()
    end
end

--- Culls generated labels that are too small and have no meaning
local function GenerateCullLabels()
    local navLabels = NavLabels

    local culledLabels = 0

    ---@type NavLeaf[]
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
                for k = 1, TableGetn(node) do
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
---@param mapHasWater boolean
local function GenerateMarkerMetadata(mapHasWater)
    local navLabels = NavLabels

    local grids = {
        NavGrids['Land'],
    }

    if mapHasWater then
        TableInsert(grids, NavGrids['Amphibious'])
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
---@param mapHasWater boolean
local function ComputeTreeInformation(mapHasWater)

    local cache = {}
    local size = ScenarioInfo.size[1] / LabelCompressionTreesPerAxis
    local area = ((0.01 * size) * (0.01 * size))

    local grids = {
        NavGrids['Land'],
        NavGrids['Water'],
        NavGrids['Air'],
    }

    if mapHasWater then
        TableInsert(grids, NavGrids['Amphibious'])
        TableInsert(grids, NavGrids['Hover'])
    end

    ---@param a NavLeaf
    ---@param b NavLeaf
    local function SortLeaves(a, b)
        return a.Size > b.Size
    end

    ---@param tree NavTree
    ---@param leaves NavLeaf[]
    ---@param count number
    local function ComputeSections(tree, leaves, count)
        ---@type table <number, NavLeaf[]>
        local output = { }

        -- gather all the leaves
        for k = 1, count do
            local leaf = leaves[k]
            local label = leaf.Label
            if label > 0 then
                if not output[label] then
                    output[label] = { leaf }
                else
                    table.insert(output[label], leaf)
                end
            end
        end

        -- sort the leaves on size, largest to smallest
        for _, leaves in output do
            table.sort(leaves, SortLeaves)
        end

        ---@type NavLeaf[]
        local stack = { }

        local sections = { }
        for label, leaves in output do

            sections[label] = { }

            -- start creating a section of leaves

            local sHead = 1
            for k = 1, TableGetn(leaves) do

                -- for each traversable leaf
                local leaf = leaves[k]

                -- that isn't already part of a section
                if not leaf.Section then

                    -- we create a new section
                    local identifier = GenerateSectionIdentifier()

                    ---@type NavSection
                    local section = {
                        Identifier = identifier,
                        Label = leaf.Label,
                        Neighbors = { },
                        Leaves = { },
                        Tree = tree.Identifier,
                        Center = { 0, 0, 0 }
                    } 

                    NavSections[identifier] = section

                    -- and gather all neighbors of the same tree that share the same label
                    local head = 2
                    stack[1] = leaf
                    while head > 1 do
                        head = head - 1
                        local other = stack[head]

                        if not other.Section then
                            other.Section = identifier
                            TableInsert(section.Leaves, other)
                            for k = 1, TableGetn(other) do
                                local neighbor = NavLeaves[other[k]]
                                if (neighbor.Label == leaf.Label) and (neighbor.Root == tree) and (not neighbor.Section) then
                                    stack[head] = neighbor
                                    head = head + 1
                                end
                            end
                        end
                    end

                    -- sort it from large to small again
                    table.sort(section.Leaves, SortLeaves)

                    local center = section.Leaves[1]
                    local cx = center.px * center.Size
                    local cz = center.pz * center.Size
                    local av = center.Size

                    for k = 1, TableGetn(center) do
                        local neighbor = NavLeaves[center[k]]
                        if neighbor.Root == center.Root and neighbor.Section == center.Section then
                            cx = cx + neighbor.px * neighbor.Size
                            cz = cz + neighbor.pz * neighbor.Size
                            av = av + neighbor.Size
                        end
                    end

                    cx = cx / av
                    cz = cz / av

                    section.Center = { cx, GetSurfaceHeight(cx, cz), cz }

                    if av > 1 then
                        DrawCircle(section.Center, 10, 'ffffff')
                    end

                    sections[label][sHead] = section

                    -- proceed with processing the next section
                    sHead = sHead + 1
                end
            end
        end

        tree.Sections = sections
        tree.Leaves = output
    end

    ---@param tree NavTree
    local function ComputeLabelArea(tree)
        -- sum up the area for the tree as a whole
        local labels = {}
        for label, leaves in tree.Leaves do
            local treeArea = 0
            for k = 1, TableGetn(leaves) do
                local leaf = leaves[k]
                local areaOfLeaf = ((0.01 * leaf.Size) * (0.01 * leaf.Size))
                treeArea = treeArea + areaOfLeaf
            end

            labels[label] = treeArea / area
        end
        tree.Labels = labels

        -- sum up the area for each section of the tree
        for label, sections in tree.Sections do
            for s = 1, TableGetn(sections) do
                local section = sections[s] --[[@as (NavSection)]]
                local sectionArea = 0
                for k = 1, TableGetn(section.Leaves) do
                    local leaf = section.Leaves[k]
                    local areaOfLeaf = ((0.01 * leaf.Size) * (0.01 * leaf.Size))
                    sectionArea = sectionArea + areaOfLeaf
                end

                section.Area = sectionArea / area
            end
        end
    end

    ---@param tree NavTree
    local function ComputeNeighbors(tree)

        local thresholdArea = 0.05

        for label, sections in tree.Sections do
            for s = 1, TableGetn(sections) do

                -- find neighbors for each section
                local section = sections[s] --[[@as (NavSection)]]
                for l = 1, TableGetn(section.Leaves) do
                    local leaf = section.Leaves[l]

                    for n = 1, TableGetn(leaf) do
                        local neighbor = NavLeaves[leaf[n]]
                        local neighborTree = neighbor.Root --[[@as NavTree]]
                        local neighborSection = NavSections[neighbor.Section] --[[@as NavSection]]
                        if (neighbor.Label > 0) and (neighborTree ~= tree) and (neighborSection.Area > thresholdArea) then
                            section.Neighbors[neighborSection.Identifier] = true
                        end
                    end
                end

                section.Neighbors = table.unhash(section.Neighbors)
            end
        end
    end

    -- phase 1

    for _, grid in grids do
        for z = 0, LabelCompressionTreesPerAxis - 1 do
            for x = 0, LabelCompressionTreesPerAxis - 1 do
                ---@type NavTree
                local tree = grid.Trees[z][x]

                local allLeaves, allCount = tree:FindLeaves(cache)
                ComputeSections(tree, allLeaves, allCount)
                ComputeLabelArea(tree)

            end
        end
    end

    -- phase 2

    for _, grid in grids do
        for z = 0, LabelCompressionTreesPerAxis - 1 do
            for x = 0, LabelCompressionTreesPerAxis - 1 do
                ---@type NavTree
                local tree = grid.Trees[z][x]
                ComputeNeighbors(tree)
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
    local MapSize = MathMax(ScenarioInfo.size[1], ScenarioInfo.size[2])

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

    -- check the water ratio
    local brain = GetArmyBrain(1)
    local mapHasWater = brain:GetMapWaterRatio() > 0

    NavGrids['Air'] = NavGrid('Air', CompressionTreeSize)
    NavGrids['Land'] = NavGrid('Land', CompressionTreeSize)
    NavGrids['Water'] = NavGrid('Water', CompressionTreeSize)
    NavGrids['Hover'] = NavGrid('Hover', CompressionTreeSize)
    NavGrids['Amphibious'] = NavGrid('Amphibious', CompressionTreeSize)

    GenerateCompressionGrids(CompressionTreeSize, compressionThreshold, mapHasWater)
    local infoMessage = string.format("generated compression trees: %f", GetSystemTimeSecondsOnlyForProfileUse() - start)
    SPEW(infoMessage)

    GenerateGraphs(mapHasWater)
    local infoMessage = string.format("generated neighbors and labels: %f", GetSystemTimeSecondsOnlyForProfileUse() - start)
    SPEW(infoMessage)

    GenerateMarkerMetadata(mapHasWater)
    local infoMessage = string.format("generated marker metadata: %f", GetSystemTimeSecondsOnlyForProfileUse() - start)
    SPEW(infoMessage)

    GenerateCullLabels()
    local infoMessage = string.format("cleaning up generated data: %f", GetSystemTimeSecondsOnlyForProfileUse() - start)
    SPEW(infoMessage)

    ComputeTreeInformation(mapHasWater)
    local infoMessage = string.format("generated tree information: %f", GetSystemTimeSecondsOnlyForProfileUse() - start)
    SPEW(infoMessage)

    if not mapHasWater then
        NavGrids['Hover'] = NavGrids['Land']
        NavGrids['Amphibious'] = NavGrids['Land']
    end

    local infoMessage = string.format("Generated in %.2f seconds", GetSystemTimeSecondsOnlyForProfileUse() - start)
    print(infoMessage)
    SPEW(infoMessage)

    local allocatedSizeGrids = import('/lua/system/utils.lua').ToBytes(NavGrids) / (1024 * 1024)
    local allocatedSizeLabels = import('/lua/system/utils.lua').ToBytes(NavLabels, { Node = true }) / (1024 * 1024)

    local infoMessage = string.format("Allocating %.1fmb memory", allocatedSizeGrids)
    print(infoMessage)
    SPEW(infoMessage)

    SPEW(string.format("Allocated megabytes for labels: %f", allocatedSizeLabels))
    SPEW(string.format("Number of labels: %f", LabelIdentifier))
    SPEW(string.format("Number of cells: %f", CellIdentifier))
    SPEW(reprs(NavLayerData))

    Sync.NavLayerData = NavLayerData
    Generated = true

    -- allows debugging tools to function
    import("/lua/sim/navdebug.lua")
end
