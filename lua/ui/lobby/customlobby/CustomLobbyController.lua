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

    instance.Trash:Add(ForkThread(ShareCpuBenchmarkThread, instance))
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

    instance.Trash:Add(ForkThread(ShareCpuBenchmarkThread, instance))
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

--- Host records a peer's benchmark (sim-performance history) and re-broadcasts.
---@param instance UICustomLobbyInstance
---@param data UICustomLobbyReportCpuBenchmarkMessage
function ProcessReportCpuBenchmark(instance, data)
    CustomLobbyModel.SetCpuBenchmark(CustomLobbyModel.GetSingleton(), data.SenderID, data.CpuBenchmark)
    BroadcastCpuBenchmarks(instance)
end

--- Everyone applies the host's authoritative benchmark snapshot.
---@param instance UICustomLobbyInstance
---@param data UICustomLobbySetCpuBenchmarksMessage
function ProcessSetCpuBenchmarks(instance, data)
    CustomLobbyModel.GetSingleton().CpuBenchmarks:Set(data.CpuBenchmarks)
end

--#endregion

-------------------------------------------------------------------------------
--#region CPU benchmark
--
-- We share each peer's stored in-game sim-performance history (the engine's
-- `PerformanceTrackingV2` preference, accumulated over past games) rather than
-- running a live stress test. The host owns the table and broadcasts it; a client
-- sends its own to the host, which reconciles everyone.

--- Host broadcasts the authoritative benchmark snapshot to everyone.
---@param instance UICustomLobbyInstance
function BroadcastCpuBenchmarks(instance)
    instance:BroadcastData({
        Type = 'SetCpuBenchmarks',
        CpuBenchmarks = CustomLobbyModel.GetSingleton().CpuBenchmarks(),
    })
end

--- Shares the local machine's stored sim-performance benchmark: the host records +
--- broadcasts it; a client sends it to the host. Forked so the brief defer doesn't
--- block the connection callback.
---@param instance UICustomLobbyInstance
function ShareCpuBenchmarkThread(instance)
    -- defer briefly so connection negotiation / seating settles first
    WaitSeconds(2.0)
    if IsDestroyed(instance) then
        return
    end

    -- the machine's in-game sim-performance history (nil on a fresh install)
    local benchmark = GetPreference('PerformanceTrackingV2')
    if not benchmark then
        return
    end

    local model = CustomLobbyAuthoritativeModel.GetSingleton()
    local connModel = CustomLobbyModel.GetSingleton()

    -- show our own data immediately; the host's snapshots reconcile everyone
    CustomLobbyModel.SetCpuBenchmark(connModel, model.LocalPeerId(), benchmark)

    if model.IsHost() then
        BroadcastCpuBenchmarks(instance)
    else
        instance:SendData(model.HostID(), { Type = 'ReportCpuBenchmark', CpuBenchmark = benchmark })
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
