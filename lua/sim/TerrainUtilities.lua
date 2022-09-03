
-- upvalue scope for performance
local MathMax = math.max
local MathMin = math.min
local MathAbs = math.abs
local GetTerrainType = GetTerrainType
local GetTerrainHeight = GetTerrainHeight

local MaxHeightDifference = 0.75
local MaxWaterDepthAmphibious = 25
local MinWaterDepthNaval = 2.0

--- Determines whether the slope of the terrain is too much to path
---@param x number x coordinate of the terrain cell, starting at 1 - should be an integer
---@param z number z coordinate of a terrain cell, starting at 1 - should be an integer
function CanPathSlope(x, z) 

    local a = GetTerrainHeight(x - 1,z - 1)
    local b = GetTerrainHeight(x - 1,z    )
    local c = GetTerrainHeight(x,    z    )
    local d = GetTerrainHeight(x,    z - 1)
    
    return MathMax(MathAbs(a-b), MathAbs(b-c), MathAbs(c-d), MathAbs(d-a)) <= MaxHeightDifference
end

--- Determines whether the slope of the terrain is too much to path
---@param x number x coordinate of the terrain cell, starting at 1
---@param z number z coordinate of a terrain cell, starting at 1
function CanPathTerrain(x, z) 
    local t = GetTerrainType(x, z)
    return t ~= 'Dirt09' and t ~= 'Lava01'
end

--- Determines whether this location is shallow enough for amphibious units
---@param surface number height of the surface
---@param terrain number height of the terrain
function CanAmphPathWater(surface,terrain)
    return terrain + (MaxWaterDepthAmphibious or 0) > surface
end

--- Determines whether this location is deep enough for naval units
---@param surface number height of the surface
---@param terrain number height of the terrain
function CanNavalPathWater(surface,terrain)
    return surface - (MinWaterDepthNaval or 0) > terrain
end

function ScanTerrain()
    reprsl(GetMouseWorldPos())
end

---@type thread
local terrainScanningThread = nil

---@type boolean
local pauseTerrainScanning = nil

function TerrainScanningThread()
    while true do 

        while not pauseTerrainScanning do

        end

        -- 
        SuspendCurrentThread()
    end
end


--- 
---@param enable any
function ToggleTerrainScanning(enable)

    pauseTerrainScanning = enable

    if enable then
        if not terrainScanningThread then
            terrainScanningThread = ForkThread(TerrainScanningThread)
        else
            ResumeThread(terrainScanningThread)
        end
    end
end

