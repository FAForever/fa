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
-- passing itself as `instance`. The host is authoritative; state goes to the three
-- models via their write helpers:
--   * CustomLobbyLaunchModel   — shared, launched (players, scenario, options, mods).
--   * CustomLobbySessionModel  — shared, lobby-room only (slot count, closed slots).
--   * CustomLobbyLocalModel    — per-peer, never synced (identity, CPU benchmarks).
--
-- Barebones host-authority flow:
--   host    : OnHosting -> seats itself in slot 1
--   client  : OnConnectionToHostEstablished -> SendData(host, AddPlayer)
--   host    : ProcessAddPlayer -> seats the peer -> broadcasts players + launch + session
--   everyone: Process* -> applies the snapshot -> components react
--   ready   : RequestSetReady (intent) -> host applies + broadcasts SetPlayers
--
-- See /lua/ui/lobby/TARGET_ARCHITECTURE.md § 5.

local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")
local CustomLobbySessionModel = import("/lua/ui/lobby/customlobby/customlobbysessionmodel.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/customlobbylocalmodel.lua")

--- The live lobby object, set by the first engine callback. UI-triggered intents
--- (RequestSetReady, …) reach the network through it without threading it everywhere.
---@type UICustomLobbyInstance | false
local LobbyInstance = false

-------------------------------------------------------------------------------
--#region Helpers

--- First empty player slot within the active slot count, or nil.
---@return number | nil
local function FindFreeSlot()
    local launch = CustomLobbyLaunchModel.GetSingleton()
    local session = CustomLobbySessionModel.GetSingleton()
    for slot = 1, session.SlotCount() do
        if not launch.Players[slot]() then
            return slot
        end
    end
    return nil
end

--- The slot a peer occupies, or nil.
---@param ownerId UILobbyPeerId
---@return number | nil
local function FindSlotForOwner(ownerId)
    local launch = CustomLobbyLaunchModel.GetSingleton()
    for slot = 1, CustomLobbyLaunchModel.MaxSlots do
        local player = launch.Players[slot]()
        if player and player.OwnerID == ownerId then
            return slot
        end
    end
    return nil
end

--- The player occupying `slot` within the player array, or nil. Tolerant of the
--- arbitrary slot values a chat command might pass.
---@param slot any
---@return UICustomLobbyPlayer | nil
local function PlayerInSlot(slot)
    if type(slot) ~= 'number' or slot < 1 or slot > CustomLobbyLaunchModel.MaxSlots then
        return nil
    end
    return CustomLobbyLaunchModel.GetSingleton().Players[slot]() or nil
end

--- A plain per-slot snapshot of all players (false for empty), for the wire.
---@return table
local function GatherPlayers()
    local launch = CustomLobbyLaunchModel.GetSingleton()
    local players = {}
    for slot = 1, CustomLobbyLaunchModel.MaxSlots do
        players[slot] = launch.Players[slot]() or false
    end
    return players
end

--- Host broadcasts the player + observer snapshot (part of the launch state) to everyone.
---@param instance UICustomLobbyInstance
local function BroadcastPlayers(instance)
    local launch = CustomLobbyLaunchModel.GetSingleton()
    instance:BroadcastData({
        Type = 'SetPlayers',
        Players = GatherPlayers(),
        Observers = launch.Observers(),
    })
end

--- Whether `slot` is a real, currently-open seat (in range, empty, not closed).
---@param slot any
---@return boolean
local function IsOpenSlot(slot)
    local session = CustomLobbySessionModel.GetSingleton()
    if type(slot) ~= 'number' or slot < 1 or slot > session.SlotCount() then
        return false
    end
    return not CustomLobbyLaunchModel.GetSingleton().Players[slot]() and not session.ClosedSlots()[slot]
end

