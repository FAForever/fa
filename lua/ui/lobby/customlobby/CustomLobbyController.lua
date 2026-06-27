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

local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/models/customlobbylaunchmodel.lua")
local CustomLobbySessionModel = import("/lua/ui/lobby/customlobby/models/customlobbysessionmodel.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/models/customlobbylocalmodel.lua")
local CustomLobbySession = import("/lua/ui/lobby/customlobby/customlobbysession.lua")
local CustomLobbyPresets = import("/lua/ui/lobby/customlobby/customlobbypresets.lua")

--- The live lobby object, set by the first engine callback. UI-triggered intents
--- (RequestSetReady, …) reach the network through it without threading it everywhere.
---@type UICustomLobbyInstance | false
local LobbyInstance = false

-- delay between the close-assert and the open broadcast in RequestReopenClosedSlots
local ReopenClosedSlotsDelay = 0.5

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

--- Host-side: drops any auto-balance lock pinning `slot`. A lock belongs to the player seated there,
--- so it must not outlive them and pin whoever takes the seat next (see CustomLobbyBalancer). Does
--- NOT broadcast — returns whether a lock was actually cleared so the caller can fold a session-state
--- snapshot into its existing broadcast only when something changed.
---@param slot number
---@return boolean # true if a lock was cleared
local function ClearSlotLock(slot)
    local session = CustomLobbySessionModel.GetSingleton()
    if not session.LockedSlots()[slot] then
        return false
    end
    CustomLobbySessionModel.SetLocked(session, slot, false)
    return true
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
        -- the player relocated; the seat it left must not stay locked (the lock was theirs)
        if ClearSlotLock(from) then
            BroadcastSessionState(instance)
        end
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

    -- a seat that ends up empty must shed its lock (the lock belonged to the player who left it),
    -- so a later occupant isn't silently pinned
    local lockChanged = false
    if b then
        CustomLobbyLaunchModel.SetPlayer(launch, slotA, b)
    else
        CustomLobbyLaunchModel.ClearPlayer(launch, slotA)
        lockChanged = ClearSlotLock(slotA) or lockChanged
    end
    if a then
        CustomLobbyLaunchModel.SetPlayer(launch, slotB, a)
    else
        CustomLobbyLaunchModel.ClearPlayer(launch, slotB)
        lockChanged = ClearSlotLock(slotB) or lockChanged
    end
    BroadcastPlayers(instance)
    if lockChanged then
        BroadcastSessionState(instance)
    end
end

--- Reads a numeric command-line argument (e.g. `/mean 1500`), falling back to the default
--- when it is absent or unparseable.
---@param key string
---@param default number
---@return number
local function GetCommandLineNumber(key, default)
    local arg = GetCommandLineArg(key, 1)
    if arg and arg[1] then
        return tonumber(arg[1]) or default
    end
    return default
end

--- Reads a string command-line argument (e.g. `/clan Yps`), falling back to the default when
--- it is absent.
---@param key string
---@param default string
---@return string
local function GetCommandLineString(key, default)
    local arg = GetCommandLineArg(key, 1)
    if arg and arg[1] then
        return tostring(arg[1])
    end
    return default
end

--- Reads the faction from the flag args (`/uef` `/aeon` `/cybran` `/seraphim`), falling back to
--- the default when none is present. Mirrors the autolobby's CreateLocalPlayer.
---@param default number
---@return number
local function GetCommandLineFaction(default)
    for index, faction in import("/lua/factions.lua").Factions do
        if HasCommandLineArg("/" .. faction.Key) then
            return index
        end
    end
    return default
end

