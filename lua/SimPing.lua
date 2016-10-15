local SUtils = import('/lua/ai/sorianutilities.lua')

local PingMarkers = {}
MaxPingMarkers = 15
--On first ping, send data to the user layer telling it the maximum allowable markers per army
Sync.MaxPingMarkers = MaxPingMarkers

function AnimatePingMesh(entity)
    local time = 0
    local ascending = true
    while entity do
        local orien = entity:GetOrientation()
        entity:SetScale(MATH_Lerp(math.sin(time), -.5, 0.5, .3, .5))
        time = time + .3
        WaitSeconds(.1)
    end
end

function SpawnPing(data)
    -- Move ping owner decision sim side to block UI mod exploitation.
    local army = GetFocusArmy()

    if army < 1 then
        WARN("SpawnPing: army cannot be less than 1")
        return
    end

    if data.Marker and PingMarkers[army] and table.getsize(PingMarkers[army]) >= MaxPingMarkers then
        return
    elseif data.Marker and not PingMarkers[army] then
        PingMarkers[army] = {}
    end

    if data.Marker and GetPingID(army) then
        data.ID = GetPingID(army)
        PingMarkers[army][data.ID] = data
    else
        local Entity = import('/lua/sim/Entity.lua').Entity
        data.Location[2] = data.Location[2]+2

        -- Entity.Owner needs armyIndex - 1 internally, so here we actually needs to offset when creating a special ping entity
        local pingSpec = {Owner = army - 1, Location = data.Location}
        local ping = Entity(pingSpec)
        Warp(ping, Vector(data.Location[1], data.Location[2], data.Location[3]))
        ping:SetVizToFocusPlayer('Always')
        ping:SetVizToEnemies('Never')
        ping:SetVizToAllies('Always')
        ping:SetVizToNeutrals('Never')
        ping:SetMesh('/meshes/game/ping_'..data.Mesh)
        local animThread = ForkThread(AnimatePingMesh, ping)
        ForkThread(function()
            WaitSeconds(data.Lifetime)
            KillThread(animThread)
            ping:Destroy()
        end)
    end

    data.Owner = army

    SendData(data)
    DoCallbacks(data)
end

function IsVisible(data, army)
    return IsAlly(army, data.Owner) and (not data.To or data.To == army)
end

function DoCallbacks(data)
    for army, brain in ArmyBrains do
        if IsVisible(data, army) then
            brain:DoPingCallbacks(data)
            if not SUtils.IsAIArmy(data.Owner) then
                brain:DoAIPing(data)
            end
        end
    end
end

function SpawnSpecialPing(data)
    -- This function is used to generate automatic nuke pings
    local Entity = import('/lua/sim/Entity.lua').Entity
    data.Location[2] = data.Location[2]+2

    -- Once again, the owner has been through the user layer. Set army in sim to avoid exploitation
    local army = GetFocusArmy()
    if data.Owner ~= army then
        WARN('Nuke ping owner Sim/UI mismatch. Possible exploitation detected. Please investigate')
    end

    local pingSpec = {Owner = army - 1, Location = data.Location}
    local ping = Entity(pingSpec)
    Warp(ping, Vector(data.Location[1], data.Location[2], data.Location[3]))
    ping:SetVizToFocusPlayer('Always')
    ping:SetVizToEnemies('Never')
    ping:SetVizToAllies('Always')
    ping:SetVizToNeutrals('Never')
    ping:SetMesh('/meshes/game/ping_'..data.Mesh)
    local animThread = ForkThread(AnimatePingMesh, ping)
    ForkThread(function()
        WaitSeconds(data.Lifetime)
        KillThread(animThread)
        ping:Destroy()
    end)

    data.Owner = army

    SendData(data)
    DoCallbacks(data)
end

function GetPingID(army)
    for i = 1, MaxPingMarkers do
        if not PingMarkers[army][i] then
            return i
        end
    end
    return false
end

function OnArmyDefeat(armyID)
    if PingMarkers[armyID] then
        for i, v in PingMarkers[armyID] do
            UpdateMarker({Action = 'delete', ID = i, Owner = v.Spec.Owner})
        end
    end
end

function OnArmyChange()
    Sync.MaxPingMarkers = MaxPingMarkers
    LOG('syncing max ping markers: ', MaxPingMarkers)
    --Flush all of the current markers on the UI side
    if not Sync.Ping then Sync.Ping = {} end
    table.insert(Sync.Ping, {Action = 'flush'})
    --Add All of the relevant marker data on the next sync
    local army = GetFocusArmy()
    if army ~= -1 then
        ForkThread(function()
            for ownerID, pingTable in PingMarkers do
                if IsAlly(ownerID, army) then
                    for pingID, ping in pingTable do
                        ping.Renew = true
                        SendData(ping)
                    end
                end
            end
        end)
    end
end

function OnAllianceChange()
    OnArmyChange()
end

function UpdateMarker(data)
    if PingMarkers[data.Owner][data.ID] or data.Action == 'renew' then
        if data.Action == 'delete' then
            PingMarkers[data.Owner][data.ID] = nil
        elseif data.Action == 'move' then
            PingMarkers[data.Owner][data.ID].Location = data.Location
        elseif data.Action == 'rename' then
            PingMarkers[data.Owner][data.ID].Name = data.Name
        elseif data.Action == 'renew' then
            local army = GetFocusArmy()
            if army ~= -1 then
                ForkThread(function()
                    for ownerID, pingTable in PingMarkers do
                        if IsAlly(ownerID, army) then
                            for pingID, ping in pingTable do
                                ping.Renew = true
                                SendData(ping)
                            end
                        end
                    end
                end)
            end
            return
        end
        SendData(data)
    end
end

function SendData(data)
    local army = GetFocusArmy()
    if army ~= -1 and IsVisible(data, army) then
        Sync.Ping = Sync.Ping or {}
        table.insert(Sync.Ping, data)
    end
end