--- Host-side: moves the player owned by `ownerId` into an open `slot` (or seats it from
--- the observer list), forcing it unready and keeping StartSpot mirrored to the seat.
--- Broadcasts the new snapshot. A no-op if the move isn't valid — the host is the gate.
---@param instance UICustomLobbyInstance
---@param ownerId UILobbyPeerId
---@param slot number
local function TakeSlot(instance, ownerId, slot)
    if not IsOpenSlot(slot) then
        return
    end

    local launch = CustomLobbyLaunchModel.GetSingleton()
    local from = FindSlotForOwner(ownerId)
    local player
    if from then
        if from == slot then
            return
        end
        player = table.copy(launch.Players[from]())
        CustomLobbyLaunchModel.ClearPlayer(launch, from)
    else
        -- not in a slot: an observer joining a slot (the reverse of Move to observers)
        local observer = CustomLobbyLaunchModel.RemoveObserver(launch, ownerId)
        if not observer then
            return
        end
        player = table.copy(observer)
    end

    player.StartSpot = slot
    player.Ready = false                       -- (re)seating resets readiness
    CustomLobbyLaunchModel.SetPlayer(launch, slot, player)
    BroadcastPlayers(instance)
end

--- Host-side: swaps the contents of two slots (players and/or empties), forcing any
--- moved player unready and keeping StartSpot mirrored to the seat. Broadcasts.
---@param instance UICustomLobbyInstance
---@param slotA number
---@param slotB number
local function SwapSlots(instance, slotA, slotB)
    local count = CustomLobbySessionModel.GetSingleton().SlotCount()
    if type(slotA) ~= 'number' or type(slotB) ~= 'number' then
        return
    end
    if slotA == slotB or slotA < 1 or slotA > count or slotB < 1 or slotB > count then
        return
    end

    local launch = CustomLobbyLaunchModel.GetSingleton()
    local a = launch.Players[slotA]()
    local b = launch.Players[slotB]()
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
        CustomLobbyLaunchModel.SetPlayer(launch, slotA, b)
    else
        CustomLobbyLaunchModel.ClearPlayer(launch, slotA)
    end
    if a then
        CustomLobbyLaunchModel.SetPlayer(launch, slotB, a)
    else
        CustomLobbyLaunchModel.ClearPlayer(launch, slotB)
    end
    BroadcastPlayers(instance)
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

    local localModel = CustomLobbyLocalModel.GetSingleton()
    local id = instance:GetLocalPlayerID()
    localModel.LocalPeerId:Set(id)
    localModel.HostID:Set(id)
    localModel.IsHost:Set(true)

    local launch = CustomLobbyLaunchModel.GetSingleton()
    local player = CreateLocalPlayer(instance)
    player.OwnerID = id
    player.StartSpot = 1
    player.PlayerColor = 1
    player.ArmyColor = 1
    CustomLobbyLaunchModel.SetPlayer(launch, 1, player)

    instance.Trash:Add(ForkThread(ShareCpuBenchmarkThread, instance))
end

--- Called when our connection to the host succeeds.
---@param instance UICustomLobbyInstance
---@param localId UILobbyPeerId
---@param localName string
---@param hostId UILobbyPeerId
function OnConnectionToHostEstablished(instance, localId, localName, hostId)
    LobbyInstance = instance

    local localModel = CustomLobbyLocalModel.GetSingleton()
    localModel.LocalPeerId:Set(localId)
    localModel.HostID:Set(hostId)
    localModel.IsHost:Set(false)

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
    if not CustomLobbyLocalModel.GetSingleton().IsHost() then
        return
    end

    -- tell the remaining peers to tear down their direct connection to the leaver
    instance:BroadcastData({ Type = 'DisconnectPeer', PeerID = uid })

    local slot = FindSlotForOwner(uid)
    if slot then
        CustomLobbyLaunchModel.ClearPlayer(CustomLobbyLaunchModel.GetSingleton(), slot)
    end
    BroadcastPlayers(instance)
end

--- Called when the game launches. Barebones: not wired yet.
---@param instance UICustomLobbyInstance
function OnGameLaunched(instance)
    LOG("CustomLobby: GameLaunched (launch flow not implemented yet)")
end

--#endregion

-------------------------------------------------------------------------------
--#region Message handlers (run after Validate + Accept)