--- Builds the local player's options from the profile / engine name.
---@param instance UICustomLobbyInstance
---@return UICustomLobbyPlayer
function CreateLocalPlayer(instance)
    local name = instance:GetLocalPlayerName() or import("/lua/user/prefs.lua").GetFromCurrentProfile('Name') or "Player"
    local player = import("/lua/ui/lobby/lobbycomm.lua").GetDefaultPlayerOptions(name)

    -- player info from the command line: the FAF client passes the player's real values, and the
    -- dev launch script (scripts/LaunchCustomLobby.ps1) seeds random ones. Mirrors the autolobby's
    -- CreateLocalPlayer and the legacy lobby's GetLocalPlayerData. The host preserves all of these
    -- when it seats a joining peer (it only reassigns StartSpot / colors) — see ProcessAddPlayer.

    -- rating + game count
    player.MEAN = GetCommandLineNumber("/mean", 1500)
    player.DEV = GetCommandLineNumber("/deviation", 500)
    player.NG = GetCommandLineNumber("/numgames", 0)
    player.PL = math.floor(player.MEAN - 3 * player.DEV)

    -- faction + team
    player.Faction = GetCommandLineFaction(player.Faction)
    player.Team = GetCommandLineNumber("/team", player.Team)

    -- identity + league standing
    player.PlayerClan = GetCommandLineString("/clan", player.PlayerClan or "")
    player.Country = GetCommandLineString("/country", player.Country or "")
    player.DIV = GetCommandLineString("/division", player.DIV or "")
    player.SUBDIV = GetCommandLineString("/subdivision", player.SUBDIV or "")

    return player
end

--#endregion

-------------------------------------------------------------------------------
--#region Connection events

--- Called when we become the host.
---@param instance UICustomLobbyInstance
function OnHosting(instance)
    LOG("OnHosting")
    LobbyInstance = instance

    local localModel = CustomLobbyLocalModel.GetSingleton()
    local id = instance:GetLocalPlayerID()
    localModel.LocalPeerId:Set(id)
    localModel.HostID:Set(id)
    localModel.IsHost.OnDirty = function()
        LOG("CustomLobby: IsHost changed to " .. tostring(localModel.IsHost()))
    end
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
    local lockChanged = false
    if slot then
        CustomLobbyLaunchModel.ClearPlayer(CustomLobbyLaunchModel.GetSingleton(), slot)
        lockChanged = ClearSlotLock(slot)
    end
    BroadcastPlayers(instance)
    if lockChanged then
        BroadcastSessionState(instance)
    end
end

--- Called when the game launches. The engine has taken over in its own Lua state, so the lobby's
--- front-end state can be released: free everything registered in the session trash (the map
--- catalog today; the models, interface and instance follow as they are converted to the pattern).
---@param instance UICustomLobbyInstance
function OnGameLaunched(instance)
    LOG("CustomLobby: GameLaunched — tearing down the lobby session")
    CustomLobbySession.Teardown()
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
    launch.Restrictions:Set(data.Restrictions or {})
end

--- Everyone applies the host's session state (slot count / closed slots) — lobby-room
--- management, not part of the launch.
---@param instance UICustomLobbyInstance
---@param data UICustomLobbySetSessionStateMessage
function ProcessSetSessionState(instance, data)
    local session = CustomLobbySessionModel.GetSingleton()
    session.SlotCount:Set(data.SlotCount or session.SlotCount())
    session.ClosedSlots:Set(data.ClosedSlots or {})
    session.LockedSlots:Set(data.LockedSlots or {})
    session.SlotsPinned:Set(data.SlotsPinned and true or false)
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

--- Host moves a requesting client into the open slot it asked for. Ignored while seating
--- is pinned — only the host may change slots then (the host's own take goes through
--- RequestTakeSlot, which is exempt).
---@param instance UICustomLobbyInstance
---@param data UICustomLobbyTakeSlotMessage
function ProcessTakeSlot(instance, data)
    if CustomLobbySessionModel.GetSingleton().SlotsPinned() then
        return
    end
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

--- Everyone launches the game with the host's configuration (the engine takes over from here).
---@param instance UICustomLobbyInstance
---@param data UICustomLobbyLaunchGameMessage
function ProcessLaunchGame(instance, data)
    instance:LaunchGame(data.GameConfig)
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
        Restrictions = launch.Restrictions(),
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
        LockedSlots = session.LockedSlots(),
        SlotsPinned = session.SlotsPinned(),
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
        -- pinned seating is host-only: don't bother the host with a request it will reject
        if CustomLobbySessionModel.GetSingleton().SlotsPinned() then
            return
        end
        instance:SendData(localModel.HostID(), { Type = 'TakeSlot', Slot = slot })
    end
end

