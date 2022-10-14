--****************************************************************************
--**  File     :  /lua/sim/MarkerGenerator.lua
--**  Authored by (Jip) Willem Wijnia - shared under the GPL V3 license
--****************************************************************************

local Model = import("/lua/sim/MarkerGeneratorCache.lua")

-- upvalue scope for performance
local MathMax = math.max
local MathMin = math.min
local MathAbs = math.abs
local GetTerrainType = GetTerrainType
local GetTerrainHeight = GetTerrainHeight

local labelColors = { "CD9575", "915C83", "841B2D", "FAEBD7", "008000", "8DB600", "FBCEB1", "00FFFF", "7FFFD4", "D0FF14", "4B5320", "8F9779", "E9D66B", "B2BEB5", "87A96B", "27346F", "FF9966", "A52A2A", "FDEE00", "568203", "007FFF", "F0FFFF", "89CFF0", "A1CAF1", "F4C2C2", "FEFEFA", "FF91AF", "FAE7B5", "DA1884", "7C0A02", "848482", "BCD4E6", "9F8170", "F5F5DC", "2E5894", "9C2542", "FFE4C4", "3D2B1F", "967117", "CAE00D", "BFFF00", "FE6F5E", "BF4F51", "000000", "3D0C02", "1B1811", "3B2F2F", "54626F", "3B3C36", "BFAFB2", "FFEBCD", "A57164", "318CE7", "ACE5EE", "FAF0BE", "660000", "0000FF", "1F75FE", "0093AF", "0087BD", "0018A8", "333399", "0247FE", "A2A2D0", "6699CC", "0D98BA", "064E40", "5DADEC", "126180", "8A2BE2", "7366BD", "4D1A7F", "5072A7", "3C69E7", "DE5D83", "79443B", "E3DAC9", "006A4E", "87413F", "CB4154", "66FF00", "D891EF", "C32148", "1974D2", "FFAA1D", "FF55A3", "FB607F", "004225", "CD7F32", "88540B", "AF6E4D", "1B4D3E", "7BB661", "FFC680", "800020", "DEB887", "A17A74", "CC5500", "E97451", "8A3324", "BD33A4", "702963", "536872", "5F9EA0", "A9B2C3", "91A3B0", "006B3C", "ED872D", "E30022", "FFF600", "A67B5B", "4B3621", "A3C1AD", "C19A6B", "EFBBCC", "FFFF99", "FFEF00", "FF0800", "E4717A", "00BFFF", "592720", "C41E3A", "00CC99", "960018", "D70040", "FFA6C9", "B31B1B", "56A0D3", "ED9121", "00563F", "703642", "C95A49", "ACE1AF", "007BA7", "2F847C", "B2FFFF", "246BCE", "DE3163", "007BA7", "2A52BE", "6D9BC3", "1DACD6", "007AA5", "E03C31", "F7E7CE", "F1DDCF", "36454F", "232B2B", "E68FAC", "DFFF00", "7FFF00", "FFB7C5", "954535", "E23D28", "DE6FA1", "A8516E", "AA381E", "856088", "FFB200", "7B3F00", "D2691E", "58111A", "FFA700", "98817B", "E34234", "CD607E", "E4D00A", "9FA91F", "7F1734", "0047AB", "D2691E", "6F4E37", "B9D9EB", "F88379", "8C92AC", "B87333", "DA8A67", "AD6F69", "CB6D51", "996666", "FF3800", "FF7F50", "F88379", "893F45", "FBEC5D", "B31B1B", "6495ED", "FFF8DC", "2E2D88", "FFF8E7", "81613C", "FFBCD9", "FFFDD0", "DC143C", "9E1B32", "A7D8DE", "F5F5F5", "00FFFF", "00B7EB", "58427C", "FFD300", "F56FA1", "666699", "654321", "5D3954", "26428B", "008B8B", "536878", "B8860B", "013220", "006400", "1A2421", "BDB76B", "483C32", "534B4F", "543D37", "8B008B", "4A5D23", "556B2F", "FF8C00", "9932CC", "03C03C", "301934", "8B0000", "E9967A", "8FBC8F", "3C1414", "8CBED6", "483D8B", "2F4F4F", "177245", "00CED1", "9400D3", "00703C", "555555", "DA3287", "FAD6A5", "B94E48", "004B49", "FF1493", "FF9933", "00BFFF", "4A646C", "7E5E60", "1560BD", "2243B6", "C19A6B", "EDC9AF", "696969", "1E90FF", "D71868", "967117", "00009C", "EFDFBB", "E1A95F", "555D50", "C2B280", "1B1B1B", "614051", "F0EAD6", "1034A6", "16161D", "7DF9FF", "00FF00", "6F00FF", "CCFF00", "BF00FF", "8F00FF", "50C878", "6C3082", "1B4D3E", "B48395", "AB4B52", "CC474B", "563C5C", "00FF40", "96C8A2", "C19A6B", "801818", "B53389", "DE5285", "F400A1", "E5AA70", "9FD170", "4D5D53", "4F7942", "6C541E", "FF5470", "683068", "B22222", "CE2029", "E95C4B", "E25822", "EEDC82", "A2006D", "FFFAF0", "15F4EE", "5FA777", "014421", "228B22", "A67B5B", "856D4D", "0072BB", "FD3F92", "86608E", "9EFD38", "D473D4", "FD6C9E", "C72C48", "F64A8A", "77B5FE", "8806CE", "E936A7", "FF00FF", "C154C1", "CC397B", "C74375", "E48400", "87421F" }
local MaxHeightDifference = 0.75
local MaxWaterDepthAmphibious = 25
local MinWaterDepthNaval = 2.0