--- Host seats a connecting peer and brings it up to date (players + launch + session).
---@param instance UICustomLobbyInstance
---@param data table
function ProcessAddPlayer(instance, data)
    local slot = FindFreeSlot()
    if not slot then
        WARN("CustomLobby: no free slot for joining peer " .. tostring(data.SenderID))
        return
    end

    local launch = CustomLobbyLaunchModel.GetSingleton()

    ---@type UICustomLobbyPlayer
    local player = data.PlayerOptions
    player.OwnerID = data.SenderID
    player.StartSpot = slot
    player.PlayerColor = slot
    player.ArmyColor = slot
    CustomLobbyLaunchModel.SetPlayer(launch, slot, player)

    BroadcastPlayers(instance)
    -- a fresh peer also needs the current launch config (scenario / options / mods) and
    -- the session state (slot count / closed slots), not just the player list — without
    -- them the map preview / slot grid have nothing to render
    BroadcastLaunchInfo(instance)
    BroadcastSessionState(instance)
end

--- Everyone applies the host's player + observer snapshot (launch state).
---@param instance UICustomLobbyInstance
---@param data table
function ProcessSetPlayers(instance, data)
    local launch = CustomLobbyLaunchModel.GetSingleton()
    for slot = 1, CustomLobbyLaunchModel.MaxSlots do
        launch.Players[slot]:Set(data.Players[slot] or false)
    end
    if data.Observers then
        launch.Observers:Set(data.Observers)
    end
end

--- Everyone applies the host's launch config (scenario / options / mods / teams / spawn
--- mex) — the part of the launch state that isn't the player list.
---@param instance UICustomLobbyInstance
---@param data UICustomLobbySentLaunchInfoMessage
function ProcessSentLaunchInfo(instance, data)
    local launch = CustomLobbyLaunchModel.GetSingleton()
    launch.ScenarioFile:Set(data.ScenarioFile or false)
    launch.GameOptions:Set(data.GameOptions or {})
    launch.GameMods:Set(data.GameMods or {})
    launch.AutoTeams:Set(data.AutoTeams or {})
    launch.SpawnMex:Set(data.SpawnMex or {})
end

--- Everyone applies the host's session state (slot count / closed slots) — lobby-room
--- management, not part of the launch.
---@param instance UICustomLobbyInstance
---@param data UICustomLobbySetSessionStateMessage
function ProcessSetSessionState(instance, data)
    local session = CustomLobbySessionModel.GetSingleton()
    session.SlotCount:Set(data.SlotCount or session.SlotCount())
    session.ClosedSlots:Set(data.ClosedSlots or {})
end

--- Host flips a peer's ready flag and re-broadcasts.
---@param instance UICustomLobbyInstance
---@param data table
function ProcessSetReady(instance, data)
    local slot = FindSlotForOwner(data.SenderID)
    if slot then
        CustomLobbyLaunchModel.SetPlayerField(CustomLobbyLaunchModel.GetSingleton(), slot, 'Ready', data.Ready and true or false)
        BroadcastPlayers(instance)
    end
end

--- Host moves a requesting client into the open slot it asked for.
---@param instance UICustomLobbyInstance
---@param data UICustomLobbyTakeSlotMessage
function ProcessTakeSlot(instance, data)
    TakeSlot(instance, data.SenderID, data.Slot)
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
    CustomLobbyLocalModel.SetCpuBenchmark(CustomLobbyLocalModel.GetSingleton(), data.SenderID, data.CpuBenchmark)
    BroadcastCpuBenchmarks(instance)
end

--- Everyone applies the host's authoritative benchmark snapshot.
---@param instance UICustomLobbyInstance
---@param data UICustomLobbySetCpuBenchmarksMessage
function ProcessSetCpuBenchmarks(instance, data)
    CustomLobbyLocalModel.GetSingleton().CpuBenchmarks:Set(data.CpuBenchmarks)
end

--#endregion

-------------------------------------------------------------------------------
--#region Shared-state broadcasts
--
-- The host owns the shared models and pushes whole snapshots: rather than syncing each
-- field with its own message, it broadcasts the relevant snapshot whenever any of it
-- changes (and to each peer as it joins). Call these after a host-side change.

--- Host broadcasts the launch config snapshot (scenario / options / mods / teams / spawn).
---@param instance UICustomLobbyInstance
function BroadcastLaunchInfo(instance)
    local launch = CustomLobbyLaunchModel.GetSingleton()
    instance:BroadcastData({
        Type = 'SentLaunchInfo',
        ScenarioFile = launch.ScenarioFile(),
        GameOptions = launch.GameOptions(),
        GameMods = launch.GameMods(),
        AutoTeams = launch.AutoTeams(),
        SpawnMex = launch.SpawnMex(),
    })
