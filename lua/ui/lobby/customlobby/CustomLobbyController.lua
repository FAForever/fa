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

--- Host broadcasts the authoritative player + observer snapshot to everyone.
---@param instance UICustomLobbyInstance
---@param model UICustomLobbyAuthoritativeModel
local function BroadcastPlayers(instance, model)
    instance:BroadcastData({
        Type = 'SetPlayers',
        Players = GatherPlayers(model),
        Observers = model.Observers(),
    })
end

--- Whether `slot` is a real, currently-open seat (in range, empty, not closed).
---@param model UICustomLobbyAuthoritativeModel
---@param slot any
---@return boolean
local function IsOpenSlot(model, slot)
    if type(slot) ~= 'number' or slot < 1 or slot > model.SlotCount() then
        return false
    end
    return not model.Players[slot]() and not model.ClosedSlots()[slot]
end

--- Host-side: moves the player owned by `ownerId` into an open `slot`, forcing it
--- unready and keeping StartSpot mirrored to the seat. Broadcasts the new snapshot.
--- A no-op (and harmless) if the move isn't valid — the host is the gate.
---@param instance UICustomLobbyInstance
---@param model UICustomLobbyAuthoritativeModel
---@param ownerId UILobbyPeerId
---@param slot number
local function TakeSlot(instance, model, ownerId, slot)
    if not IsOpenSlot(model, slot) then
        return
    end

    local from = FindSlotForOwner(model, ownerId)
    local player
    if from then
        if from == slot then
            return
        end
        player = table.copy(model.Players[from]())
        CustomLobbyAuthoritativeModel.ClearPlayer(model, from)
    else
        -- not in a slot: an observer joining a slot (the reverse of Move to observers)
        local observer = CustomLobbyAuthoritativeModel.RemoveObserver(model, ownerId)
        if not observer then
            return
        end
        player = table.copy(observer)
    end

    player.StartSpot = slot
    player.Ready = false                       -- (re)seating resets readiness
    CustomLobbyAuthoritativeModel.SetPlayer(model, slot, player)
    BroadcastPlayers(instance, model)
end

--- Host-side: swaps the contents of two slots (players and/or empties), forcing any
--- moved player unready and keeping StartSpot mirrored to the seat. Broadcasts.
---@param instance UICustomLobbyInstance
---@param model UICustomLobbyAuthoritativeModel
---@param slotA number
---@param slotB number
local function SwapSlots(instance, model, slotA, slotB)
    local count = model.SlotCount()
    if type(slotA) ~= 'number' or type(slotB) ~= 'number' then
        return
    end
    if slotA == slotB or slotA < 1 or slotA > count or slotB < 1 or slotB > count then
        return
    end

    local a = model.Players[slotA]()
    local b = model.Players[slotB]()
    if a then
        a = table.copy(a)
        a.StartSpot = slotB
        a.Ready = false
    end
    if b then
        b = table.copy(b)
        b.StartSpot = slotA
        b.Ready = false
    end

    if b then
        CustomLobbyAuthoritativeModel.SetPlayer(model, slotA, b)
    else
        CustomLobbyAuthoritativeModel.ClearPlayer(model, slotA)
    end
    if a then
        CustomLobbyAuthoritativeModel.SetPlayer(model, slotB, a)
    else
        CustomLobbyAuthoritativeModel.ClearPlayer(model, slotB)
    end
    BroadcastPlayers(instance, model)
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

--- Called when a peer disconnects. Only the host acts: it clears the peer's slot,
--- tells everyone still connected to drop their own link to that peer, and sends the
--- new authoritative player snapshot. (A non-host ignores it — the host's broadcasts
--- drive its state and mesh cleanup.)
---@param instance UICustomLobbyInstance
---@param peerName string
---@param uid UILobbyPeerId
function OnPeerDisconnected(instance, peerName, uid)
    local model = CustomLobbyAuthoritativeModel.GetSingleton()
    if not model.IsHost() then
        return
    end

    -- tell the remaining peers to tear down their direct connection to the leaver
    instance:BroadcastData({ Type = 'DisconnectPeer', PeerID = uid })

    local slot = FindSlotForOwner(model, uid)
    if slot then
        CustomLobbyAuthoritativeModel.ClearPlayer(model, slot)
    end
    BroadcastPlayers(instance, model)
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