--- The number of start spots (max players) a scenario declares, or 0 when it can't be read.
---@param scenarioFile FileName | false
---@return number
local function ScenarioSlotCount(scenarioFile)
    if not scenarioFile then
        return 0
    end
    local info = import("/lua/ui/maputil.lua").LoadScenario(scenarioFile)
    local armies = info
        and info.Configurations
        and info.Configurations.standard
        and info.Configurations.standard.teams
        and info.Configurations.standard.teams[1]
        and info.Configurations.standard.teams[1].armies
    return armies and table.getsize(armies) or 0
end

--- The host picks the scenario (map). Host-only — backs the map-select dialog and a
--- `/map <name>` chat command. Sets the scenario in the launch model, sizes the lobby room to the
--- map's start spots, and broadcasts both; the map preview / unit-cap react to the new `ScenarioFile`.
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

    -- size the lobby room to the map's start spots, so all of its slots show (capped at MaxSlots)
    local count = ScenarioSlotCount(scenarioFile)
    if count > 0 then
        local session = CustomLobbySessionModel.GetSingleton()
        session.SlotCount:Set(math.min(count, CustomLobbyLaunchModel.MaxSlots))
        BroadcastSessionState(instance)
    end

    BroadcastLaunchInfo(instance)
end

--- The host sets the active sim mods. Host-only — backs the mod-select dialog. Sets `GameMods`
--- in the launch model and broadcasts the launch config so every peer sees the same sim mods.
--- UI mods are per-peer and handled locally by the dialog, never here.
---@param gameMods table<string, true>
function RequestSetGameMods(gameMods)
    local instance = LobbyInstance
    if not instance then
        return
    end

    if not CustomLobbyLocalModel.GetSingleton().IsHost() then
        WARN("CustomLobby: only the host can change the game mods")
        return
    end

    CustomLobbyLaunchModel.SetGameMods(CustomLobbyLaunchModel.GetSingleton(), gameMods)
    BroadcastLaunchInfo(instance)
end

--- The host sets the unit restrictions. Host-only — backs the unit-select dialog and a
--- `/restrict <key>` chat command. Stores the preset-key list in the launch model and broadcasts,
--- so every peer sees the same restrictions. The keys are folded into the launch config's
--- `GameOptions.RestrictedCategories` at launch (`BuildGameConfiguration`); the sim expands them.
---@param keys string[]
function RequestSetRestrictions(keys)
    local instance = LobbyInstance
    if not instance then
        WARN("CustomLobby: RequestSetRestrictions ignored — no lobby instance (UI-only, or the "
            .. "controller was hot-reloaded; re-host to restore it)")
        return
    end

    if not CustomLobbyLocalModel.GetSingleton().IsHost() then
        WARN("CustomLobby: only the host can change the unit restrictions")
        return
    end

    CustomLobbyLaunchModel.SetRestrictions(CustomLobbyLaunchModel.GetSingleton(), keys)
    LOG("CustomLobby: restrictions set (" .. table.getn(keys) .. ")")
    BroadcastLaunchInfo(instance)
end

--- The host sets the game options. Host-only — backs the options dialog. Replaces the whole
--- `GameOptions` value table in the launch model and broadcasts so every peer sees the same
--- options. The dialog already seeds defaults + drops stale keys, so this is the reconciled set.
---@param options table
function RequestSetGameOptions(options)
    local instance = LobbyInstance
    if not instance then
        return
    end

    if not CustomLobbyLocalModel.GetSingleton().IsHost() then
        WARN("CustomLobby: only the host can change the game options")
        return
    end

    CustomLobbyLaunchModel.SetGameOptions(CustomLobbyLaunchModel.GetSingleton(), options)
    BroadcastLaunchInfo(instance)
end

--- The host resets every game option to its default. Host-only — backs the lobby's "Reset
--- options" button. Derives the current option schema (lobby + scenario + mods) and seeds the
--- defaults, then broadcasts, so it reconciles to exactly the options the current map/mods define.
function RequestResetGameOptions()
    local instance = LobbyInstance
    if not instance then
        return
    end

    if not CustomLobbyLocalModel.GetSingleton().IsHost() then
        WARN("CustomLobby: only the host can reset the game options")
        return
    end

    local OptionUtil = import("/lua/ui/optionutil.lua")
    local CustomLobbyMapCatalog = import("/lua/ui/lobby/customlobby/mapselect/customlobbymapcatalog.lua")
    local launch = CustomLobbyLaunchModel.GetSingleton()

    local options = {}
    for _, option in OptionUtil.GetLobbyOptions() do
        table.insert(options, option)
    end
    for _, option in CustomLobbyMapCatalog.LoadOptions(launch.ScenarioFile()) do
        table.insert(options, option)
    end
    for _, option in OptionUtil.GetModOptions(launch.GameMods()) do
        table.insert(options, option)
    end

    CustomLobbyLaunchModel.SetGameOptions(launch, OptionUtil.SeedDefaults(options, {}))
    BroadcastLaunchInfo(instance)
