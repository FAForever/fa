--****************************************************************************
--**  File     :  /lua/sim/MarkerGenerator.lua
--**  Authored by (Jip) Willem Wijnia - shared under the GPL V3 license
--****************************************************************************

local Model = import("/lua/sim/MarkerGeneratorCache.lua")

-- upvalue scope for performance
local MathMax = math.max 
local MathAbs = math.abs 
local GetTerrainType = GetTerrainType
local GetTerrainHeight = GetTerrainHeight

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

---comment
---@param cx number Horizontal cell index
---@param cz number Vertical cell index
---@param cw number Width of cell
---@param ch number Height of cell
---@param slabs table Table to use to compute things on
local function Flood(cx, cz, cw, ch, slabs)

    

    for iz = 1, ch do 
        local z = (cz * ch) + iz
        for ix = 1, cw do 
            local x = (cx * cw) + ix 



        end
    end

end

local IMAPCells = { }

---@class PathingMarker

---@class IMAPCell
---@field X number                              # Horizontal cell index
---@field Z number                              # Vertical cell index 
---@field LandMarkers table<PathingMarker>      # Land markers in this cell
---@field WaterMarkers table<PathingMarker>     # Water markers in this cell
---@field AirMarkers table<PathingMarker>       # Air markers in this cell
---@field AmphMarkers table<PathingMarker>      # Amph markers in this cell
---@field NoLandObstructions boolean            # Flag that indicates that there are no terrain obstructions
---@field NoWaterObstructions boolean           # Flag that indicates that there are no water obstructions

--- Populates an IMAP cell with basic data points
---@param cx number         # Horizontal cell index
---@param sx number         # Horizontal cell size in ogrids
---@param ix number         # Slab index (usually 1)
---@param cz any            # Vertical cell index
---@param sz any            # Vertical cell size in ogrids
---@param iz number         # Slab index (usually 1)
---@return IMAPCell
local function CreateIMAPCell(cx, sx, ix, cz, sz, iz)

    local cell = {
        X = cx,
        Z = cz, 

        LandMarkers = { },
        WaterMarkers = { },
        AmphMarkers = { },
        AirMarkers = { },

        NoLandObstructions = true,
        NoWaterObstructions = true,
    }

    for lz = 1, cz do 
        local z = lz + cz * sz
        for lx = 1, cx do 
            local x = lx + cx * sx

            

        end
    end

    return cell
end

function ProcessMap()

    local n = 16 
    local mx = ScenarioInfo.size[1]
    local mz = ScenarioInfo.size[2]

    -- smaller maps have a 8x8 iMAP
    if mx == mz and mx == 5 then 
        n = 8
    end



    local cx = mx / n 
    local cz = mz / n

    -- # initialize

    local minz = 0 
    local maxz = 15

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

    -- cheap horizontal scan

    for zs = minz, maxz do 
        for zi = 1, cz do 
            local z = zs * cz + zi

            local d = 0
            local x = 1 
            while x < mx do 
                if PathSlabs[z][x] == -1 then 

                    -- cull to the left
                    if d > 8 then 
                        d = 8 
                    end

                    for lx = 1, d do 
                        if PathSlabs[z][x - lx] ~= -1 and PathSlabs[z][x - lx] < (8 - lx) then 
                            PathSlabs[z][x - lx] = 8 - lx 
                        end
                    end

                    -- cull to the right
                    local skip = 1
                    for rx = 1, 8 do 
                        if PathSlabs[z][x + rx] == -1 then 
                            break 
                        end
                        
                        skip = skip + 1

                        if PathSlabs[z][x + rx] < (8 - rx) then 
                            PathSlabs[z][x + rx] = 8 - rx 
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

    -- cheap vertical scan 

    for x = 1, mx do 

        local d = 0
        local zi = 1 
        while zi < ((maxz - minz) + 1) * cz do 
            local z = minz * cz + zi

            if (PathSlabs[z][x] == -1) or (PathSlabs[z][x] > 0) then 

                local c = PathSlabs[z][x]
                if c < 0 then 
                    c = 8
                end

                -- cull to the top
                for tx = 1, c do 
                    if
                        PathSlabs[z - tx][x] ~= nil and
                        PathSlabs[z - tx][x] ~= -1  and
                        PathSlabs[z - tx][x] < (c - tx)
                    then 
                        PathSlabs[z - tx][x] = (c - tx)
                    end
                end

                -- cull to the bottom
                local skip = 1
                for bx = 1, c do 
                    
                    skip = skip + 1

                    if 
                        PathSlabs[z + bx][x] ~= nil and
                        PathSlabs[z + bx][x] ~= -1  and
                        PathSlabs[z + bx][x] < (c - bx)
                    then 
                        PathSlabs[z + bx][x] = (c - bx)
                    end
                end

                d = 0
                zi = zi + 1
            else 
                d = d + 1
                zi = zi + 1
            end
        end
    end

    -- generate land markers based




    local stop = GetSystemTimeSecondsOnlyForProfileUse()

    LOG(stop - start)

    -- test 

    local colors = {
        'ffffff',
        '99ffff',
        '44ffff',
        '00ffff', 
        '0099ff',
        '0044ff',
        '0000ff',
        '000099',
        '000044',
        '000000',
    }

    ForkThread(
        function()
            while true do 
                for zs = minz, maxz do 
                    for zi = 1, cz do 
                        local z = zs * cz + zi
                        for x = 1, mx - 1 do 
                            if PathSlabs[z][x] > 0 then 
                                DrawCircle({x, GetSurfaceHeight(x, z), z}, 0.25, colors[PathSlabs[z][x]])
                            elseif PathSlabs[z][x] == -1 then 
                                DrawCircle({x, GetSurfaceHeight(x, z), z}, 0.25, 'ff0000')
                            end
                        end
                    end
                end
                WaitSeconds(0.1)
            end
        end
    )

end