--- Everyone applies the host's authoritative player + observer snapshot.
---@param instance UICustomLobbyInstance
---@param data table
function ProcessSetPlayers(instance, data)
    local model = CustomLobbyAuthoritativeModel.GetSingleton()
    for slot = 1, CustomLobbyAuthoritativeModel.MaxSlots do
        model.Players[slot]:Set(data.Players[slot] or false)
    end
    if data.Observers then
        model.Observers:Set(data.Observers)
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

--- Host moves a requesting client into the open slot it asked for.
---@param instance UICustomLobbyInstance
---@param data UICustomLobbyTakeSlotMessage
function ProcessTakeSlot(instance, data)
    local model = CustomLobbyAuthoritativeModel.GetSingleton()
    TakeSlot(instance, model, data.SenderID, data.Slot)
end

--- A client drops its direct connection to a peer the host says has left. The slot
--- itself is cleared by the SetPlayers snapshot the host sends alongside this.
---@param instance UICustomLobbyInstance
---@param data UICustomLobbyDisconnectPeerMessage
function ProcessDisconnectPeer(instance, data)
    instance:DisconnectFromPeer(data.PeerID)
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
--#region Intents (called by the UI or a chat command, e.g. `/take 2`, `/swap 2 3`)

--- The local player takes an open slot. Host applies + broadcasts; a client asks the
--- host. Backs both a click on an open slot and a `/take <slot>` chat command.
---@param slot number
function RequestTakeSlot(slot)
    local instance = LobbyInstance
    if not instance then
        return
    end

    local model = CustomLobbyAuthoritativeModel.GetSingleton()
    if model.IsHost() then
        TakeSlot(instance, model, model.LocalPeerId(), slot)
    else
        instance:SendData(model.HostID(), { Type = 'TakeSlot', Slot = slot })
    end
end

--- The host swaps the contents of two slots. Host-only (a client request isn't
--- offered) — backs a host-side drag/menu and a `/swap <a> <b>` chat command.
---@param slotA number
---@param slotB number
function RequestSwapSlots(slotA, slotB)
    local instance = LobbyInstance
    if not instance then
        return
    end

    local model = CustomLobbyAuthoritativeModel.GetSingleton()
    if not model.IsHost() then
        WARN("CustomLobby: only the host can swap slots")
        return
    end
    SwapSlots(instance, model, slotA, slotB)
end

--- The player occupying `slot` within the active slot range, or nil. Tolerant of the
--- arbitrary slot values a chat command might pass.
---@param model UICustomLobbyAuthoritativeModel
---@param slot any
---@return UICustomLobbyPlayer | nil
local function PlayerInSlot(model, slot)
    if type(slot) ~= 'number' or slot < 1 or slot > CustomLobbyAuthoritativeModel.MaxSlots then
        return nil
    end
    return model.Players[slot]() or nil
end

--- Ejects the player in `slot`: a human is dropped from the network (the resulting
--- PeerDisconnected clears the slot + re-broadcasts), an AI is just cleared. Host-only.
--- Slot-keyed so a chat command (`/eject <slot>`) can call it too; whether the caller
--- is permitted to is gated separately.
---@param slot number
function RequestEject(slot)
    local instance = LobbyInstance
    if not instance then
        return
    end

    local model = CustomLobbyAuthoritativeModel.GetSingleton()
    if not model.IsHost() then
        WARN("CustomLobby: only the host can eject players")
        return
    end

    local player = PlayerInSlot(model, slot)
    if not player then
        return
    end
    if player.Human then
        instance:EjectPeer(player.OwnerID, "KickedByHost")
    else
        CustomLobbyAuthoritativeModel.ClearPlayer(model, slot)
        BroadcastPlayers(instance, model)
    end
end

--- Moves the player in `slot` into the observer list, then re-broadcasts. Host-only.
--- Slot-keyed for chat (`/observe <slot>`). The reverse (observer → slot) is
--- `RequestTakeSlot` ("Play this slot").
---@param slot number
function RequestMoveToObserver(slot)
    local instance = LobbyInstance
    if not instance then
        return
    end

    local model = CustomLobbyAuthoritativeModel.GetSingleton()
    if not model.IsHost() then
        WARN("CustomLobby: only the host can move players to observers")
        return
    end

    local player = PlayerInSlot(model, slot)
    if not player then
        return
    end
    CustomLobbyAuthoritativeModel.AddObserver(model, player)
    CustomLobbyAuthoritativeModel.ClearPlayer(model, slot)
    BroadcastPlayers(instance, model)
end

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
