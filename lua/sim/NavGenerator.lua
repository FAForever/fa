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

local SmallestLabelTree = 1

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


---TODO: properly annotate this
local LabelRoots = { }

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
        self.Layer = layer
        self.Trees = { }
        for z = 0, BlockCountPerAxis - 1 do
            self.Trees[z] = { }
            for x = 0, BlockCountPerAxis - 1 do
                self.Trees[z][x] = { }
            end
        end
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

    GenerateLabels = function(self)

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
                tl = LabelTree(self.layer, self.bx, self.bz, hc, self.ox, self.oz),
                tr = LabelTree(self.layer, self.bx, self.bz, hc, self.ox + hc, self.oz),
                bl = LabelTree(self.layer, self.bx, self.bz, hc, self.ox, self.oz + hc),
                br = LabelTree(self.layer, self.bx, self.bz, hc, self.ox + hc, self.oz + hc)
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
            for k, child in self.children do 
                child:GenerateNeighbors(root)
            end

            return
        end

        -- we are a leaf, so find those neighbors!
        local px = self.bx + self.ox
        local pz = self.bz + self.oz
        local c = self.c

        local neighbor = nil
        self.neighbors = { }
        
        -- scan top-left -> top-right

        for k = px, px + c do
            local x = k + 0.5
            local z = pz - 0.5
            -- DrawCircle({x, GetSurfaceHeight(x, z), z}, 0.5, 'ff0000')
            neighbor = root:FindLeafXZ(x, z)
            if neighbor and neighbor.label >= 0 then
                k = k + neighbor.c - 1
                self.neighbors[neighbor.identifier] = neighbor
            end
        end

        -- -- scan bottom-left -> bottom-right
        for k = px, px + c do 
            
            local x = k + 0.5
            local z = pz + c + 0.5
            -- DrawCircle({x, GetSurfaceHeight(x, z), z}, 0.5, 'ff0000')
            neighbor = root:FindLeafXZ(x, z)
            if neighbor and neighbor.label >= 0 then
                k = k + neighbor.c - 1
                self.neighbors[neighbor.identifier] = neighbor
            end
        end

        -- -- scan left-top -> left-bottom

        for k = pz, pz + c do 
            local x = px - 0.5
            local z = k + 0.5
            -- DrawCircle({x, GetSurfaceHeight(x, z), z}, 0.5, 'ff0000')
            neighbor = root:FindLeafXZ(x, z)
            if neighbor and neighbor.label >= 0 then
                k = k + neighbor.c - 1
                self.neighbors[neighbor.identifier] = neighbor
            end
        end


        -- -- scan right-top -> right-bottom

        for k = pz, pz + c do 
            local x = px + c + 0.5
            local z = k + 0.5
            -- DrawCircle({x, GetSurfaceHeight(x, z), z}, 0.5, 'ff0000')
            neighbor = root:FindLeafXZ(x, z)
            if neighbor and neighbor.label >= 0 then
                k = k + neighbor.c - 1
                self.neighbors[neighbor.identifier] = neighbor

            end
        end

        -- scan top-left

        neighbor = root:FindLeafXZ(px - 0.5, pz - 0.5)
        -- DrawCircle({px - 0.5, GetSurfaceHeight(px - 0.5, pz - 0.5), pz - 0.5}, 0.5, 'ff0000')
        if neighbor and neighbor.label >= 0 then
            self.neighbors[neighbor.identifier] = neighbor
        end

        -- scan top-right

        neighbor = root:FindLeafXZ(px + c + 0.5, pz - 0.5)
        -- DrawCircle({px + c + 0.5, GetSurfaceHeight(px + c + 0.5, pz - 0.5), pz - 0.5}, 0.5, 'ff0000')
        if neighbor and neighbor.label >= 0 then
            self.neighbors[neighbor.identifier] = neighbor
        end

        -- scan bottom-left

        -- DrawCircle({px - 0.5, GetSurfaceHeight(px - 0.5, pz + c + 0.5), pz + c + 0.5}, 0.5, 'ff0000')
        neighbor = root:FindLeafXZ(px - 0.5, pz + c + 0.5)
        if neighbor and neighbor.label >= 0 then
            self.neighbors[neighbor.identifier] = neighbor
        end

        -- scan bottom-right

        -- DrawCircle({px + c + 0.5, GetSurfaceHeight(px + c + 0.5, pz + c + 0.5), pz + c + 0.5}, 0.5, 'ff0000')
        neighbor = root:FindLeafXZ(px + c + 0.5, pz + c + 0.5)
        if neighbor and neighbor.label >= 0 then
            self.neighbors[neighbor.identifier] = neighbor
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
        if x > self.bx + self.ox and x < self.bx + self.ox + self.c then
            if z > self.bz + self.oz and z < self.bz + self.oz + self.c then
                if not self.children then
                    return self
                else
                    for k, child in self.children do 
                        local result = child:FindLeafXZ(x, z)
                        if result then
                            return result
                        end
                    end
                end
            end
        end

        return nil
    end,

    ---@param self LabelTree
    ---@param color Color
    Draw = function(self, color, inset)
        if self.label != nil then
            if self.label >= 0 then
                DrawSquare(self.bx + self.ox, self.bz + self.oz, self.c, color, inset)
            end
        else
            for k, child in self.children do
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
    local tCache, dCache, daCache, pxCache, pzCache, pCache, bCache, rCache = { }, { }, { }, { }, { }, { }, { }, { }

    -- these need one additional element, as they represent the corners / sides of the cell we're evaluating
    for z = 1, cells + 1 do
        tCache[z] = { }
        dCache[z] = { }
        pxCache[z] = { }
        pzCache[z] = { }
        for x = 1, cells + 1 do
            tCache[z][x] = -1
            dCache[z][x] = -1
            pxCache[z][x] = true
            pzCache[z][x] = true
        end
    end

    -- these represent the cell as a whole, and therefore do not need an additional element
    for z = 1, cells do
        pCache[z] = { }
        bCache[z] = { }
        rCache[z] = { }
        daCache[z] = { }
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

    local mathabs = math.abs
    local GetTerrainHeight = GetTerrainHeight
    local GetSurfaceHeight = GetSurfaceHeight
    local GetTerrainType = GetTerrainType

    -- scan / cache terrain and depth
    for z = labelTree.bz, labelTree.bz + labelTree.c do
        local lz = z - labelTree.bz + 1

        for x = labelTree.bx, labelTree.bx + labelTree.c do
            local lx = x - labelTree.bx + 1

            local terrain = GetTerrainHeight(x, z)
            local surface = GetSurfaceHeight(x, z)

            tCache[lz][lx] = terrain
            dCache[lz][lx] = surface - terrain

            -- DrawSquare(x - 0.15, z - 0.15, 0.3, 'ff0000')
        end
    end

    -- scan / cache cliff walkability
    for z = labelTree.bz, labelTree.bz + labelTree.c do
        local lz = z - labelTree.bz + 1
        for x = labelTree.bx, labelTree.bx + labelTree.c - 1 do
            local lx = x - labelTree.bx + 1
            pxCache[lz][lx] = mathabs(tCache[lz][lx] - tCache[lz][lx + 1]) < MaxHeightDifference
        end
    end

    for z = labelTree.bz, labelTree.bz + labelTree.c - 1 do
        local lz = z - labelTree.bz + 1
        for x = labelTree.bx, labelTree.bx + labelTree.c do
            local lx = x - labelTree.bx + 1
            pzCache[lz][lx] = mathabs(tCache[lz][lx] - tCache[lz + 1][lx]) < MaxHeightDifference
        end
    end

    -- compute cliff walkability
    -- compute average depth
    -- compute terrain type
    for z = labelTree.bz, labelTree.bz + labelTree.c - 1 do
        local lz = z - labelTree.bz + 1
        for x = labelTree.bx, labelTree.bx + labelTree.c - 1 do
            local lx = x - labelTree.bx + 1

            pCache[lz][lx] = pxCache[lz][lx] and pzCache[lz][lx] and pxCache[lz][lx+1] and pzCache[lz+1][lx]
            daCache[lz][lx] = 0.25 * (dCache[lz][lx] + dCache[lz + 1][lx] + dCache[lz][lx + 1] + dCache[lz + 1][lx + 1])
            bCache[lz][lx] = not GetTerrainType(x, z).Blocking

            -- local color = 'ff0000'
            -- if pCache[lz][lx] == 0 then
            --     color = '00ff00'
            -- end

            -- DrawSquare(x + 0.35, z + 0.35, 0.3, color)
        end
    end
