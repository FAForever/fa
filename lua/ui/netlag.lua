local HEADROOM       = 2    -- buffer value (avg + dev*<headroom>).  dev is std-deviation
local MIN_NETLAG     = 0    -- minimum net_lag value (milliseconds)
local MAX_NETLAG     = 600  -- maximum net_lag value (milliseconds)
local HISTORY_SIZE   = 10   -- size of ping history, used for avg / dev

local clientData = {}
local WorstPing = 0;

-- {clients: [{id: 1, name: 'Crotalus', ping: 25.5}]}
function UpdateClientPings(clients)
    local newClientData = {}

    for index, client in clients do
        local data = clientData[client.id] or {ping=0, avg=0, dev=0, reldev=0, history={}}
        data.ping = client.ping
        table.insert(data.history, 1, data.ping)
        data.history[HISTORY_SIZE+1] = nil -- truncate

        local i, n = 0, math.min(HISTORY_SIZE, table.getsize(data.history))
        local avg, dev = 0, 0
        for i=1, n do
            avg = avg + data.history[i]
        end

        data.avg = avg / n

        -- calculate standard deviation
        for i=1, n do
            dev = dev + math.pow(data.avg - data.history[i], 2)
        end
        data.dev = math.sqrt(dev/n)
        if data.avg > 0 then data.reldev = data.dev / data.avg end

        WorstPing = math.max(WorstPing, data.avg + data.dev*HEADROOM)
        newClientData[client.id] = data
    end

    clientData = newClientData
end

function UpdateNetworkSettings(gameOptions)
    local zeroDelay = false

    if gameOptions.NetLag ~= '500' then
        local lag
        if gameOptions.NetLag == 'adaptive' then
            local ping = math.ceil((WorstPing + 50) / 50) * 50
            lag = math.clamp(ping, MIN_NETLAG, MAX_NETLAG)
        else
            lag = gameOptions.NetLag
        end

        ConExecute('net_lag ' .. lag)
        gameOptions.NetLag = lag -- So we send the decided netLag to the other players
        zeroDelay = true
    end

    if gameOptions.NetworkLimits == 'experimental' then
        ConExecute('net_MaxSendRate 4096') -- from 2048
        ConExecute('net_MaxBacklog 4096') -- from 2048
        ConExecute('net_MinResendDelay 50') -- from 100
        ConExecute('net_MaxResendDelay 500') -- from 1000
        zeroDelay = true
    end

    if zeroDelay then
        ConExecute('net_AckDelay 0') -- from 25
        ConExecute('net_SendDelay 0') -- from 25
    end
end