--- Determines whether the slope of the terrain is too much to path
---@param x number x coordinate of the terrain cell, starting at 1 - should be an integer
---@param z number z coordinate of a terrain cell, starting at 1 - should be an integer
local function CanPathSlope(x, z) 

    local a = GetTerrainHeight(x - 1,z - 1)
    local b = GetTerrainHeight(x - 1,z    )
    local c = GetTerrainHeight(x,    z    )
    local d = GetTerrainHeight(x,    z - 1) 
    
    return MathMax(MathAbs(a-b), MathAbs(b-c), MathAbs(c-d), MathAbs(d-a)) <= MaxHeightDifference
end

--- Determines whether the slope of the terrain is too much to path
---@param x number x coordinate of the terrain cell, starting at 1
---@param z number z coordinate of a terrain cell, starting at 1
local function CanPathTerrain(x, z) 
    local t = GetTerrainType(x, z) 
    return t ~= 'Dirt09' and t ~= 'Lava01' 
end

--- Determines whether this location is shallow enough for amphibious units
---@param surface number height of the surface
---@param terrain number height of the terrain
local function CanAmphPathWater(surface,terrain) 
    return terrain + (MaxWaterDepthAmphibious or 0) > surface 
end

--- Determines whether this location is deep enough for naval units
---@param surface number height of the surface
---@param terrain number height of the terrain
local function CanNavalPathWater(surface,terrain) 
    return surface - (MinWaterDepthNaval or 0) > terrain 
end

local PathSlabs = { }
local WaterSlabs = { }
local TerrainHeightSlabs = { }
local SurfaceHeightSlabs = { }

---@class PathingMarker

---@class IMAPCell
---@field X number                               Horizontal cell index
---@field Z number                               Vertical cell index 
---@field Markers table<PathingMarker>           Markers
---@field NoLandObstructions boolean             Flag that indicates that there are no terrain obstructions
---@field NoWaterObstructions boolean            Flag that indicates that there are no water obstructions
local IMAPCell = ClassSimple {

    ---@param self IMAPCell
    ---@param ix number          Horizontal cell index
    ---@param cx number          Horizontal cell size in ogrids
    ---@param cz number          Vertical cell index
    ---@param cz number          Vertical cell size in ogrids
    ---@return IMAPCell
    __init = function(self, ix, cx, iz, cz)
        self.X = ix
        self.Z = iz
        self.CX = cx 
        self.CZ = cz 

        self.MaximumNumberOfTags = cx * cz

        self.Tags = { }
        self.TagsData = { }
        self.Markers = { }


        self.Obstructed = false
        self.NoObstructions = true

        self:PopulateCell()
    end,

    PopulateCell = function(self)

        -- localize for performance

        local cz = self.CZ
        local z = self.Z
        local cx = self.CX
        local x = self.X
        local tags = self.Tags
        local data = self.TagsData

        -- gather information of this cell

        for lz = 1, cz do 
            local z = lz + z * cz
            for lx = 1, cx do 
                local x = lx + x * cx

                -- keep track of tag count

                local tag = PathSlabs[z][x]
                if tag < -1 then 
                    tag = -1 
                end

                tags[tag] = (tags[tag] or 0) + 1

                -- keep track of tag data

                if not (data[tag]) then 
                    data[tag] = {
                        -- BoundingBox = { L = 4096, R = 0, T = 4096, B = 0 },
                        Center = { X = 0, Z = 0 }
                    }
                end

                local center = data[tag].Center
                center.X = center.X + x
                center.Z = center.Z + z

                -- data.BoundingBox.L = MathMin(data.BoundingBox.L, x)
                -- data.BoundingBox.R = MathMax(data.BoundingBox.R, x)
                -- data.BoundingBox.T = MathMin(data.BoundingBox.T, z)
                -- data.BoundingBox.B = MathMax(data.BoundingBox.B, z)
            end
        end

        -- post processing

        -- compute center for iMAP
        for tag, count in tags do 
            data[tag].Center.X = math.floor((1 / count) * data[tag].Center.X + 0.5)
            data[tag].Center.Z = math.floor((1 / count) * data[tag].Center.Z + 0.5)

            local tagAtCenter = PathSlabs[data[tag].Center.Z][data[tag].Center.X]
            data[tag].Obstructed = tagAtCenter ~= tag or tag == -1
        end

        self.Obstructed = self.Tags[-1] > (0.9 * self.MaximumNumberOfTags)
        self.NoObstructions = not self.Tags[-1]

    end,

    Draw = function(self)

        for tag, count in self.Tags do 
            if
                count > 0.1 * self.MaximumNumberOfTags
            then

            local data = self.TagsData[tag]
            local color = labelColors[tag] or 'ff0000'

            if self.TagsData[tag].Obstructed then 
                color = 'ff0000'
            end

            DrawCircle({ data.Center.X, GetSurfaceHeight(data.Center.X, data.Center.Z), data.Center.Z }, 1, color)
            end
        end

    end,

}

