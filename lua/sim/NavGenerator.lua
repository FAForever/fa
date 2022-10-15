--******************************************************************************************************
--** This file is licensed using GNU GPL v3. You can find more information here:
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

local labelColors = { "CD9575", "915C83", "841B2D", "FAEBD7", "008000", "8DB600", "FBCEB1", "00FFFF", "7FFFD4", "D0FF14", "4B5320", "8F9779", "E9D66B", "B2BEB5", "87A96B", "27346F", "FF9966", "A52A2A", "FDEE00", "568203", "007FFF", "F0FFFF", "89CFF0", "A1CAF1", "F4C2C2", "FEFEFA", "FF91AF", "FAE7B5", "DA1884", "7C0A02", "848482", "BCD4E6", "9F8170", "F5F5DC", "2E5894", "9C2542", "FFE4C4", "3D2B1F", "967117", "CAE00D", "BFFF00", "FE6F5E", "BF4F51", "000000", "3D0C02", "1B1811", "3B2F2F", "54626F", "3B3C36", "BFAFB2", "FFEBCD", "A57164", "318CE7", "ACE5EE", "FAF0BE", "660000", "0000FF", "1F75FE", "0093AF", "0087BD", "0018A8", "333399", "0247FE", "A2A2D0", "6699CC", "0D98BA", "064E40", "5DADEC", "126180", "8A2BE2", "7366BD", "4D1A7F", "5072A7", "3C69E7", "DE5D83", "79443B", "E3DAC9", "006A4E", "87413F", "CB4154", "66FF00", "D891EF", "C32148", "1974D2", "FFAA1D", "FF55A3", "FB607F", "004225", "CD7F32", "88540B", "AF6E4D", "1B4D3E", "7BB661", "FFC680", "800020", "DEB887", "A17A74", "CC5500", "E97451", "8A3324", "BD33A4", "702963", "536872", "5F9EA0", "A9B2C3", "91A3B0", "006B3C", "ED872D", "E30022", "FFF600", "A67B5B", "4B3621", "A3C1AD", "C19A6B", "EFBBCC", "FFFF99", "FFEF00", "FF0800", "E4717A", "00BFFF", "592720", "C41E3A", "00CC99", "960018", "D70040", "FFA6C9", "B31B1B", "56A0D3", "ED9121", "00563F", "703642", "C95A49", "ACE1AF", "007BA7", "2F847C", "B2FFFF", "246BCE", "DE3163", "007BA7", "2A52BE", "6D9BC3", "1DACD6", "007AA5", "E03C31", "F7E7CE", "F1DDCF", "36454F", "232B2B", "E68FAC", "DFFF00", "7FFF00", "FFB7C5", "954535", "E23D28", "DE6FA1", "A8516E", "AA381E", "856088", "FFB200", "7B3F00", "D2691E", "58111A", "FFA700", "98817B", "E34234", "CD607E", "E4D00A", "9FA91F", "7F1734", "0047AB", "D2691E", "6F4E37", "B9D9EB", "F88379", "8C92AC", "B87333", "DA8A67", "AD6F69", "CB6D51", "996666", "FF3800", "FF7F50", "F88379", "893F45", "FBEC5D", "B31B1B", "6495ED", "FFF8DC", "2E2D88", "FFF8E7", "81613C", "FFBCD9", "FFFDD0", "DC143C", "9E1B32", "A7D8DE", "F5F5F5", "00FFFF", "00B7EB", "58427C", "FFD300", "F56FA1", "666699", "654321", "5D3954", "26428B", "008B8B", "536878", "B8860B", "013220", "006400", "1A2421", "BDB76B", "483C32", "534B4F", "543D37", "8B008B", "4A5D23", "556B2F", "FF8C00", "9932CC", "03C03C", "301934", "8B0000", "E9967A", "8FBC8F", "3C1414", "8CBED6", "483D8B", "2F4F4F", "177245", "00CED1", "9400D3", "00703C", "555555", "DA3287", "FAD6A5", "B94E48", "004B49", "FF1493", "FF9933", "00BFFF", "4A646C", "7E5E60", "1560BD", "2243B6", "C19A6B", "EDC9AF", "696969", "1E90FF", "D71868", "967117", "00009C", "EFDFBB", "E1A95F", "555D50", "C2B280", "1B1B1B", "614051", "F0EAD6", "1034A6", "16161D", "7DF9FF", "00FF00", "6F00FF", "CCFF00", "BF00FF", "8F00FF", "50C878", "6C3082", "1B4D3E", "B48395", "AB4B52", "CC474B", "563C5C", "00FF40", "96C8A2", "C19A6B", "801818", "B53389", "DE5285", "F400A1", "E5AA70", "9FD170", "4D5D53", "4F7942", "6C541E", "FF5470", "683068", "B22222", "CE2029", "E95C4B", "E25822", "EEDC82", "A2006D", "FFFAF0", "15F4EE", "5FA777", "014421", "228B22", "A67B5B", "856D4D", "0072BB", "FD3F92", "86608E", "9EFD38", "D473D4", "FD6C9E", "C72C48", "F64A8A", "77B5FE", "8806CE", "E936A7", "FF00FF", "C154C1", "CC397B", "C74375", "E48400", "87421F" }