end

---@param labelTree LabelTree
---@param daCache NavAverageDepthCache
---@param bCache NavTerrainBlockCache
---@param pCache NavPathCache
---@param rCache NavLabelCache
function ComputeLandPathingMatrix(labelTree, daCache, pCache, bCache, rCache)
    for z = labelTree.bz, labelTree.bz + labelTree.c - 1 do
        local lz = z - labelTree.bz + 1
        for x = labelTree.bx, labelTree.bx + labelTree.c - 1 do
            local lx = x - labelTree.bx + 1
            rCache[lz][lx] = (
                -- should be on land
                daCache[lz][lx] <= 0.0 and
                -- should have accessible terrain type
                bCache[lz][lx] and 
                -- should be flat enough
                pCache[lz][lx] and 0)
                -- or this is inaccessible
                or -1

            -- if rCache[lz][lx] == 0 then
            --     DrawSquare(x + 0.30, z + 0.30, 0.4, '00ff00')
            -- end
        end
    end
end

---@param labelTree LabelTree
---@param daCache NavAverageDepthCache
---@param bCache NavTerrainBlockCache
---@param pCache NavPathCache
---@param rCache NavLabelCache
function ComputeHoverPathingMatrix(labelTree, daCache, pCache, bCache, rCache)
    for z = labelTree.bz, labelTree.bz + labelTree.c - 1 do
        local lz = z - labelTree.bz + 1
        for x = labelTree.bx, labelTree.bx + labelTree.c - 1 do
            local lx = x - labelTree.bx + 1
            rCache[lz][lx] = (
                -- should have accessible terrain type
                bCache[lz][lx] and 
                (
                    -- can either be on water
                    daCache[lz][lx] >= 0.01 or
                    -- or on flat enough terrain
                    pCache[lz][lx]
                ) and 0)
                -- or this is inaccessible  
                or -1

            -- if rCache[lz][lx] == 0 then
            --     DrawSquare(x + 0.4, z + 0.4, 0.2, '00b3b3')
            -- end
        end
    end
