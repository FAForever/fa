-- Table of ping types
-- All of this data is sent to the sim and back to the UI for display on the world views

PingTypes = {
    nuke = {Lifetime = 10, Mesh = 'nuke_marker', Ring = '/textures/ui/common/game/marker/ring_nuke04-blur.dds', ArrowColor = 'red', Sound = 'Aeon_Select_Radar'},
}

local lastPingData = {}
local redundantPingCheckDistance = 10
local redundantPingCheckTime = 8

function DoNukePing(NukeLaunchData)
    local pingType = 'nuke'
    if SessionIsReplay() or import("/lua/ui/game/gamemain.lua").supressExitDialog or import("/lua/ui/game/gamemain.lua").IsNISMode() then return end
    for _, launchData in NukeLaunchData do
        if not launchData.location then
            -- means it's an enemy nuke
            continue
        end
        local position = launchData.location
        for _, v in position do
            local var = v
            if var ~= v then
                return
            end
        end
        local army = launchData.army

        -- Check ping table do determine if this is another ping near the same place at the same time
        local pingTime = GetGameTimeSeconds()
        local pingOkFlag = false
        if lastPingData[army] then
            -- If data has been set, check it...
            if VDist3(lastPingData[army].loc, position) > redundantPingCheckDistance or lastPingData[army].tm < pingTime - redundantPingCheckTime then
                pingOkFlag = true
                lastPingData[army] = {loc = position, tm = pingTime}
            end
        else
            -- If no data has been set for this army, set some
            lastPingData[army] = {loc = position, tm = pingTime}
            pingOkFlag = true
        end

        if pingOkFlag then
            local data = {Owner = army, Type = pingType, Location = position}
            data = table.merged(data, PingTypes[pingType])
            SimCallback({Func = 'SpawnSpecialPing', Args = data})
        end
    end
end
