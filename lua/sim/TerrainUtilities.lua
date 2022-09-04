
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
local enableTerrainScanning = nil

function TerrainScanningThread()

    local size = 6

    local data = { }
    for z = -size, size do
        data[z] = { }
        for x = -size, size do
            data[z][x] = { }
        end
    end

    while true do
        while enableTerrainScanning do

            -- with thanks to: https://github.com/FAForever/FA-Binary-Patches/commit/88dc4ddaffbc06ff2bcff051dfe20d1dbaf18727
            local center = GetMouseWorldPos()

            -- average them using bankers rule
            center[1] = (center[1] ^ 0) + 0.5
            center[3] = (center[3] ^ 0) + 0.5

            -- gather data
            local location = { }
            for z = -size, size do
                for x = -size, size do
                    location[1] = center[1] + x
                    location[3] = center[3] + z

                    local surfaceHeight = GetSurfaceHeight(location[1], location[3])
                    local terrainHeight = GetTerrainHeight(location[1], location[3])

                    local land = CanPathSlope(location[1], location[3]) and CanPathTerrain(location[1], location[3]) and surfaceHeight == terrainHeight
                    local naval = CanNavalPathWater(surfaceHeight, terrainHeight)
                    local amph = CanPathSlope(location[1], location[3]) and CanPathTerrain(location[1], location[3]) and CanAmphPathWater(surfaceHeight, terrainHeight)

                    if land then
                        location[2] = GetTerrainHeight(location[1], location[3])
                        DrawCircle(location, 0.4, '32cd32')
                    elseif amph then
                        location[2] = GetTerrainHeight(location[1], location[3])
                        DrawCircle(location, 0.4, 'ffa500')
                    end

                    if naval then
                        location[2] = GetSurfaceHeight(location[1], location[3])
                        DrawCircle(location, 0.4, '3333ff')
                    end
                end
            end

            WaitTicks(1)
        end

        -- lie idle, waiting in the dark forest until we are required again
        WaitTicks(1)
        SuspendCurrentThread()
    end
end


--- 
---@param enable any
function ToggleTerrainScanning(enabled)

    -- switch it up
    enableTerrainScanning = enabled

    -- allocate or resume the thread
    if enabled then
        if not terrainScanningThread then
            terrainScanningThread = ForkThread(TerrainScanningThread)
        else
            ResumeThread(terrainScanningThread)
        end
    end
end

