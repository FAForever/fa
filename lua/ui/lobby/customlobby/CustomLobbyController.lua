--******************************************************************************************************
--** Copyright (c) 2026 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

-- Lobby logic for the custom lobby, as free functions (the autolobby pattern). The
-- engine instantiates the thin CustomLobbyInstance and forwards its callbacks here,
-- passing itself as `instance`. All state goes to CustomLobbyAuthoritativeModel via its write
-- helpers; the host is authoritative.
--
-- Barebones host-authority flow:
--   host    : OnHosting -> seats itself in slot 1
--   client  : OnConnectionToHostEstablished -> SendData(host, AddPlayer)
--   host    : ProcessAddPlayer -> seats the peer -> broadcasts SetPlayers (full snapshot)
--   everyone: ProcessSetPlayers -> applies the snapshot -> slot rows react
--   ready   : RequestSetReady (intent) -> host applies + broadcasts SetPlayers
--
-- See /lua/ui/lobby/TARGET_ARCHITECTURE.md § 5.

local CustomLobbyAuthoritativeModel = import("/lua/ui/lobby/customlobby/customlobbyauthoritativemodel.lua")
local CustomLobbyModel = import("/lua/ui/lobby/customlobby/customlobbymodel.lua")

--- The live lobby object, set by the first engine callback. UI-triggered intents
--- (RequestSetReady, …) reach the network through it without threading it everywhere.
---@type UICustomLobbyInstance | false
local LobbyInstance = false

-------------------------------------------------------------------------------
--#region Helpers

--- First empty player slot within the active slot count, or nil.
---@param model UICustomLobbyAuthoritativeModel
---@return number | nil
local function FindFreeSlot(model)
    for slot = 1, model.SlotCount() do
        if not model.Players[slot]() then
            return slot
        end
    end
    return nil
end

--- The slot a peer occupies, or nil.
---@param model UICustomLobbyAuthoritativeModel
---@param ownerId UILobbyPeerId
---@return number | nil
local function FindSlotForOwner(model, ownerId)
    for slot = 1, CustomLobbyAuthoritativeModel.MaxSlots do
        local player = model.Players[slot]()
        if player and player.OwnerID == ownerId then
            return slot
        end
    end
    return nil
end

--- A plain per-slot snapshot of all players (false for empty), for the wire.
---@param model UICustomLobbyAuthoritativeModel
---@return table
local function GatherPlayers(model)
    local players = {}
    for slot = 1, CustomLobbyAuthoritativeModel.MaxSlots do
        players[slot] = model.Players[slot]() or false
    end
    return players
end

--- Host broadcasts the authoritative player snapshot to everyone.
---@param instance UICustomLobbyInstance
---@param model UICustomLobbyAuthoritativeModel
local function BroadcastPlayers(instance, model)
    instance:BroadcastData({ Type = 'SetPlayers', Players = GatherPlayers(model) })
end

--- Builds the local player's options from the profile / engine name.
---@param instance UICustomLobbyInstance
---@return UICustomLobbyPlayer
function CreateLocalPlayer(instance)
    local name = instance:GetLocalPlayerName() or import("/lua/user/prefs.lua").GetFromCurrentProfile('Name') or "Player"
    return import("/lua/ui/lobby/lobbycomm.lua").GetDefaultPlayerOptions(name)
end

--#endregion

-------------------------------------------------------------------------------
--#region Connection events

--- Called when we become the host.
---@param instance UICustomLobbyInstance
function OnHosting(instance)
    LobbyInstance = instance

    local model = CustomLobbyAuthoritativeModel.GetSingleton()
    local id = instance:GetLocalPlayerID()
    model.LocalPeerId:Set(id)
    model.HostID:Set(id)
    model.IsHost:Set(true)

    local player = CreateLocalPlayer(instance)
    player.OwnerID = id
    player.StartSpot = 1
    player.PlayerColor = 1
    player.ArmyColor = 1
    CustomLobbyAuthoritativeModel.SetPlayer(model, 1, player)

    instance.Trash:Add(ForkThread(RunBenchmarkThread, instance))
end