end

-------------------------------------------------------------------------------
--#region Launch

--- Why the game can't launch right now, or nil when it can. Requires at least one seated player,
--- a selected map, and every *other* human to be ready — the launching host is exempt, since
--- clicking Launch is their commit.
---@return string | nil
local function LaunchBlockReason()
    local launch = CustomLobbyLaunchModel.GetSingleton()
    local localId = CustomLobbyLocalModel.GetSingleton().LocalPeerId()
    local seated = 0
    for slot = 1, CustomLobbyLaunchModel.MaxSlots do
        local player = launch.Players[slot]()
        if player then
            seated = seated + 1
            if player.Human and player.OwnerID ~= localId and not player.Ready then
                return "not everyone is ready"
            end
        end
    end
    if seated == 0 then
        return "no players are seated"
    end
    if not launch.ScenarioFile() then
        return "no map is selected"
    end
    return nil
end

--- Builds the engine launch configuration from the launch model — mirrors the autolobby's
--- `LaunchThread` and the legacy lobby's `LaunchGame`:
---   * `GameOptions`: the host's values with lobby/scenario/mod defaults seeded over them, plus the
---     scenario file and the ratings / clan-tag tables (sim + UI read those there);
---   * `PlayerOptions`: the seated players (fresh copies; a random faction resolved to a concrete
---     one), keyed by slot, with army numbers assigned in slot order and pushed to the server;
---   * `GameMods` + `Observers` straight off the model.
---@param instance UICustomLobbyInstance
---@return UILobbyLaunchConfiguration
local function BuildGameConfiguration(instance)
    local OptionUtil = import("/lua/ui/optionutil.lua")
    local CustomLobbyMapCatalog = import("/lua/ui/lobby/customlobby/mapselect/customlobbymapcatalog.lua")
    local Factions = import("/lua/factions.lua").Factions
    local factionCount = table.getn(Factions)
    local launch = CustomLobbyLaunchModel.GetSingleton()

    -- the full option set: the host's chosen values, with defaults seeded for anything unset
    local schema = {}
    for _, option in OptionUtil.GetLobbyOptions() do table.insert(schema, option) end
    for _, option in CustomLobbyMapCatalog.LoadOptions(launch.ScenarioFile()) do table.insert(schema, option) end
    for _, option in OptionUtil.GetModOptions(launch.GameMods()) do table.insert(schema, option) end
    local gameOptions = OptionUtil.SeedDefaults(schema, launch.GameOptions())
    gameOptions.ScenarioFile = launch.ScenarioFile()
    -- the unit restrictions live in their own launch-model field (so the options dialog can't wipe
    -- them); fold them in here as the preset-key array the sim expands (see simInit.lua)
    gameOptions.RestrictedCategories = launch.Restrictions() or {}

    -- seated players (fresh copies; random faction resolved to a concrete one)
    local playerOptions = {}
    local ratings, clanTags = {}, {}
    for slot = 1, CustomLobbyLaunchModel.MaxSlots do
        local player = launch.Players[slot]()
        if player then
            local options = table.copy(player)
            if (options.Faction or factionCount + 1) > factionCount then
                options.Faction = Random(1, factionCount)
            end
            options.StartSpot = options.StartSpot or slot
            playerOptions[slot] = options
            if options.PL then ratings[options.PlayerName] = options.PL end
            if options.PlayerClan then clanTags[options.PlayerName] = options.PlayerClan end
        end
    end
    gameOptions.Ratings = ratings
    gameOptions.ClanTags = clanTags

    -- army numbers are assigned in slot order; tell the server each seated player's army settings
    local slots = {}
    for slot, _ in playerOptions do
        table.insert(slots, slot)
    end
    table.sort(slots)
    for armyIndex, slot in ipairs(slots) do
        local player = playerOptions[slot]
        instance:SendPlayerOptionToServer(player.OwnerID, 'Team', player.Team)
        instance:SendPlayerOptionToServer(player.OwnerID, 'Army', armyIndex)
        instance:SendPlayerOptionToServer(player.OwnerID, 'StartSpot', player.StartSpot)
        instance:SendPlayerOptionToServer(player.OwnerID, 'Faction', player.Faction)
    end

    return {
        -- the model holds the selected sim-mod uid set; the engine wants the resolved mod list
        GameMods = import("/lua/mods.lua").GetGameMods(launch.GameMods()),
        GameOptions = gameOptions,
        PlayerOptions = playerOptions,
        Observers = launch.Observers(),
    }
