
local Thread = false 

local function TerrainScanThread()
    while true do 
        WaitSeconds(0.1)
        local coordinates = GetMouseWorldPos()
        if coordinates and coordinates.x and coordinates.z then 
            SimCallback({Func = 'ScanTerrain', Args = { x = coordinates.x, z = coordinates.z, radius = 4 }})
        end
    end
end

function ToggleTerrainScan()
    if not Thread then 
        Thread = ForkThread(TerrainScanThread)
    else 
        KillThread(Thread)
        Thread = false
    end
end