--- Called when our connection to the host succeeds.
---@param instance UICustomLobbyInstance
---@param localId UILobbyPeerId
---@param localName string
---@param hostId UILobbyPeerId
function OnConnectionToHostEstablished(instance, localId, localName, hostId)
    LobbyInstance = instance

    local model = CustomLobbyAuthoritativeModel.GetSingleton()
    model.LocalPeerId:Set(localId)
    model.HostID:Set(hostId)
    model.IsHost:Set(false)

    local player = CreateLocalPlayer(instance)
    player.OwnerID = localId
    player.PlayerName = localName or player.PlayerName

    instance:SendData(hostId, { Type = 'AddPlayer', PlayerOptions = player })

    instance.Trash:Add(ForkThread(RunBenchmarkThread, instance))
end

--- Called when the connection fails.
---@param instance UICustomLobbyInstance
---@param reason string
function OnConnectionFailed(instance, reason)
    LOG("CustomLobby: connection failed: " .. tostring(reason))
end

--- Called when a peer disconnects. The host clears its slot and re-broadcasts.
---@param instance UICustomLobbyInstance
---@param peerName string
---@param uid UILobbyPeerId
function OnPeerDisconnected(instance, peerName, uid)
    local model = CustomLobbyAuthoritativeModel.GetSingleton()
    if not model.IsHost() then
        return
    end
    local slot = FindSlotForOwner(model, uid)
    if slot then
        CustomLobbyAuthoritativeModel.ClearPlayer(model, slot)
        BroadcastPlayers(instance, model)
    end
end

--- Called when the game launches. Barebones: not wired yet.
---@param instance UICustomLobbyInstance
function OnGameLaunched(instance)
    LOG("CustomLobby: GameLaunched (launch flow not implemented yet)")
end

--#endregion

-------------------------------------------------------------------------------
--#region Message handlers (run after Validate + Accept)

--- Host seats a connecting peer and broadcasts the new snapshot.
---@param instance UICustomLobbyInstance
---@param data table
function ProcessAddPlayer(instance, data)
    local model = CustomLobbyAuthoritativeModel.GetSingleton()
    local slot = FindFreeSlot(model)
    if not slot then
        WARN("CustomLobby: no free slot for joining peer " .. tostring(data.SenderID))
        return
    end

    ---@type UICustomLobbyPlayer
    local player = data.PlayerOptions
    player.OwnerID = data.SenderID
    player.StartSpot = slot
    player.PlayerColor = slot
    player.ArmyColor = slot
    CustomLobbyAuthoritativeModel.SetPlayer(model, slot, player)

    BroadcastPlayers(instance, model)
end

--- Everyone applies the host's authoritative snapshot.
---@param instance UICustomLobbyInstance
---@param data table
function ProcessSetPlayers(instance, data)
    local model = CustomLobbyAuthoritativeModel.GetSingleton()
    for slot = 1, CustomLobbyAuthoritativeModel.MaxSlots do
        model.Players[slot]:Set(data.Players[slot] or false)
    end
end

--- Host flips a peer's ready flag and re-broadcasts.
---@param instance UICustomLobbyInstance
---@param data table
function ProcessSetReady(instance, data)
    local model = CustomLobbyAuthoritativeModel.GetSingleton()
    local slot = FindSlotForOwner(model, data.SenderID)
    if slot then
        CustomLobbyAuthoritativeModel.SetPlayerField(model, slot, 'Ready', data.Ready and true or false)
        BroadcastPlayers(instance, model)
    end
end

--- Host records a peer's CPU score and re-broadcasts the authoritative table.
---@param instance UICustomLobbyInstance
---@param data table
function ProcessCpuBenchmark(instance, data)
    CustomLobbyModel.SetCpuBenchmark(
        CustomLobbyModel.GetSingleton(), data.SenderID, data.Benchmark)
    BroadcastCpuBenchmarks(instance)
end

--- Everyone applies the host's authoritative CPU-benchmark snapshot.
---@param instance UICustomLobbyInstance
---@param data table
function ProcessSetCpuBenchmarks(instance, data)
    CustomLobbyModel.GetSingleton().CpuBenchmarks:Set(data.Benchmarks)