end

--- The host launches the game. Host-only — backs the Launch button. Validates readiness, builds
--- the launch configuration, broadcasts it so every peer launches with the same config, then
--- launches locally. The engine takes over from here (see `OnGameLaunched`).
---
--- TODO: resolve AutoTeams (the mode lives in `GameOptions` but teams aren't applied at launch yet
--- — see USER_STORIES.md H), and gate the button reactively / surface the block reason in the UI
--- rather than only warning.
function RequestLaunch()
    local instance = LobbyInstance
    if not instance then
        return
    end

    if not CustomLobbyLocalModel.GetSingleton().IsHost() then
        WARN("CustomLobby: only the host can launch the game")
        return
    end

    local reason = LaunchBlockReason()
    if reason then
        WARN("CustomLobby: cannot launch — " .. reason)
        return
    end

    -- auto-save the launched setup as the reserved "last game" preset, so a rehost can restore it
    -- (USER_STORIES.md § O); failure to persist must not block the launch
    local ok, err = pcall(function()
        CustomLobbyPresets.SavePreset(CustomLobbyPresets.LastGamePresetName, BuildSetupSnapshot())
    end)
    if not ok then
        WARN("CustomLobby: failed to auto-save the last-game preset — " .. tostring(err))
    end

    local gameConfiguration = BuildGameConfiguration(instance)
    instance:BroadcastData({ Type = 'LaunchGame', GameConfig = gameConfiguration })
    instance:LaunchGame(gameConfiguration)
end

--#endregion

-------------------------------------------------------------------------------
--#region Setup presets (save / load named setup snapshots; § O)
--
-- Persistence is in CustomLobbyPresets (pure prefs). Capturing the live launch state into a
-- snapshot and applying one back touch the synced model + network, so they live here (the host
-- is the only writer). A preset is **setup-only** — scenario / game options / sim mods /
-- restrictions. Players, observers and the (not-yet-applied) auto-teams / spawn-mex are
-- intentionally left out: a preset reconfigures a lobby, it doesn't restore a roster. The future
-- rehost reseat (§ O.4) will need its own player capture, not these presets.

--- Reads the current launch state into a plain serializable setup snapshot. Used both by the
--- save-preset intent and the launch auto-save. Pure read — never mutates the model.
---@return UICustomLobbySetupSnapshot
function BuildSetupSnapshot()
    local launch = CustomLobbyLaunchModel.GetSingleton()

    -- per-player Ratings / ClanTags are stamped fresh at launch; drop them from the saved options
    local options = table.deepcopy(launch.GameOptions())
    options.Ratings = nil
    options.ClanTags = nil

    return {
        ScenarioFile = launch.ScenarioFile(),
        GameOptions = options,
        GameMods = table.deepcopy(launch.GameMods()),
        Restrictions = table.deepcopy(launch.Restrictions()),
    }
end

