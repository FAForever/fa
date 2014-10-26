--*************************************************************************************
--**
--**  File     :  /modules/netlag.lua
--**  Author(s):  Duck_42, Crotalus
--**
--**  Summary  :  Automatically adjusts net_lag values based on in game pings
--**
--**  Change Log:
--**
--**  2013.06.16: Initial Version.                                           Duck_42
--**  2013.06.30: Modified query logic to handle concurrency more reliably.  Duck_42
--**  2013.07.08: Re-wrote all the code for deciding net lag values.
--**              New code uses a client-server model instead of a
--**              decentralized approach.                                    Duck_42
--**  2013.07.11: Bugfix                                                     Duck_42
--**  2014.10.15: Use average ping + some refactoring                        Crotalus
--*************************************************************************************
local GameMain = import('/lua/ui/game/gamemain.lua')
local QuerySystem = import('/lua/UserPlayerQuery.lua')

local DEBUG = true

--Configuration Values
local POLL_FREQUENCY = 30   -- Seconds (recommended that this not be less than 10 seconds)
local HEADROOM       = 2.5  -- buffer value (avg + 25 + dev*<headroom>).  dev is std-deviation
local MIN_NETLAG     = 0   -- minimum net_lag value (milliseconds)
local MAX_NETLAG     = 500  -- maximum net_lag value (milliseconds)
local HISTORY_SIZE   = 10   -- size of ping history, used for avg / dev

function Init()
    QuerySystem.AddQueryListener('NetLagUpdateRequest', ReceiveNetLagRequest)
    QuerySystem.AddQueryListener('NetLagUpdateCommand', ReceiveNetLagCommand)
    ForkThread(NetLagThread)
end

netLag = MAX_NETLAG
worstPings = {}
----------------------------------- Common Functions-----------------------------------

local myUid = -1
local isMasterClient = false
local clientData = {}

local optimalValue = MAX_NETLAG

function DLOG(log)
    if(DEBUG) then LOG(log) end
end

-- decides who's master, gathers ping data from the clients
function UpdateClientData()
    local clients = GetSessionClients()
    local minUid = nil
    local worstPing = MIN_NETLAG

    for index, client in clients do
        local data = clientData[index]
        if(not data) then
            data = {ping=0, avg=0, dev=0, reldev=0, history={}}
        end

        if client.connected then
            if(client['local']) then myUid = client.uid end -- find out local players uid
            if(not minUid or client.uid < minId) then minUid = client.uid end
            data.ping = client.ping
            table.insert(data.history, 1, data.ping)
            data.history[HISTORY_SIZE+1] = nil -- truncate

            -- calculate average ping
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
            if(data.avg > 0) then data.reldev = data.dev / data.avg end
            clientData[index] = data
        end
    end

    isMasterClient = minUid == myUid -- client with lowest uid is master
end

function NetLagThread()
    --Check who's master according to the specified polling interval
    --If we are the master, send a request for max ping values

    while(true) do
        UpdateClientData()
        if isMasterClient then ForkThread(SendNetLagRequest) end

        WaitSeconds(POLL_FREQUENCY)
    end
end
-----------------------------------------------------------------------------------------------------



-----------------------------------Master Client Control Functions-----------------------------------

local requestNumber = 0
local ResponseTable = {}
local updatedThisCycle = false


function SendNetLagRequest()
    --Clear the response table and increase the update sequence number
    requestNumber = requestNumber + 1
    ResponseTable = {}
    netLag = MIN_NETLAG
    updatedThisCycle = false

    local armiesInfo = GetArmiesTable()
    local f = armiesInfo.focusArmy
    DLOG('AUTO NETLAG: Master sending net_lag request nr ' .. requestNumber)
    for armyIndex, armyData in armiesInfo.armiesTable do
        qd = { From = f, To = armyIndex, Name='NetLagUpdateRequest', RNumber=requestNumber}
        QuerySystem.Query(qd, ReceiveNetLagAnswer)
    end
end

function SendNetLagChange()
    local armiesInfo = GetArmiesTable()
    local f = armiesInfo.focusArmy
    DLOG('AUTO NETLAG: Master:NetLegUpdateCommand '.. netLag .. 'ms')
    qd = { From = f, To = f, Name='NetLagUpdateCommand', RNumber=requestNumber, worstPings=worstPings, UValue=netLag}
    QuerySystem.Query(qd, ReceiveNetLagCommandAnswer)
end

function ReceiveNetLagAnswer(resultData)
    if resultData.RNumber == requestNumber and not HasClientResponded(resultData.From) then
        DLOG('AUTO NETLAG: ReceiveNetLagAnswer, client='.. resultData.From .. ', Pings= ' .. repr(resultData.Pings))
        ResponseTable[resultData.From] = resultData.Pings
    end

    if AllClientsResponded() and updatedThisCycle == false then
        local worstPing = 0
        updatedThisCycle = true
        for from, pings in ResponseTable do
            worstPings[from] = 0
            for to, data in pings do
                worstPings[from] = math.max(worstPings[from], data.avg + data.dev*HEADROOM)
            end

            worstPing = math.max(worstPing, worstPings[from])
        end
        netLag = math.floor(math.min(math.max(worstPing + 25, MIN_NETLAG), MAX_NETLAG))

        ForkThread(SendNetLagChange)
    end
end

function ReceiveNetLagCommandAnswer()
end
-----------------------------------------------------------------------------------------------------


------------------------------------Slave Client Control Functions-----------------------------------
function DoNetLagChange(value)
    WaitSeconds(2)
    DLOG('AUTO NETLAG: DoNetLagChange, netLag='.. value ..'ms.')
    ConExecute('net_Lag '.. value)
end

function ReceiveNetLagRequest(qd)
    local armiesInfo = GetArmiesTable()
    local f = armiesInfo.focusArmy
    if qd.To == f then
        local clientPings = {}
        for i, data in clientData do
            clientPings[i] = {avg=data.avg, dev=data.dev}
        end
        ad = { From = f, To = qd.From, Name='NetLagUpdateRequest', Pings = clientPings, RNumber=qd.RNumber}
        DLOG('AUTO NETLAG: NetLagUpdateRequest, Pings='.. repr(clientPings))
        QuerySystem.SendResult(qd, ad)
    end
end

function ReceiveNetLagCommand(qd)
    worstPings = qd.worstPings
    ForkThread(DoNetLagChange, qd.UValue)
end
-----------------------------------------------------------------------------------------------------

function HasClientResponded(armyId)
    return ResponseTable[armyId] == true
end

function AllClientsResponded()
    local clients = GetSessionClients()
    local rCount = 0
    local cCount = 0

    for r in ResponseTable do
        rCount = rCount + 1
    end

    for i, clientInfo in clients do
        if clientInfo.connected then
            cCount = cCount + 1
        end
    end

    if cCount == rCount then
        return true
    else
        return false
    end
end
