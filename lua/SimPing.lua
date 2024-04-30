local SUtils = import("/lua/ai/sorianutilities.lua")

local PingLimit = 1 -- Maximum number of pings per army, within PingTimeout seconds
local PingTimeout = 1 -- How many seconds a ping counts toward an army's limit
local PingsRemaining = {}
local PingMarkers = {}
MaxPingMarkers = 15
--On first ping, send data to the user layer telling it the maximum allowable markers per army
Sync.MaxPingMarkers = MaxPingMarkers

---@param entity Entity
---@param lifetime? number
function AnimatePingMesh(entity, lifetime)
    local time = 0
    if lifetime then
        while entity and lifetime > 0 do
            entity:SetScale(MATH_Lerp(math.sin(time), -0.5, 0.5, 0.3, 0.5))
            time = time + 0.3
            WaitSeconds(0.1)

            lifetime = lifetime - 0.1
        end
        entity:Destroy()
    else
        while entity do
            entity:SetScale(MATH_Lerp(math.sin(time), -0.5, 0.5, 0.3, 0.5))
            time = time + 0.3
            WaitSeconds(0.1)
        end
    end
end

function SpawnPing(data)
    if not PingsRemaining[data.Owner] then
        PingsRemaining[data.Owner] = PingLimit
    end

    if PingsRemaining[data.Owner] > 0 then
        if data.Marker and PingMarkers[data.Owner] and table.getsize(PingMarkers[data.Owner]) >= MaxPingMarkers then
            return
        elseif data.Marker and not PingMarkers[data.Owner] then
            PingMarkers[data.Owner] = {}
        end
        PingsRemaining[data.Owner] = PingsRemaining[data.Owner] - 1

        if data.Marker and GetPingID(data.Owner) then
            data.ID = GetPingID(data.Owner)
            PingMarkers[data.Owner][data.ID] = data
        else
            SpawnPingMesh(data)
        end

        SendData(data)

        -- Callbacks to allied brains
        for num,brain in ArmyBrains do
            if data.Owner + 1 ~= num and IsAlly(num, data.Owner + 1) then
                ArmyBrains[num]:DoPingCallbacks(data)
                if not SUtils.IsAIArmy(data.Owner + 1) then
                    ArmyBrains[num]:DoAIPing(data)
                end
            end
        end

        ForkThread(DelayPingCountThread, data.Owner)
    end
end

function DelayPingCountThread(owner)
    WaitSeconds(PingTimeout)

    PingsRemaining[owner] = PingsRemaining[owner] + 1
end

function SpawnSpecialPing(data)
    --This function is used to generate automatic nuke pings
    SpawnPingMesh(data)
    SendData(data)

    -- Callbacks to allied brains
    for num,brain in ArmyBrains do
        if data.Owner + 1 ~= num and IsAlly(num, data.Owner + 1) then
            ArmyBrains[num]:DoPingCallbacks(data)
            if not SUtils.IsAIArmy(data.Owner + 1) then
                ArmyBrains[num]:DoAIPing(data)
            end
        end
    end
end

function SpawnPingMesh(data)
    local Entity = import("/lua/sim/entity.lua").Entity
    data.Location[2] = data.Location[2] + 2
    local pingSpec = {Owner = data.Owner, Location = data.Location}
    local ping = Entity(pingSpec)
    Warp(ping, Vector(data.Location[1], data.Location[2], data.Location[3]))
    ping:SetVizToFocusPlayer("Always")
    ping:SetVizToEnemies("Never")
    ping:SetVizToAllies("Always")
    ping:SetVizToNeutrals("Never")
    ping:SetMesh("/meshes/game/ping_" .. data.Mesh)
    ForkThread(AnimatePingMesh, ping, data.Lifetime)
end

function GetPingID(owner)
    for i = 1, MaxPingMarkers do
        if not PingMarkers[owner][i] then
            return i
        end
    end
    return false
end

function OnArmyDefeat(armyID)
    armyID = armyID - 1
    if PingMarkers[armyID] then
        for i, v in PingMarkers[armyID] do
            UpdateMarker({Action = 'delete', ID = i, Owner = v.Spec.Owner})
        end
    end
end

function OnArmyChange()
    Sync.MaxPingMarkers = MaxPingMarkers
    --Flush all of the current markers on the UI side
    if not Sync.Ping then Sync.Ping = {} end
    table.insert(Sync.Ping, {Action = 'flush'})
    --Add All of the relevant marker data on the next sync
    local focus = GetFocusArmy()
    if focus ~= -1 then
        ForkThread(RenewAllPingsTo, focus)
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
            local focus = GetFocusArmy()
            if focus ~= -1 then
                ForkThread(RenewAllPingsTo, focus)
            end
            return
        end
        SendData(data)
    end
end

---@param focus Army
function RenewAllPingsTo(focus)
    for ownerID, pingTable in PingMarkers do
        if IsAlly(ownerID + 1, focus) then
            for _, ping in pingTable do
                ping.Renew = true
                SendData(ping)
            end
        end
    end
end

function SendData(data)
    local focus = GetFocusArmy()
    if focus ~= -1 and IsAlly(data.Owner+1, focus) then
        if not Sync.Ping then Sync.Ping = {} end
        table.insert(Sync.Ping, data)
    end
end