--- Host-side: applies a setup snapshot to the launch model and broadcasts it. Sets the scenario
--- (re-sizing the lobby room), sim mods and restrictions, then reconciles the game options against
--- the now-current scenario+mods (drop stale keys, seed defaults) — the same reconcile the options
--- dialog / reset use — and broadcasts once. Players, observers and auto-teams / spawn-mex are left
--- untouched (a preset is setup-only — see the region note). Mirrors the legacy `ApplyGameSettings`
--- → single `UpdateGame`.
---@param setup UICustomLobbySetupSnapshot
function ApplySetup(setup)
    local instance = LobbyInstance
    if not instance then
        WARN("CustomLobby: ApplySetup ignored — no lobby instance (UI-only, or the controller was "
            .. "hot-reloaded; re-host to restore it)")
        return
    end

    if not CustomLobbyLocalModel.GetSingleton().IsHost() then
        WARN("CustomLobby: only the host can load a setup preset")
        return
    end

    if not setup then
        WARN("CustomLobby: ApplySetup ignored — empty setup")
        return
    end

    local launch = CustomLobbyLaunchModel.GetSingleton()

    -- scenario first: it sizes the lobby room and drives the option schema below
    local scenario = setup.ScenarioFile or false
    CustomLobbyLaunchModel.SetScenario(launch, scenario)
    local count = ScenarioSlotCount(scenario)
    if count > 0 then
        local session = CustomLobbySessionModel.GetSingleton()
        session.SlotCount:Set(math.min(count, CustomLobbyLaunchModel.MaxSlots))
        BroadcastSessionState(instance)
    end

    CustomLobbyLaunchModel.SetGameMods(launch, setup.GameMods or {})
    CustomLobbyLaunchModel.SetRestrictions(launch, setup.Restrictions or {})

    -- reconcile the saved option values against the current scenario+mods schema
    local OptionUtil = import("/lua/ui/optionutil.lua")
    local CustomLobbyMapCatalog = import("/lua/ui/lobby/customlobby/mapselect/customlobbymapcatalog.lua")
    local schema = {}
    for _, option in OptionUtil.GetLobbyOptions() do table.insert(schema, option) end
    for _, option in CustomLobbyMapCatalog.LoadOptions(scenario) do table.insert(schema, option) end
    for _, option in OptionUtil.GetModOptions(launch.GameMods()) do table.insert(schema, option) end
    CustomLobbyLaunchModel.SetGameOptions(launch, OptionUtil.SeedDefaults(schema, setup.GameOptions or {}))

    BroadcastLaunchInfo(instance)
end

--- Saves the current setup under `name` (host-local prefs). Reads the live model, so a client may
--- also capture the host-dictated setup to reuse later; the save itself never mutates the lobby.
---@param name string
function RequestSaveSetupPreset(name)
    if not name or name == "" then
        WARN("CustomLobby: RequestSaveSetupPreset ignored — empty name")
        return
    end
    CustomLobbyPresets.SavePreset(name, BuildSetupSnapshot())
    LOG("CustomLobby: setup preset saved (" .. name .. ")")
end

--- Loads the named setup preset and applies it. Host-only (enforced in `ApplySetup`).
---@param name string
function RequestLoadSetupPreset(name)
    local setup = CustomLobbyPresets.GetPreset(name)
    if not setup then
        WARN("CustomLobby: no setup preset named " .. tostring(name))
        return
    end
    ApplySetup(setup)
    LOG("CustomLobby: setup preset loaded (" .. tostring(name) .. ")")
end

--#endregion

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

--- The host pins or unpins seating. Host-only — backs the slots header's pin button. While
--- pinned, the host rejects client slot-takes (ProcessTakeSlot), so only the host can change
--- who sits where; the host itself is unaffected. Synced via the session-state snapshot.
---@param pinned boolean
function RequestSetSlotsPinned(pinned)
    local instance = LobbyInstance
    if not instance then
        return
    end

    if not CustomLobbyLocalModel.GetSingleton().IsHost() then
        WARN("CustomLobby: only the host can pin the slots")
        return
    end

    CustomLobbySessionModel.SetSlotsPinned(CustomLobbySessionModel.GetSingleton(), pinned)
    BroadcastSessionState(instance)
end

--- The host locks or unlocks a single seat. Host-only — backs the slot context menu's "Lock in
--- slot" toggle. A locked seat's player is held in place by auto-balance (only the unlocked players
--- are rearranged); see CustomLobbyBalancer. Synced via the session-state snapshot.
---@param slot number
---@param locked boolean
function RequestSetSlotLocked(slot, locked)
    local instance = LobbyInstance
    if not instance then
        return
    end

    if not CustomLobbyLocalModel.GetSingleton().IsHost() then
        WARN("CustomLobby: only the host can lock slots")
        return
    end

    CustomLobbySessionModel.SetLocked(CustomLobbySessionModel.GetSingleton(), slot, locked and true or false)
    BroadcastSessionState(instance)
end