end

--- Host broadcasts the session state snapshot (slot count / closed slots).
---@param instance UICustomLobbyInstance
function BroadcastSessionState(instance)
    local session = CustomLobbySessionModel.GetSingleton()
    instance:BroadcastData({
        Type = 'SetSessionState',
        SlotCount = session.SlotCount(),
        ClosedSlots = session.ClosedSlots(),
    })
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
        CpuBenchmarks = CustomLobbyLocalModel.GetSingleton().CpuBenchmarks(),
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

    local localModel = CustomLobbyLocalModel.GetSingleton()

    -- show our own data immediately; the host's snapshots reconcile everyone
    CustomLobbyLocalModel.SetCpuBenchmark(localModel, localModel.LocalPeerId(), benchmark)

    if localModel.IsHost() then
        BroadcastCpuBenchmarks(instance)
    else
        instance:SendData(localModel.HostID(), { Type = 'ReportCpuBenchmark', CpuBenchmark = benchmark })
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

    local localModel = CustomLobbyLocalModel.GetSingleton()
    if localModel.IsHost() then
        TakeSlot(instance, localModel.LocalPeerId(), slot)
    else
        instance:SendData(localModel.HostID(), { Type = 'TakeSlot', Slot = slot })
    end
end

--- The host picks the scenario (map). Host-only — backs the map-select dialog and a
--- `/map <name>` chat command. Sets the scenario in the launch model and broadcasts the
--- launch config; the map preview / unit-cap react to the new `ScenarioFile`.
---
--- TODO (options slice): when the scenario changes, the game-options *schema* changes too
--- (the map contributes its own options). Reconcile `GameOptions` here — drop values whose
--- keys no longer exist, seed defaults for new keys — before broadcasting. See CLAUDE.md.
---@param scenarioFile FileName
function RequestSetScenario(scenarioFile)
    local instance = LobbyInstance
    if not instance then
        return
    end

    if not CustomLobbyLocalModel.GetSingleton().IsHost() then
        WARN("CustomLobby: only the host can change the map")
        return
    end

    CustomLobbyLaunchModel.SetScenario(CustomLobbyLaunchModel.GetSingleton(), scenarioFile)
    BroadcastLaunchInfo(instance)
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

    if not CustomLobbyLocalModel.GetSingleton().IsHost() then
        WARN("CustomLobby: only the host can swap slots")
        return
    end
    SwapSlots(instance, slotA, slotB)
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

    if not CustomLobbyLocalModel.GetSingleton().IsHost() then
        WARN("CustomLobby: only the host can eject players")
        return
    end

    local player = PlayerInSlot(slot)
    if not player then
        return
    end
    if player.Human then
        instance:EjectPeer(player.OwnerID, "KickedByHost")
    else
        CustomLobbyLaunchModel.ClearPlayer(CustomLobbyLaunchModel.GetSingleton(), slot)
        BroadcastPlayers(instance)
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

    if not CustomLobbyLocalModel.GetSingleton().IsHost() then
        WARN("CustomLobby: only the host can move players to observers")
        return
    end

    local player = PlayerInSlot(slot)
    if not player then
        return
    end
    local launch = CustomLobbyLaunchModel.GetSingleton()
    CustomLobbyLaunchModel.AddObserver(launch, player)
    CustomLobbyLaunchModel.ClearPlayer(launch, slot)
    BroadcastPlayers(instance)
end

--- The local player toggles their ready flag. Host applies + broadcasts; a client
--- asks the host to.
---@param ready boolean
function RequestSetReady(ready)
    local instance = LobbyInstance
    if not instance then
        return
    end

    local localModel = CustomLobbyLocalModel.GetSingleton()
    if localModel.IsHost() then
        local slot = FindSlotForOwner(localModel.LocalPeerId())
        if slot then
            CustomLobbyLaunchModel.SetPlayerField(CustomLobbyLaunchModel.GetSingleton(), slot, 'Ready', ready and true or false)
            BroadcastPlayers(instance)
        end
    else
        instance:SendData(localModel.HostID(), { Type = 'SetReady', Ready = ready and true or false })
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
