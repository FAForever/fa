local NukePingTexturePath = ''
--Table of ping types
--All of this data is sent to the sim and back to the UI for display on the world views
PingTypes = {
    nuke = {Lifetime = 10, Mesh = 'nuke_marker', Ring = NukePingTexturePath..'/game/marker/ring_nuke04-blur.dds', ArrowColor = 'red', Sound = 'Aeon_Select_Radar'},
}

local lastPingData = {}
local redundantPingCheckDistance = 10
local redundantPingCheckTime = 8

function DoNukePing(NukeLaunchData)
	local pingType = 'nuke'
    if SessionIsReplay() or import('/lua/ui/game/gamemain.lua').supressExitDialog then return end
    local position = NukeLaunchData.location
    for _, v in position do
        local var = v
        if var != v then
            return
        end
    end
    local army = NukeLaunchData.army
    
    #Check ping table do determine if this is another ping near the same place at the same time
    local pingTime = GetGameTimeSeconds()
    local pingOkFlag = false
    if lastPingData[army] then
    	#if data has been set, check it...
    	if VDist3(lastPingData[army].loc, position) > redundantPingCheckDistance or lastPingData[army].tm < pingTime - redundantPingCheckTime then
    		pingOkFlag = true
    		lastPingData[army] = {loc = position, tm = pingTime}
    	end
    else
    	#if no data has been set for this army, set some
    	lastPingData[army] = {loc = position, tm = pingTime}
    	pingOkFlag = true
    end
    
    if pingOkFlag then
    	local data = {Owner = army, Type = pingType, Location = position, Type = pingType}
    	data = table.merged(data, PingTypes[pingType])
    	SimCallback({Func = 'SpawnSpecialPing', Args = data})
    end
end