--- The host applies a balanced re-seating, after confirming it in the preview. Host-only — backs
--- the auto-balance preview's Apply button. `arrangement` (slot -> ownerId) comes from
--- CustomLobbyBalancer; it only says *where* each player sits, never *what* they are (no rating /
--- faction / team — under AutoTeams the position decides the team), so it can't smuggle edits. The
--- whole board is rewritten from one snapshot — read by owner, moved to the target seat — then
--- broadcast once (re-seating via the model directly, not N pairwise swaps).
---@param arrangement table<number, UILobbyPeerId>
function RequestApplyBalance(arrangement)
    local instance = LobbyInstance
    if not instance then
        return
    end

    if not CustomLobbyLocalModel.GetSingleton().IsHost() then
        WARN("CustomLobby: only the host can auto-balance")
        return
    end
    if type(arrangement) ~= 'table' then
        return
    end

    local launch = CustomLobbyLaunchModel.GetSingleton()

    -- snapshot the seated players by owner: lets us move players between seats safely, and validate
    -- the arrangement against who is actually seated *now* (a player may have left since the preview)
    local byOwner = {}
    local seatedCount = 0
    for slot = 1, CustomLobbyLaunchModel.MaxSlots do
        local player = launch.Players[slot]()
        if player then
            byOwner[player.OwnerID] = player
            seatedCount = seatedCount + 1
        end
    end

    -- build the target board; bail if the arrangement references someone no longer seated or doesn't
    -- account for exactly the seated players (a stale preview)
    local newPlayers = {}
    local placedCount = 0
    for slot, ownerId in arrangement do
        local source = byOwner[ownerId]
        if not source then
            WARN("CustomLobby: balance arrangement references an unseated player; ignoring")
            return
        end
        local player = table.copy(source)
        player.StartSpot = slot
        player.Ready = false                   -- (re)seating resets readiness, as a manual move does
        newPlayers[slot] = player
        placedCount = placedCount + 1
    end
    if placedCount ~= seatedCount then
        WARN("CustomLobby: balance arrangement doesn't match the seated players; ignoring")
        return
    end

    -- write the new occupants and clear any seat that emptied, then broadcast once
    for slot = 1, CustomLobbyLaunchModel.MaxSlots do
        if newPlayers[slot] then
            CustomLobbyLaunchModel.SetPlayer(launch, slot, newPlayers[slot])
        elseif launch.Players[slot]() then
            CustomLobbyLaunchModel.ClearPlayer(launch, slot)
        end
    end
    BroadcastPlayers(instance)
end

--- Re-broadcasts the closed slots, then after a short delay opens every one of them. The
--- close→open pulse pushes two fresh session snapshots so a client that drifted out of sync
--- re-renders its closed slots correctly. Host-only — backs the slots header's reopen button.
function RequestReopenClosedSlots()
    local instance = LobbyInstance
    if not instance then
        return
    end

    if not CustomLobbyLocalModel.GetSingleton().IsHost() then
        WARN("CustomLobby: only the host can reopen the closed slots")
        return
    end

    local session = CustomLobbySessionModel.GetSingleton()
    local closed = {}
    for slot, isClosed in session.ClosedSlots() do
        if isClosed then
            table.insert(closed, slot)
        end
    end
    if table.empty(closed) then
        return
    end

    instance.Trash:Add(ForkThread(function()
        -- re-assert the closed state to everyone
        BroadcastSessionState(instance)
        WaitSeconds(ReopenClosedSlotsDelay)
        if IsDestroyed(instance) then
            return
        end
        -- then open the slots that were closed
        local opened = table.copy(session.ClosedSlots())
        for _, slot in closed do
            opened[slot] = nil
        end
        session.ClosedSlots:Set(opened)
        BroadcastSessionState(instance)
    end))
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
        -- the resulting PeerDisconnected clears the slot (and its lock) and re-broadcasts
        instance:EjectPeer(player.OwnerID, "KickedByHost")
    else
        CustomLobbyLaunchModel.ClearPlayer(CustomLobbyLaunchModel.GetSingleton(), slot)
        BroadcastPlayers(instance)
        if ClearSlotLock(slot) then
            BroadcastSessionState(instance)
        end
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
    -- the seat is now empty; drop any lock so the next occupant isn't pinned
    if ClearSlotLock(slot) then
        BroadcastSessionState(instance)
    end
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
