--******************************************************************************************************
--** The code in this file is licensed using GNU GPL v3. You can find more information here:
--** - https://www.gnu.org/licenses/gpl-3.0.en.html
--**
--** You can find an informal description of this license here:
--** - https://www.youtube.com/watch?v=sQIVclmxvdQ
--** 
--** This file is maintained by members of and contributors to the Forged Alliance Forever association. 
--** You can find more information here:
--** - www.faforever.com
--**
--** In particular, the following people made significant contributions to this file:
--** - Jip @ https://github.com/Garanas
--** - Softles @ https://github.com/HardlySoftly
--******************************************************************************************************

local Shared = import('/lua/shared/NavGenerator.lua')

---@alias NavTerrainCache number[][]
---@alias NavDepthCache number[][]
---@alias NavAverageDepthCache number[][]
---@alias NavHorizontalPathCache boolean[][]
---@alias NavVerticalPathCache boolean[][]
---@alias NavPathCache boolean[][]
---@alias NavTerrainBlockCache boolean[][]
---@alias NavLabelCache number[][]

-- Tweakable data

local SmallestLabelTree = 4

--- TODO: should this be dynamic, based on playable area?
--- Number of blocks that encompass the map, per axis
---@type number
local BlockCountPerAxis = 16

--- TODO: this approach does not support non-square maps
--- Total width / height of the map
---@type number
local MapSize = ScenarioInfo.size[1]

--- Number of cells per block
---@type number
local BlockSize = MapSize / BlockCountPerAxis

--- Maximum height difference that is considered to be pathable, within a single oGrid
---@type number
local MaxHeightDifference = 0.75

--- Maximum depth that amphibious units consider to be pathable
---@type number
local MaxWaterDepthAmphibious = 25

--- Minimum dept that naval units consider to be pathable
---@type number
local MinWaterDepthNaval = 1.5

-- Generated data

local labelTreeIdentifier = 0

local function GenerateLabelTreeIdentifier()
    labelTreeIdentifier = labelTreeIdentifier + 1
    return labelTreeIdentifier
end

---@class LabelRoots
---@field land? LabelRoot
---@field naval? LabelRoot
---@field hover? LabelRoot
---@field amph? LabelRoot
LabelRoots = { }

--- Scanning thread for debugging utilities
---@type thread?
local ScanningThread = nil

-- Shared data with UI

---@type NavProfileData
local ProfileData = Shared.CreateEmptyProfileData()

---@type NavLayerData
local NavLayerData = Shared.CreateEmptyNavLayerData()

local tl = { 0, 0, 0 }
local tr = { 0, 0, 0 }
local bl = { 0, 0, 0 }
local br = { 0, 0, 0 }

--- Draws a square on the map
---@param px number
---@param pz number
---@param c number
---@param color string
local function DrawSquare(px, pz, c, color, inset)
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

---@class LabelRoot
---@field Layer NavLayers
---@field Trees LabelTree[][]
local LabelRoot = ClassSimple {

    ---@param self LabelRoot
    ---@param layer NavLayers
    __init = function(self, layer)
        self.Trees = { }
        for z = 0, BlockCountPerAxis - 1 do
            self.Trees[z] = { }
            for x = 0, BlockCountPerAxis - 1 do
                self.Trees[z][x] = { }
            end
        end

        self.Layer = layer
        self.FreeLabel = 1
    end,

    --- Adds a (compressed) label tree
    ---@param self LabelRoot
    ---@param z number
    ---@param x number
    ---@param labelTree LabelTree
    AddTree = function (self, z, x, labelTree)
        self.Trees[z][x] = labelTree
    end,

    --- Returns the leaf that encompasses the position, or nil if no leaf does
    ---@param self LabelRoot
    ---@param position Vector A position in world space
    ---@return LabelTree?
    FindLeaf = function(self, position)
        return self:FindLeafXZ(position[1], position[3])
    end,

    --- Returns the leaf that encompasses the x / z coordinates, or nil if no leaf does
    ---@param self LabelRoot
    ---@param x number x-coordinate, in world space
    ---@param z number z-coordinate, in world space
    ---@return LabelTree?
    FindLeafXZ = function(self, x, z)
        if x > 0 and z > 0 then
            local bx = (x / BlockSize) ^ 0
            local bz = (z / BlockSize) ^ 0
            local labelTree = self.Trees[bz][bx]
            if labelTree then
                return labelTree:FindLeafXZ(x, z)
            end
        end

        return nil
    end,

    GenerateNeighbors = function(self)
        for z = 0, BlockCountPerAxis - 1 do
            for x = 0, BlockCountPerAxis - 1 do
                self.Trees[z][x]:GenerateNeighbors(self)
            end
        end
    end,

    --- Generates a unique label for an enclosed area
    ---@param self LabelRoot
    ---@return integer
    GenerateUniqueLabel = function(self)
        self.FreeLabel = self.FreeLabel + 1
        return self.FreeLabel
    end,

    ---@param self LabelRoot
    GenerateLabels = function(self)
        for z = 0, BlockCountPerAxis - 1 do
            for x = 0, BlockCountPerAxis - 1 do
                local tree = self.Trees[z][x]
                local label = self:GenerateUniqueLabel()
                tree:GenerateLabels(label)
            end
        end
    end,

    --- Draws all trees with the correct layer color
    ---@param self any
    Draw = function(self)
        for z = 0, BlockCountPerAxis - 1 do
            for x = 0, BlockCountPerAxis - 1 do
                self.Trees[z][x]:Draw(Shared.colors[self.Layer])
            end
        end
    end,
}