function ProcessMap()

    local n = 16 
    local mx = ScenarioInfo.size[1]
    local mz = ScenarioInfo.size[2]

    -- smaller maps have a 8x8 iMAP
    if mx == mz and mx == 5 then 
        n = 8
    end

    local cx = math.floor(mx / n)
    local cz = math.floor(mz / n)

    --  initialize

    local fatboysize = 8
    local minz = 0 
    local maxz = 15

    local startTotal = GetSystemTimeSecondsOnlyForProfileUse()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    -- prepare terrain / surface samples

    for zs = minz, maxz do 
        for zi = 0, cz do 
            local z = zs * cz + zi
            TerrainHeightSlabs[z] = { }
            SurfaceHeightSlabs[z] = { }
            for x = 0, mx do 
                TerrainHeightSlabs[z][x] = GetTerrainHeight(x, z)
                SurfaceHeightSlabs[z][x] = GetSurfaceHeight(x, z)
            end
        end
    end

    local stop = GetSystemTimeSecondsOnlyForProfileUse()
    WARN("Terrain sampling: " .. tostring(stop - start))
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    -- compute pathability / water places

    for zs = minz, maxz do 
        for zi = 1, cz do 

            local z = zs * cz + zi
            PathSlabs[z] = { }
            WaterSlabs[z] = { }
            for x = 1, mx do 

                local a = TerrainHeightSlabs[z - 1][x - 1]
                local b = TerrainHeightSlabs[z - 1][x    ]
                local c = TerrainHeightSlabs[z    ][x    ]
                local d = TerrainHeightSlabs[z    ][x - 1]

                WaterSlabs[z][x] = TerrainHeightSlabs[z][x] + MinWaterDepthNaval < SurfaceHeightSlabs[z][x]
                PathSlabs[z][x] = (MathMax(MathAbs(a-b), MathAbs(b-c), MathAbs(c-d), MathAbs(d-a)) > MaxHeightDifference and -1) or 0
            end
        end
    end

    local stop = GetSystemTimeSecondsOnlyForProfileUse()
    WARN("Pathing checks: " .. tostring(stop - start))
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    -- cheap horizontal scan

    for zs = minz, maxz do
        for zi = 1, cz do
            local z = zs * cz + zi

            local d = 0
            local x = 1
            while x < mx do 
                if PathSlabs[z][x] == -1 then

                    -- cull to the left
                    if d > fatboysize then
                        d = fatboysize
                    end

                    for lx = 1, d do 

                        -- negative value
                        local value = -1 * lx - 1

                        -- early exit
                        if PathSlabs[z][x - lx] == -1 then 
                            break 
                        end

                        if PathSlabs[z][x - lx] > value then
                            PathSlabs[z][x - lx] = value
                        end
                    end

                    -- cull to the right
                    local skip = 1
                    for rx = 1, fatboysize do 

                        -- negative value
                        local value = -1 * rx - 1

                        -- early exit
                        if PathSlabs[z][x + rx] == -1 then 
                            break 
                        end
                        
                        skip = skip + 1

                        if PathSlabs[z][x + rx] > value then 
                            PathSlabs[z][x + rx] = value
                        end
                    end

                    d = 0
                    x = x + skip
                else 
                    d = d + 1
                    x = x + 1
                end
            end
        end
    end

    local stop = GetSystemTimeSecondsOnlyForProfileUse()
    WARN("Horizontal Fatboy sweep: " .. tostring(stop - start))
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    -- cheap vertical scan 

    for x = 1, mx do 

        local d = 0
        local zi = 1 
        while zi < ((maxz - minz) + 1) * cz do 
            local z = minz * cz + zi

            if (PathSlabs[z][x] <= -1) then 

                local v = PathSlabs[z][x]
                local c = (fatboysize + 1) + PathSlabs[z][x]

                -- cull to the top, backwards
                for tx = 1, c do
                    local value = v - tx

                    -- early exit
                    if (PathSlabs[z - tx][x] > value and (PathSlabs[z - tx][x] ~= 0)) or ((z - tx) < 1) then
                        break
                    end

                    PathSlabs[z - tx][x] = value
                end

                -- cull to the bottom, forwards
                local skip = 1
                for bx = 1, c do 
                    local value = v - bx

                    -- early exit
                    if (PathSlabs[z + bx][x] > value and (PathSlabs[z + bx][x] ~= 0)) or ((z + bx) > mz) then
                        break
                    end

                    skip = skip + 1
                    PathSlabs[z + bx][x] = value
                end

                d = 0
                zi = zi + skip
            else 
                d = d + 1
                zi = zi + 1
            end
        end
    end

    local stop = GetSystemTimeSecondsOnlyForProfileUse()
    WARN("Vertical Fatboy sweep: " .. tostring(stop - start))
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    -- flooding to label

    local tag = 1
    local qx = { }
    local qz = { }
    local qh = 1 

    local function AddNeighbours(z, x)
        for lz = -1, 1 do
            for lx = -1, 1 do
                if
                    PathSlabs[z + lz][x + lx] ~= nil and
                    PathSlabs[z + lz][x + lx] == 0
                then
                    -- assign a tag
                    PathSlabs[z + lz][x + lx] = tag

                    -- search around this entry
                    qx[qh] = x + lx
                    qz[qh] = z + lz
                    qh = qh + 1
                end
            end
        end
    end

    for z = 1, mz do 
        for x = 1, mx do 
            if PathSlabs[z][x] == 0 then 
                PathSlabs[z][x] = tag
                AddNeighbours(z, x)
            
                while (qh > 1) do 
                    qh = qh - 1 
                    local lx = qx[qh]
                    local lz = qz[qh]
                    AddNeighbours(lz, lx)
                end

                tag = tag + 1
            end
        end
    end

    local stop = GetSystemTimeSecondsOnlyForProfileUse()
    WARN("Labelling: " .. tostring(stop - start))
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    -- edge detection for drawing

    for z = 1, mz do 
        for x = 1, mx do 
            local uniform = true 
            local tag = PathSlabs[z][x]
            for lz = -1, 1 do
                for lx = -1, 1 do
                    uniform = uniform and (tag == PathSlabs[z + lz][x + lx])
                end
            end

            if not uniform then 
                qx[qh] = x 
                qz[qh] = z
                qh = qh + 1
            end
        end
    end

    local stop = GetSystemTimeSecondsOnlyForProfileUse()
    WARN("Edge detection: " .. tostring(stop - start))
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    -- cells 

    local cells = { }
    for z = 0, cx do 
        cells[z] = { }
        for x = 0, cx do 
            cells[z][x] = IMAPCell(x, cx, z, cz)
        end
    end

    local stop = GetSystemTimeSecondsOnlyForProfileUse()
    WARN("iMAP creation: " .. tostring(stop - start))

    local stopTotal = GetSystemTimeSecondsOnlyForProfileUse()
    WARN("Total time taken: " .. tostring(stopTotal - startTotal))
    -- 

    -- test 

    local cliffDistanceColors = {
        'ff0000',
        'ee0000',
        'dd0000',
        'cc0000', 
        'bb0000',
        'aa0000',
        '990000',
        '880000',
        '770000',
        '660000',
        '550000',
        '440000',
        '330000',        
        '220000',
        '110000',
        '000000',
    }

    ForkThread(
        function()
            while true do 

                local labelColorsN = table.getn(labelColors)

                for z = 0, cx do 
                    for x = 0, cx do 
                        cells[z][x]:Draw()
                    end
                end

                for i = 1, qh - 1 do 
                    local x = qx[i]
                    local z = qz[i]

                    local value = PathSlabs[z][x]
                    if value == -1 then 
                        -- DrawCircle({x, GetSurfaceHeight(x, z), z}, 0.25, 'ff0000')
                    elseif value < -1 then 
                        -- DrawCircle({x, GetSurfaceHeight(x, z), z}, 0.25, cliffDistanceColors[-1 * value + 1])
                    elseif value > 0 then 

                        while value > labelColorsN do 
                            value = value - labelColorsN
                        end

                        DrawCircle({x, GetSurfaceHeight(x, z), z}, 0.25, labelColors[value])
                    end
                end

                WaitSeconds(0.1)
            end
        end
    )

end