end

---@param labelTree LabelTree
---@param daCache NavAverageDepthCache
---@param bCache NavTerrainBlockCache
---@param pCache NavPathCache
---@param rCache NavLabelCache
function ComputeNavalPathingMatrix(labelTree, daCache, pCache, bCache, rCache)
    for z = labelTree.bz, labelTree.bz + labelTree.c - 1 do
        local lz = z - labelTree.bz + 1
        for x = labelTree.bx, labelTree.bx + labelTree.c - 1 do
            local lx = x - labelTree.bx + 1
            rCache[lz][lx] = (
                -- should be deep enough
                daCache[lz][lx] >= MinWaterDepthNaval and
                -- should have accessible terrain type
                bCache[lz][lx] and 0)
                -- or this is inaccessible
                or -1

            -- if rCache[lz][lx] == 0 then
            --     DrawSquare(x + 0.45, z + 0.45, 0.1, '0000ff')
            -- end
        end
    end
end

---@param labelTree LabelTree
---@param daCache NavAverageDepthCache
---@param bCache NavTerrainBlockCache
---@param pCache NavPathCache
---@param rCache NavLabelCache
function ComputeAmphPathingMatrix(labelTree, daCache, pCache, bCache, rCache)
    for z = labelTree.bz, labelTree.bz + labelTree.c - 1 do
        local lz = z - labelTree.bz + 1
        for x = labelTree.bx, labelTree.bx + labelTree.c - 1 do
            local lx = x - labelTree.bx + 1
            rCache[lz][lx] = (
                -- should be on land
                daCache[lz][lx] <= MaxWaterDepthAmphibious and
                -- should have accessible terrain type
                bCache[lz][lx] and 
                -- should be flat enough
                pCache[lz][lx] and 0)
                -- or this is inaccessible
                or -1

            -- if rCache[lz][lx] == 0 then
            --     DrawSquare(x + 0.35, z + 0.35, 0.3, 'ffa500')
            -- end
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
            over:Draw('ffffff')
            if over.neighbors then
                for k, neighbor in over.neighbors do 
                    neighbor:Draw('222222', 0.25)
                end
            end
        end

        WaitTicks(2)
    end