end

--#endregion

-------------------------------------------------------------------------------
--#region CPU benchmark
--
-- A faithful port of the legacy lobby's CPU stress test (lobby-old.lua). Each peer
-- runs it shortly after connecting; the host owns the table and broadcasts it.
-- The score is a busy-loop duration (lower = faster CPU); skews were no-ops, so
-- they're dropped.

--- Host broadcasts the authoritative CPU-benchmark snapshot to everyone.
---@param instance UICustomLobbyInstance
function BroadcastCpuBenchmarks(instance)
    instance:BroadcastData({
        Type = 'SetCpuBenchmarks',
        Benchmarks = CustomLobbyModel.GetSingleton().CpuBenchmarks(),
    })
end

--- Runs the busy-loop once and returns its `ceil(seconds * 100)` cost, or nil if
--- the lobby was torn down mid-run. Must run inside a forked thread (it yields).
---@param instance UICustomLobbyInstance
---@return number | nil
local function RunOnce(instance)
    local TableInsert = table.insert
    local totalTime = 0
    local countTime = 0
    local lastTime, currTime, j, k, l, m
    local n = {}
    for h = 1, 24 do
        if IsDestroyed(instance) then
            return nil
        end
        lastTime = GetSystemTimeSeconds()
        for i = 1.0, 30.4, 0.0008 do
            j = i + i
            k = i * i
            l = k / j
            m = j - i
            j = math.pow(i, 4)
            l = -i
            m = { '1234567890', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', true }
            TableInsert(m, '1234567890')
            k = i < j
            k = i == j
            k = i <= j
            k = not k
            n[tostring(i)] = m
        end
        currTime = GetSystemTimeSeconds()
        totalTime = totalTime + currTime - lastTime
        if totalTime > countTime then
            -- yield so the UI keeps ticking during the benchmark
            countTime = totalTime + 0.125
            coroutine.yield(1)
        end
    end
    return math.ceil(totalTime * 100)
end

--- Benchmarks the local CPU (best of three runs) and reports the score: the host
--- records + broadcasts it; a client sends it to the host.
---@param instance UICustomLobbyInstance
function RunBenchmarkThread(instance)
    -- defer briefly so connection negotiation isn't starved
    WaitSeconds(2.0)

    local best
    for run = 1, 3 do
        local score = RunOnce(instance)
        if not score or IsDestroyed(instance) then
            return
        end
        if not best or score < best then
            best = score
        end
    end

    local model = CustomLobbyAuthoritativeModel.GetSingleton()
    local connModel = CustomLobbyModel.GetSingleton()

    -- show our own score immediately; the host's snapshot reconciles everyone
    CustomLobbyModel.SetCpuBenchmark(connModel, model.LocalPeerId(), best)

    if model.IsHost() then
        BroadcastCpuBenchmarks(instance)
    else
        instance:SendData(model.HostID(), { Type = 'CPUBenchmark', Benchmark = best })
    end
end

--#endregion

-------------------------------------------------------------------------------
--#region Intents (called by the UI)

--- The local player toggles their ready flag. Host applies + broadcasts; a client
--- asks the host to.
---@param ready boolean
function RequestSetReady(ready)
    local instance = LobbyInstance
    if not instance then
        return
    end

    local model = CustomLobbyAuthoritativeModel.GetSingleton()
    if model.IsHost() then
        local slot = FindSlotForOwner(model, model.LocalPeerId())
        if slot then
            CustomLobbyAuthoritativeModel.SetPlayerField(model, slot, 'Ready', ready and true or false)
            BroadcastPlayers(instance, model)
        end
    else
        instance:SendData(model.HostID(), { Type = 'SetReady', Ready = ready and true or false })
    end
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: re-imports this module so the instance's forwarders resolve to
--- the fresh functions. (Note: the stored `LobbyInstance` resets to false on reload
--- and is re-set on the next engine callback.)
function __moduleinfo.OnDirty()
    ForkThread(
        function()
            WaitFrames(2)
            import(__moduleinfo.name)
        end
    )
end

--#endregion
