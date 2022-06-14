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

local FatboyCheckSize = 8 

local CellCache = { }
local CellCacheCount = 0 

local Cells = { }

--- Processes the given cell
---@param surface number height of the surface
---@param terrain number height of the terrain
local function ProcessCell(x0, z0, x1, z1)

    -- only process the cell once
    if Cells[x0][z0] then 
        return Cells[x0][z0]
    end

    -- # pre-process it

    local Land = { }
    local Amph = { }
    local Naval = { }

    for z = z0 - FatboyCheckSize, z1 + FatboyCheckSize do 

        Land[z] = { }
        Amph[z] = { }
        Naval[z] = { }

        for x = x0 - FatboyCheckSize, x1 + FatboyCheckSize do 
            local color = 'ffffff'

            local surface = GetSurfaceHeight(x + 0.5, z + 0.5)
            local terrain = GetTerrainHeight(x + 0.5, z + 0.5)

            Land[z][x] = CanPathSlope(x, z) and CanPathTerrain(x, z)
            Amph[z][x] = CanAmphPathWater(surface, terrain) and CanPathSlope(x, z) and CanPathTerrain(x, z)
            Naval[z][x] = CanAmphPathWater(surface, terrain)
        end
    end

    -- # process it

    local ViableLand = { }
    local ViableAmph = { }
    local ViableNaval = { }

    for z = z0, z1 do 
        ViableLand[z] = { }
        ViableAmph[z] = { }
        ViableNaval[z] = { }
        for x = x0, x1 do 

            local viableLand = true 
            local viableAmph = true 
            local viableNaval = true 
            
            for fz = -FatboyCheckSize, FatboyCheckSize do 
                for fx = -FatboyCheckSize, FatboyCheckSize do 
                    viableLand = viableLand and Land[z + fz][x + fx]
                    viableAmph = viableAmph and Amph[z + fz][x + fx]
                    viableNaval = viableNaval and Naval[z + fz][x + fx]
                end
            end

            ViableLand[z][x] = viableLand
            ViableAmph[z][x] = viableAmph
            ViableNaval[z][x] = viableNaval
        end
    end

    -- # visualize it

    for z = z0, z1 do 
        for x = x0, x1 do 
            if ViableLand[z][x] then 
                DrawCircle({x + 0.5, GetSurfaceHeight(x + 0.5, z + 0.5), z + 0.5 }, 0.25, 'ffffff')
            else 
                DrawCircle({x + 0.5, GetSurfaceHeight(x + 0.5, z + 0.5), z + 0.5 }, 0.15, '999999')
            end
        end
    end

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

    ForkThread(
        function()
            while true do 

                local start = GetSystemTimeSecondsOnlyForProfileUse()
                for x = 4, 8 do 
                    for z = 0, 3 do 
                        ProcessCell(cx * x, cz * z, cx * (x + 1), cz * (z + 1))
                    end
                end
                local stop = GetSystemTimeSecondsOnlyForProfileUse()
                LOG(stop - start)

                WaitSeconds(0.1)
            end
        end
    )
end
