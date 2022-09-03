


local IsScanningTerrain = false
function ToggleTerrainScanning()

    -- find the real user index
    local localIndex = 0
    local clients = GetSessionClients()
    for k, client in clients do 
        if client['local'] == true then
            localIndex = k
        end
    end

    -- toggle it
    IsScanningTerrain = not IsScanningTerrain

    -- do simcallback
    SimCallback({
        Func = 'ToggleTerrainScanning',
        Args = { Identifier = localIndex, Enabled = IsScanningTerrain }
    })
end