-- Tweakable data

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

--- TODO: properly annotate this, it is an array of an array of objects?
local LabelTrees = { }

--- Scanning thread for debugging utilities
---@type thread?
local ScanningThread = nil

-- Shared data with UI

---@type NavProfileData
local ProfileData = {
    TimeSetupCaches = 0,
    TimeLabelTrees = 0,
}

---@type NavLayerData
local NavLayerData = {
    land = {
        Trees = 0,
        Subdivisions = 0,
        PathableLeafs = 0,
        UnpathableLeafs = 0
    },
    amph = {
        Trees = 0,
        Subdivisions = 0,
        PathableLeafs = 0,
        UnpathableLeafs = 0
    },
    hover = {
        Trees = 0,
        Subdivisions = 0,
        PathableLeafs = 0,
        UnpathableLeafs = 0
    },
    naval = {
        Trees = 0,
        Subdivisions = 0,
        PathableLeafs = 0,
        UnpathableLeafs = 0
    }
}

local tl = { 0, 0, 0 }
local tr = { 0, 0, 0 }
local bl = { 0, 0, 0 }
local br = { 0, 0, 0 }

--- Draws a square on the map
---@param px number
---@param pz number
---@param c number
---@param color string
local function DrawSquare(px, pz, c, color)
    tl[1], tl[2], tl[3] = px, GetSurfaceHeight(px, pz), pz
    tr[1], tr[2], tr[3] = px + c, GetSurfaceHeight(px + c, pz), pz
    bl[1], bl[2], bl[3] = px, GetSurfaceHeight(px, pz + c), pz + c
    br[1], br[2], br[3] = px + c, GetSurfaceHeight(px + c, pz + c), pz + c

    DrawLine(tl, tr, color)
    DrawLine(tl, bl, color)
    DrawLine(br, bl, color)
    DrawLine(br, tr, color)
end

local LabelTree

--- A simplified quad tree to act as a compression of the pathing capabilities of a section of the heightmap
---@class LabelTree
---@field layer NavLayers           # Layer that this label tree is operating on, used for debugging
---@field bx number                 # Location of top-left corner, in world space
---@field bz number                 # Location of top-left corner, in world space
---@field ox number                 # Offset of top-left corner, in world space
---@field oz number                 # Offset of top-left corner, in world space
---@field c number                  # Element count starting at { bx + ox, bz + oz } that describes the square that is covered
---@field children? LabelTree[]     # Children, is nil if we are assigned a label
---@field label? number             # Label, is nil if we require a subdivision
LabelTree = ClassSimple {

    ---@param self LabelTree
    ---@param bx number
    ---@param bz number
    ---@param c number
    __init = function(self, layer, bx, bz, c, ox, oz)
        self.layer = layer

        self.bx = bx
        self.bz = bz
        self.c = c

        self.ox = ox or 0
        self.oz = oz or 0
        
        -- these are technically obsolete, but are here for code readability
        self.children = nil
        self.label = nil
    end,

    --- Compresses the cache using a quad tree, significantly reducing the amount of data stored
    ---@param self LabelTree
    ---@param rCache number[][]
    Compress = function(self, rCache)

        -- base case, if we're a square of 4 then we skip the children and become very pessimistic
        if self.c <= 4 then
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
            else 
                self.label = -1
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
            -- LOG(" - recursive case: uniform")
            -- we're uniform, so we're good
            self.label = value
        else 
            -- LOG(" - recursive case: children")
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
        end
    end,


    IsBlocked = function(self, x, z)

        if not self.children then
            return false
        end

        -- check when we do have children
    end,

    --- Returns the leaf that encompasses the position, or nil if no leaf does
    ---@param self LabelTree
    ---@param position Vector A position in world space
    ---@return LabelTree?
    FindLeaf = function(self, position)
        if position[1] > self.bx + self.ox and position[1] < self.bx + self.ox + self.c then
            if position[3] > self.bz + self.oz and position[3] < self.bz + self.oz + self.c then
                if not self.children then
                    return self
                else
                    for k, child in self.children do 
                        local result = child:FindLeaf(position)
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
    Draw = function(self, color)
        if self.label != nil then
            if self.label >= 0 then
                DrawSquare(self.bx + self.ox, self.bz + self.oz, self.c, color)
            end
        else
            for k, child in self.children do
                child:Draw(color)
            end
        end
    end,
}