end

--- Generates the navigational mesh from `a` to `z`
function Generate()

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
    WARN(string.format(" - BlockSize: %d", BlockSize))


    WARN("Constructing caches")

    local tCache, dCache, daCache, pxCache, pzCache, pCache, bCache, rCache = InitCaches(BlockSize)

    ProfileData.TimeSetupCaches = start - GetSystemTimeSecondsOnlyForProfileUse()
    WARN(string.format("Time spent: %f", ProfileData.TimeSetupCaches))
    WARN("Generating label trees")

    LabelRoots['land'] = (LabelRoot('land') --[[@as LabelRoot]])
    LabelRoots['naval'] = (LabelRoot('naval') --[[@as LabelRoot]])
    LabelRoots['hover'] = (LabelRoot('hover') --[[@as LabelRoot]])
    LabelRoots['amph'] = (LabelRoot('amph') --[[@as LabelRoot]])

    for z = 0, BlockCountPerAxis - 1 do
        for x = 0, BlockCountPerAxis - 1 do

            local labelTreeLand = LabelTree('land', x * BlockSize, z * BlockSize, BlockSize)
            local labelTreeNaval = LabelTree('naval', x * BlockSize, z * BlockSize, BlockSize)
            local labelTreeHover = LabelTree('hover', x * BlockSize, z * BlockSize, BlockSize)
            local labelTreeAmph = LabelTree('amph', x * BlockSize, z * BlockSize, BlockSize)

            -- pre-computing the caches is irrelevant layer-wise, so we just pick the land layer
            PopulateCaches(labelTreeLand, tCache, dCache,    daCache, pxCache, pzCache,  pCache, bCache)

            ComputeLandPathingMatrix(labelTreeLand,           daCache,                    pCache, bCache, rCache)
            labelTreeLand:Compress(rCache)
            LabelRoots['land']:AddTree(z, x, labelTreeLand)

            ComputeNavalPathingMatrix(labelTreeNaval,         daCache,                    pCache, bCache, rCache)
            labelTreeNaval:Compress(rCache)
            LabelRoots['naval']:AddTree(z, x, labelTreeNaval)

            ComputeHoverPathingMatrix(labelTreeHover,       daCache,                    pCache, bCache, rCache)
            labelTreeHover:Compress(rCache)
            LabelRoots['hover']:AddTree(z, x, labelTreeHover)

            ComputeAmphPathingMatrix(labelTreeAmph,         daCache,                    pCache, bCache, rCache)
            labelTreeAmph:Compress(rCache)
            LabelRoots['amph']:AddTree(z, x, labelTreeAmph)
        end
    end

    ProfileData.TimeLabelTrees = start - GetSystemTimeSecondsOnlyForProfileUse()
    WARN(string.format("Time spent: %f", ProfileData.TimeLabelTrees))
    WARN("Generating neighbours")

    LabelRoots['land']:GenerateNeighbors()
    LabelRoots['naval']:GenerateNeighbors()
    LabelRoots['amph']:GenerateNeighbors()
    LabelRoots['hover']:GenerateNeighbors()

    ProfileData.TimeLabelTrees = start - GetSystemTimeSecondsOnlyForProfileUse()
    WARN(string.format("Time spent: %f", ProfileData.TimeLabelTrees))

    -- restart the scanning thread
    ScanningThread = ForkThread(Scan)

    -- pass data to sync
    Sync.NavProfileData = ProfileData
    Sync.NavLayerData = NavLayerData
end

--- Called by the module manager when this module is dirty due to a disk change
function OnDirtyModule()
    if ScanningThread then
        ScanningThread:Destroy()
    end
end
