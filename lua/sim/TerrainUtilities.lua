
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

    local a = GetTerrainHeight(x - 0.5,z - 1)
    local b = GetTerrainHeight(x - 0.5,z    )
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

---@class TerrainScanningData
---@field Center Vector
---@field Size number
---@field SlopeCheck boolean[][]
---@field TypeCheck boolean[][]
---@field NavalCheck boolean[][]
---@field AmphCheck boolean[][]

local samplesPerBlock = 16
local numberOfBlocks = math.max(ScenarioInfo.size[1] / samplesPerBlock, ScenarioInfo.size[2] / samplesPerBlock)

---@type number[][]
local BlockCacheTerrain = { }

---@type number[][]
local BlockCacheSurface = { }

local function MouseToBlock(position)
    local ix = (position[1] / numberOfBlocks) ^ 0
    local iz = (position[3] / numberOfBlocks) ^ 0
    return ix, iz
end

local function PopulateCache(ix, iz)

    -- store as locals for optimal access
    local GetTerrainHeight = GetTerrainHeight
    local GetSurfaceHeight = GetSurfaceHeight

    -- offset for taking samples
    local ox = ix * samplesPerBlock
    local oz = iz * samplesPerBlock

    -- sample the block
    for lz = 0, samplesPerBlock do
        
        BlockCacheTerrain[lz + 1] = BlockCacheTerrain[lz + 1] or { }
        BlockCacheSurface[lz + 1] = BlockCacheSurface[lz + 1] or { }

        for lx = 0, samplesPerBlock do
            BlockCacheTerrain[lz + 1][lx + 1] = GetTerrainHeight(ox + lx, oz + lz)
            BlockCacheSurface[lz + 1][lx + 1] = GetSurfaceHeight(ox + lx, oz + lz)
        end
    end
end

local function ScanBlock(ix, iz)
    PopulateCache(ix, iz)

    -- loop over cache, determine pathability
    for lz = 1, iz do
        for lx = 1, ix do
            
        end
    end
end

function TerrainScanningThread()

    local size = 20

    ---@type TerrainScanningData
    local data = { 
        -- data surrounding the
        Center = { },
        Size = size,

        SlopeCheck = { },
        TypeCheck = { },
        NavalCheck = { },
        AmphCheck = { },
    }

    for z = -size, size do
        data.SlopeCheck[z] = data.SlopeCheck[z] or { }
        data.TypeCheck[z] = data.TypeCheck[z] or { }
        data.NavalCheck[z] = data.NavalCheck[z] or { }
        data.AmphCheck[z] = data.AmphCheck[z] or { }
    end

    while true do

        while enableTerrainScanning do

            -- with thanks to: https://github.com/FAForever/FA-Binary-Patches/commit/88dc4ddaffbc06ff2bcff051dfe20d1dbaf18727
            local center = GetMouseWorldPos()

            -- check if cursor location is valid
            if center and center[1] and center[3] then

                -- clamp center to map
                center[1] = math.clamp(center[1], 0, ScenarioInfo.size[1])
                center[3] = math.clamp(center[3], 0, ScenarioInfo.size[2])

                -- determine block to scan
                local ix, iz = MouseToBlock(center)
                ScanBlock(ix, iz)
            end

            -- -- average them using bankers rule
            -- center[1] = (center[1] ^ 0) + 0.5
            -- center[3] = (center[3] ^ 0) + 0.5

            -- -- check if we have moved
            -- if not (data.Center[1] == center[1] and data.Center[3] == center[3]) or true then
            --     LOG("Doing a scan!")
            --     data.Center = center

            --     local lxs1 = 0
            --     local lxt1 = 0
            --     local lxs2 = 0
            --     local lxt2 = 0

            --     -- gather data
            --     local location = { }
            --     for z = -size, size do
            --         for x = -size, size do

            --             location[1] = center[1] + x
            --             location[3] = center[3] + z

            --             local surfaceHeight = GetSurfaceHeight(location[1], location[3])
            --             local terrainHeight = GetTerrainHeight(location[1], location[3])

            --             data.SlopeCheck[z][x] = CanPathSlope(location[1], location[3])
            --             data.TypeCheck[z][x] = CanPathTerrain(location[1], location[3])
            --             data.NavalCheck[z][x] = CanNavalPathWater(surfaceHeight, terrainHeight)
            --             data.AmphCheck[z][x] = CanAmphPathWater(surfaceHeight, terrainHeight)
            --         end
            --     end

            --     -- pass it to the UI
            --     Sync.TerrainScanningData = data
            -- end



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