-- defined here, as it is a recursive class
local LabelTree

--- A simplified quad tree to act as a compression of the pathing capabilities of a section of the heightmap
---@class LabelTree
---@field identifier number                     # Unique number used for table operations
---@field layer NavLayers                       # Layer that this label tree is operating on, used for debugging
---@field bx number                             # Location of top-left corner, in world space
---@field bz number                             # Location of top-left corner, in world space
---@field ox number                             # Offset of top-left corner, in world space
---@field oz number                             # Offset of top-left corner, in world space
---@field c number                              # Element count starting at { bx + ox, bz + oz } that describes the square that is covered
---@field children? LabelTree[]                 # Is nil if we are a leaf (label assigned)
---@field label? number                         # Is nil if we are a node (no label assigned)
---@field neighbors? table<number, LabelTree>   # Is nil if we are a node (no label assigned)
LabelTree = ClassSimple {

    ---@param self LabelTree
    ---@param bx number
    ---@param bz number
    ---@param c number
    __init = function(self, layer, bx, bz, c, ox, oz)
        self.identifier = GenerateLabelTreeIdentifier()

        self.layer = layer
        self.bx = bx
        self.bz = bz
        self.c = c

        self.ox = ox or 0
        self.oz = oz or 0

        -- these are technically obsolete, but are here for code readability
        self.children = nil
        self.label = nil
        self.neighbors = nil
    end,

    --- Compresses the cache using a quad tree, significantly reducing the amount of data stored. At this point
    --- the label cache only exists of 0s and -1s
    ---@param self LabelTree
    ---@param rCache NavLabelCache
    Compress = function(self, rCache)

        -- base case, if we're a square of 4 then we skip the children and become very pessimistic
        if self.c <= SmallestLabelTree then
            local value = rCache[self.oz + 1][self.ox + 1]
            local uniform = true
            for z = self.oz + 1, self.oz + self.c do
                for x = self.ox + 1, self.ox + self.c do
                    uniform = uniform and (value == rCache[z][x])
                    if not uniform  then
                        break
                    end
                end
            end

            if uniform then 
                self.label = value

                if self.label >= 0 then 
                    NavLayerData[self.layer].PathableLeafs = NavLayerData[self.layer].PathableLeafs + 1
                else 
                    NavLayerData[self.layer].UnpathableLeafs = NavLayerData[self.layer].UnpathableLeafs + 1
                end
            else 
                self.label = -1
                NavLayerData[self.layer].UnpathableLeafs = NavLayerData[self.layer].UnpathableLeafs + 1
            end

            return
        end

        -- recursive case where we do make children
        local value = rCache[self.oz + 1][self.ox + 1]
        local uniform = true 
        for z = self.oz + 1, self.oz + self.c do
            for x = self.ox + 1, self.ox + self.c do
                uniform = uniform and (value == rCache[z][x])
                if not uniform then
                    break
                end
            end
        end

        if uniform then
            -- we're uniform, so we're good
            self.label = value

            if self.label >= 0 then 
                NavLayerData[self.layer].PathableLeafs = NavLayerData[self.layer].PathableLeafs + 1
            else
                NavLayerData[self.layer].UnpathableLeafs = NavLayerData[self.layer].UnpathableLeafs + 1
            end
        else
            -- we're not uniform, split up to children
            local hc = 0.5 * self.c
            self.children = {
                LabelTree(self.layer, self.bx, self.bz, hc, self.ox, self.oz),
                LabelTree(self.layer, self.bx, self.bz, hc, self.ox + hc, self.oz),
                LabelTree(self.layer, self.bx, self.bz, hc, self.ox, self.oz + hc),
                LabelTree(self.layer, self.bx, self.bz, hc, self.ox + hc, self.oz + hc)
            }

            for k, child in self.children do
                child:Compress(rCache)
            end

            NavLayerData[self.layer].Subdivisions = NavLayerData[self.layer].Subdivisions + 1
        end
    end,

    ---
    ---@param self LabelTree
    ---@param root LabelRoot
    GenerateNeighbors = function(self, root)
        -- we are not valid :(
        if self.label == -1 then
            return
        end

        -- if we have children then we're a node, only leafs can have neighbors
        if self.children then
            for _, child in self.children do
                child:GenerateNeighbors(root)
            end
            return
        end

        -- we are a leaf, so find those neighbors!
        local x1 = self.bx + self.ox
        local z1 = self.bz + self.oz
        local size = self.c
        local x2 = x1 + size
        local z2 = z1 + size
        local x1Outside, z1Outside = x1 - 0.5, z1 - 0.5
        local x2Outside, z2Outside = x2 + 0.5, z2 + 0.5

        local neighbors = {}
        self.neighbors = neighbors

        -- scan top-left -> top-right
        for k = x1, x2 do
            local x = k + 0.5
            DrawCircle({x, GetSurfaceHeight(x, z1Outside), z1Outside}, 0.5, 'ff0000')
            local neighbor = root:FindLeafXZ(x, z1Outside)
            if neighbor then
                k = k + neighbor.c - 1
                if neighbor.label >= 0 then
                    neighbors[neighbor.identifier] = neighbor
                end
            end
        end

        -- scan bottom-left -> bottom-right
        for k = x1, x2 do
            local x = k + 0.5
            DrawCircle({x, GetSurfaceHeight(x, z2Outside), z2Outside}, 0.5, 'ff0000')
            local neighbor = root:FindLeafXZ(x, z2Outside)
            if neighbor then
                k = k + neighbor.c - 1
                if neighbor.label >= 0 then
                    neighbors[neighbor.identifier] = neighbor
                end
            end
        end

        -- scan left-top -> left-bottom
        for k = z1, z2 do
            z = k + 0.5
            DrawCircle({x1Outside, GetSurfaceHeight(x1Outside, z), z}, 0.5, 'ff0000')
            local neighbor = root:FindLeafXZ(x1Outside, z)
            if neighbor then
                k = k + neighbor.c - 1
                if neighbor.label >= 0 then
                    neighbors[neighbor.identifier] = neighbor
                end
            end
        end

        -- scan right-top -> right-bottom
        for k = z1, z2 do
            z = k + 0.5
            DrawCircle({x2Outside, GetSurfaceHeight(x2Outside, z), z}, 0.5, 'ff0000')
            local neighbor = root:FindLeafXZ(x2Outside, z)
            if neighbor then
                k = k + neighbor.c - 1
                if neighbor.label >= 0 then
                    neighbors[neighbor.identifier] = neighbor
                end
            end
        end

        -- scan top-left
        local neighbor = root:FindLeafXZ(x1Outside, z1Outside)
        DrawCircle({x1Outside, GetSurfaceHeight(x1Outside, z1Outside), z1Outside}, 0.5, 'ff0000')
        if neighbor and neighbor.label >= 0 then
            neighbors[neighbor.identifier] = neighbor
        end

        -- scan top-right
        neighbor = root:FindLeafXZ(x2Outside, z1Outside)
        DrawCircle({x2Outside, GetSurfaceHeight(x2Outside, z1Outside), z1Outside}, 0.5, 'ff0000')
        if neighbor and neighbor.label >= 0 then
            neighbors[neighbor.identifier] = neighbor
        end

        -- scan bottom-left
        DrawCircle({x1Outside, GetSurfaceHeight(x1Outside, z2Outside), z2Outside}, 0.5, 'ff0000')
        neighbor = root:FindLeafXZ(x1Outside, z2Outside)
        if neighbor and neighbor.label >= 0 then
            neighbors[neighbor.identifier] = neighbor
        end

        -- scan bottom-right
        DrawCircle({x2Outside, GetSurfaceHeight(x2Outside, z2Outside), z2Outside}, 0.5, 'ff0000')
        neighbor = root:FindLeafXZ(x2Outside, z2Outside)
        if neighbor and neighbor.label >= 0 then
            neighbors[neighbor.identifier] = neighbor
        end
    end,

    ---@param self LabelTree
    ---@param label number
    GenerateLabels = function(self, label)
        -- leaf case
        if self.label then

            -- if we have no label yet
            if self.label == 0 then

                -- assign the label, and then search through our neighbors to assign the same label to them
                self.label = label
                for _, neighbor in self.neighbors do
                    if neighbor.label == 0 then
                        neighbor:GenerateLabels(label)
                    end
                end
            end

            return
        end

        -- node case
        for _, child in self.children do
            child:GenerateLabels(label)
        end
    end,

    --- Returns the leaf that encompasses the position, or nil if no leaf does
    ---@param self LabelTree
    ---@param position Vector A position in world space
    ---@return LabelTree?
    FindLeaf = function(self, position)
        return self:FindLeafXZ(position[1], position[3])
    end,

    --- Returns the leaf that encompasses the position, or nil if no leaf does
    ---@param self LabelTree
    ---@param x number x-coordinate, in world space
    ---@param z number z-coordinate, in world space
    ---@return LabelTree?
    FindLeafXZ = function(self, x, z)
        local x1 = self.bx + self.ox
        local z1 = self.bz + self.oz
        local size = self.c
        -- Check if it's inside our rectangle the first time only
        if x < x1 or x1 + size < x or z < z1 or z1 + size < z then
            return nil
        end
        return self:_FindLeafXZ(x - self.bx, z - self.bz)
    end;

    _FindLeafXZ = function(self, x, z)
        local children = self.children
        if children then
            local hsize = self.c * 0.5
            local hx, hz = self.ox + hsize, self.oz + hsize
            local child
            if z < hz then
                if x < hx then
                    child = children[1] -- top left
                else
                    child = children[2] -- top right
                end
            else
                if x < hx then
                    child = children[3] -- bottom left
                else
                    child = children[4] -- bottom right
                end
            end
            if child then
                return child:_FindLeafXZ(x, z)
            end
        else
            return self
        end
    end;

    ---@param self LabelTree
    ---@param color Color
    Draw = function(self, color, inset)
        if self.label != nil then
            if self.label >= 0 then
                DrawSquare(self.bx + self.ox, self.bz + self.oz, self.c, color, inset)
            end
        else
            for _, child in self.children do
                child:Draw(color, inset)
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
---@param labelTree LabelTree
---@param tCache NavTerrainCache
---@param dCache NavDepthCache
---@param daCache NavAverageDepthCache
---@param pxCache NavHorizontalPathCache
---@param pzCache NavVerticalPathCache
---@param pCache NavPathCache
---@param bCache NavTerrainBlockCache
function PopulateCaches(labelTree, tCache, dCache, daCache, pxCache, pzCache, pCache, bCache)
    local MathAbs = math.abs
    local GetTerrainHeight = GetTerrainHeight
    local GetSurfaceHeight = GetSurfaceHeight
    local GetTerrainType = GetTerrainType

    local size = labelTree.c
    local bx, bz = labelTree.bx, labelTree.bz

    -- scan / cache terrain and depth
    for z = 1, size + 1 do
        local absZ = bz + z
        for x = 1, size + 1 do
            local absX = bx + x
            local terrain = GetTerrainHeight(absX, absZ)
            local surface = GetSurfaceHeight(absX, absZ)

            tCache[z][x] = terrain
            dCache[z][x] = surface - terrain

            -- DrawSquare(x - 0.15, z - 0.15, 0.3, 'ff0000')
        end
    end

    -- scan / cache cliff walkability
    for z = 1, size + 1 do
        for x = 1, size do
            pxCache[z][x] = MathAbs(tCache[z][x] - tCache[z][x + 1]) < MaxHeightDifference
        end
    end

    for z = 1, size do
        for x = 1, size + 1 do
            pzCache[z][x] = MathAbs(tCache[z][x] - tCache[z + 1][x]) < MaxHeightDifference
        end
    end

    -- compute cliff walkability
    -- compute average depth
    -- compute terrain type
    for z = 1, size do
        for x = 1, size do
            pCache[z][x] = pxCache[z][x] and pzCache[z][x] and pxCache[z][x + 1] and pzCache[z + 1][x]
            daCache[z][x] = (dCache[z][x] + dCache[z + 1][x] + dCache[z][x + 1] + dCache[z + 1][x + 1]) * 0.25
            bCache[z][x] = not GetTerrainType(x, z).Blocking

            -- local color = 'ff0000'
            -- if pCache[lz][lx] == 0 then
            --     color = '00ff00'
            -- end

            -- DrawSquare(labelTree.bx + x + 0.35, labelTree.bz + z + 0.35, 0.3, color)
        end
    end
end

---@param labelTree LabelTree
---@param daCache NavAverageDepthCache
---@param bCache NavTerrainBlockCache
---@param pCache NavPathCache
---@param rCache NavLabelCache
function ComputeLandPathingMatrix(labelTree, daCache, pCache, bCache, rCache)
    local size = labelTree.c
    for z = 1, size do
        for x = 1, size do
            if  daCache[z][x] <= 0 and -- should be on land
                bCache[z][x] and       -- should have accessible terrain type
                pCache[z][x]           -- should be flat enough
            then
                rCache[z][x] = 0
                --DrawSquare(labelTree.bx + x + 0.3, labelTree.bz + z + 0.3, 0.4, '00ff00')
            else
                rCache[z][x] = -1
            end
        end
    end
end

---@param labelTree LabelTree
---@param daCache NavAverageDepthCache
---@param bCache NavTerrainBlockCache
---@param pCache NavPathCache
---@param rCache NavLabelCache
function ComputeHoverPathingMatrix(labelTree, daCache, pCache, bCache, rCache)
    local size = labelTree.c
    for z = 1, size do
        for x = 1, size do
            if bCache[z][x] and (        -- should have accessible terrain type
                daCache[z][x] >= 0.01 or -- can either be on water
                pCache[z][x]             -- or on flat enough terrain
            ) then
                rCache[z][x] = 0
                --DrawSquare(labelTree.bx + x + 0.4, labelTree.bz + z + 0.4, 0.2, '00b3b3')
            else
                rCache[z][x] = -1
            end
        end
    end
end

---@param labelTree LabelTree
---@param daCache NavAverageDepthCache
---@param bCache NavTerrainBlockCache
---@param pCache NavPathCache
---@param rCache NavLabelCache
function ComputeNavalPathingMatrix(labelTree, daCache, pCache, bCache, rCache)
    local size = labelTree.c
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

---@param labelTree LabelTree
---@param daCache NavAverageDepthCache
---@param bCache NavTerrainBlockCache
---@param pCache NavPathCache
---@param rCache NavLabelCache
function ComputeAmphPathingMatrix(labelTree, daCache, pCache, bCache, rCache)
    local size = labelTree.c
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

--- Scans and draws the navigational mesh, is controllable by the UI for debugging purposes
function Scan()
    while true do
        local mouse = GetMouseWorldPos()

        LabelRoots['land']:Draw()
        LabelRoots['naval']:Draw()

        local over = LabelRoots['land']:FindLeaf(mouse)
        if over then 
            LOG(over.label)
            if over.label > 0 then
                over:Draw(Shared.labelColors[over.label], 0.1)
                over:Draw(Shared.labelColors[over.label], 0.15)
                over:Draw(Shared.labelColors[over.label], 0.2)
            else
                over:Draw('ff0000', 0.1)
                over:Draw('ff0000', 0.15)
                over:Draw('ff0000', 0.2)
            end

            over:GenerateNeighbors(LabelRoots['land'])
            if over.neighbors then
                for _, neighbor in over.neighbors do
                    neighbor:Draw('22ff22', 0.25)
                end
            end
        end

        WaitTicks(2)

    end
end

--- Generates the navigational mesh from `a` to `z`
function Generate()
    local blockSize = BlockSize

    -- eliminate any previous scanning threads
    if ScanningThread then
        ScanningThread:Destroy()
    end

    ProfileData = Shared.CreateEmptyProfileData()
    NavLayerData = Shared.CreateEmptyNavLayerData()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    WARN("")
    WARN("Generating with: ")
    WARN(string.format(" - BlockCountPerAxis: %d", BlockCountPerAxis))
    WARN(string.format(" - MapSize: %d", MapSize))
    WARN(string.format(" - BlockSize: %d", blockSize))

    WARN("Constructing caches")

    local tCache, dCache, daCache, pxCache, pzCache, pCache, bCache, rCache = InitCaches(blockSize)

    ProfileData.TimeSetupCaches = start - GetSystemTimeSecondsOnlyForProfileUse()
    WARN(string.format("Time spent: %f", ProfileData.TimeSetupCaches))
    WARN("Generating label trees")

    local labelRootLand = LabelRoot('land')
    local labelRootNaval = LabelRoot('naval')
    local labelRootHover = LabelRoot('hover')
    local labelRootAmph = LabelRoot('amph')
    LabelRoots['land'] = labelRootLand
    LabelRoots['naval'] = labelRootNaval
    LabelRoots['hover'] = labelRootHover
    LabelRoots['amph'] = labelRootAmph

    for z = 0, BlockCountPerAxis - 1 do
        local blockZ = z * blockSize
        for x = 0, BlockCountPerAxis - 1 do
            local blockX = x * blockSize
            local labelTreeLand = LabelTree('land', blockX, blockZ, blockSize)
            local labelTreeNaval = LabelTree('naval', blockX, blockZ, blockSize)
            local labelTreeHover = LabelTree('hover', blockX, blockZ, blockSize)
            local labelTreeAmph = LabelTree('amph', blockX, blockZ, blockSize)

            -- pre-computing the caches is irrelevant layer-wise, so we just pick the land layer
            PopulateCaches(labelTreeLand, tCache, dCache,  daCache, pxCache, pzCache,  pCache, bCache)

            ComputeLandPathingMatrix(labelTreeLand,        daCache,                    pCache, bCache, rCache)
            labelTreeLand:Compress(rCache)
            labelRootLand:AddTree(z, x, labelTreeLand)

            ComputeNavalPathingMatrix(labelTreeNaval,      daCache,                    pCache, bCache, rCache)
            labelTreeNaval:Compress(rCache)
            labelRootNaval:AddTree(z, x, labelTreeNaval)

            ComputeHoverPathingMatrix(labelTreeHover,      daCache,                    pCache, bCache, rCache)
            labelTreeHover:Compress(rCache)
            labelRootHover:AddTree(z, x, labelTreeHover)

            ComputeAmphPathingMatrix(labelTreeAmph,        daCache,                    pCache, bCache, rCache)
            labelTreeAmph:Compress(rCache)
            labelRootAmph:AddTree(z, x, labelTreeAmph)
        end
    end

    ProfileData.TimeLabelTrees = GetSystemTimeSecondsOnlyForProfileUse() - start
    WARN(string.format("Time spent: %f", ProfileData.TimeLabelTrees))
    WARN("Generating neighbours")

    labelRootLand:GenerateNeighbors()
    labelRootNaval:GenerateNeighbors()
    labelRootHover:GenerateNeighbors()
    labelRootAmph:GenerateNeighbors()

    ProfileData.TimeLabelTrees = GetSystemTimeSecondsOnlyForProfileUse() - start
    WARN(string.format("Time spent: %f", ProfileData.TimeLabelTrees))
    WARN("Generating labels")

    LabelRoots['land']:GenerateLabels()
    LabelRoots['naval']:GenerateLabels()
    LabelRoots['amph']:GenerateLabels()
    LabelRoots['hover']:GenerateLabels()

    ProfileData.TimeLabelTrees = GetSystemTimeSecondsOnlyForProfileUse() - start
    WARN(string.format("Time spent: %f", ProfileData.TimeLabelTrees))

    -- restart the scanning thread
    ScanningThread = ForkThread(Scan)

    -- pass data to sync
    Sync.NavProfileData = ProfileData
    Sync.NavLayerData = NavLayerData
end

--- Called by the module manager when this module is dirty due to a disk change
function __OnDirtyModule()
    if ScanningThread then
        ScanningThread:Destroy()
    end
end