---@param cells number
---@return number[][]
---@return number[][]
---@return number[][]
---@return boolean[][]
---@return boolean[][]
---@return boolean[][]
---@return boolean[][]
---@return number[][]
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
---@param tCache number[][]
---@param dCache number[][]
---@param daCache number[][]
---@param pxCache boolean[][]
---@param pzCache boolean[][]
---@param bCache boolean[][]
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
---@param daCache number[][]
---@param bCache boolean[][]
---@param pCache boolean[][]
---@param rCache number[][]
function ComputeLandPathingField(labelTree, daCache, pCache, bCache, rCache)
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
---@param daCache number[][]
---@param bCache boolean[][]
---@param pCache boolean[][]
---@param rCache number[][]
function ComputeHoverPathingField(labelTree, daCache, pCache, bCache, rCache)
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
---@param daCache number[][]
---@param bCache boolean[][]
---@param pCache boolean[][]
---@param rCache number[][]
function DetermineNavalPathingField(labelTree, daCache, pCache, bCache, rCache)
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
---@param daCache number[][]
---@param bCache boolean[][]
---@param pCache boolean[][]
---@param rCache number[][]
function DetermineAmphPathingField(labelTree, daCache, pCache, bCache, rCache)
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
    local colors = {
        land = '00ff00',
        naval = '0000ff',
        amph = 'ffa500',
        hover = '008080'
    }

    while true do

        local mouse = GetMouseWorldPos()

        for z = 0, BlockCountPerAxis - 1 do
            for x = 0, BlockCountPerAxis - 1 do

                LabelTrees[z][x]['land']:Draw(colors['land'])
                LabelTrees[z][x]['naval']:Draw(colors['naval'])

                for k, tree in LabelTrees[z][x] do
                    local over = tree:FindLeaf(mouse)
                    if over then 
                        over:Draw('ff0000')
                    end
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
    WARN("Constructing label trees")

    local trees = LabelTrees
    for z = 0, BlockCountPerAxis - 1 do
        trees[z] = { }
        for x = 0, BlockCountPerAxis - 1 do
            trees[z][x] = { }

            trees[z][x]['land'] = LabelTree('land', z * BlockSize, x * BlockSize, BlockSize)
            trees[z][x]['naval'] = LabelTree('naval', z * BlockSize, x * BlockSize, BlockSize)
            trees[z][x]['hover'] = LabelTree('hover', z * BlockSize, x * BlockSize, BlockSize)
            trees[z][x]['amph'] = LabelTree('amph', z * BlockSize, x * BlockSize, BlockSize)

            -- pre-computing the caches is irrelevant layer-wise, so we just pick the land layer
            PopulateCaches(trees[z][x]['land'], tCache, dCache,    daCache, pxCache, pzCache,  pCache, bCache)

            ComputeLandPathingField(trees[z][x]['land'],           daCache,                    pCache, bCache, rCache)
            trees[z][x]['land']:Compress(rCache)

            ComputeHoverPathingField(trees[z][x]['hover'],         daCache,                    pCache, bCache, rCache)
            trees[z][x]['hover']:Compress(rCache)

            DetermineNavalPathingField(trees[z][x]['naval'],       daCache,                    pCache, bCache, rCache)
            trees[z][x]['naval']:Compress(rCache)

            DetermineAmphPathingField(trees[z][x]['amph'],         daCache,                    pCache, bCache, rCache)
            trees[z][x]['amph']:Compress(rCache)
        end
    end

    ProfileData.TimeLabelTrees = start - GetSystemTimeSecondsOnlyForProfileUse()
    WARN(string.format("Time spent: %f", ProfileData.TimeLabelTrees))

    -- restart the scanning thread
    ScanningThread = ForkThread(Scan)

    -- pass data to sync
    Sync.NavProfileData = ProfileData
end

--- Called by the module manager when this module is dirty due to a disk change
function OnDirtyModule()
    if ScanningThread then
        ScanningThread:Destroy()
    end
end
