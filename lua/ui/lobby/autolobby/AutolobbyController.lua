--******************************************************************************************************
--** Copyright (c) 2024 Willem 'Jip' Wijnia
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

-- Lobby logic for the automated lobby, as a module of free functions.
--
-- The engine instantiates a `moho.lobby_methods` object — `AutolobbyInstance`
-- (see AutolobbyInstance.lua) — and calls its callbacks. That instance is a thin
-- shell: it forwards the callbacks with real behaviour to the functions here and
-- passes itself as the first argument. This split keeps the engine-ABI surface
-- tiny and makes the logic a plain module that **hot-reloads** (the instance's
-- forwarders resolve through the live module table) and is testable with a mock
-- instance. The running threads are the exception — a forked thread holds the
-- function it started with, so thread edits only take effect on the next lobby.
--
-- All writes go to `AutolobbyModel` (the reactive singleton the UI observes),
-- through its write helpers so the copy-then-`Set` discipline stays in one place.

local MapUtil = import("/lua/ui/maputil.lua")
local AutolobbyModel = import("/lua/ui/lobby/autolobby/autolobbymodel.lua")

-------------------------------------------------------------------------------
--#region Launch-flow computations
--
-- Pure helpers used by the launch / status threads. They moved here from the
-- model because they are controller logic, not part of the reactive model's
-- derivations (which keep `PeerIdToIndex` / `Create*Matrix` in the model).

--- Determines the launch status of the local peer.
---@param connectionMatrix table<UILobbyPeerId, UILobbyPeerId[]>
---@param playerCount number
---@return UIPeerLaunchStatus
function CreateLaunchStatus(connectionMatrix, playerCount)
    -- check number of peers
    local validPeerCount = playerCount - 1
    if table.getsize(connectionMatrix) < validPeerCount then
        return 'Missing local peers'
    end

    return 'Ready'
end

--- Verifies whether we can launch the game.
---@param peerStatus UIAutolobbyStatus
---@param playerCount number
---@return boolean
function CanLaunch(peerStatus, playerCount)
    -- check if we know of all peers
    if table.getsize(peerStatus) ~= playerCount then
        return false
    end

    -- check if all peers are ready for launch
    for k, launchStatus in peerStatus do
        if launchStatus ~= 'Ready' then
            return false
        end
    end

    return true
end

---@param playerOptions UIAutolobbyPlayer[]
---@return table<string, number>
function CreateRatingsTable(playerOptions)
    ---@type table<string, number>
    local allRatings = {}

    for slot, options in pairs(playerOptions) do
        if options.Human and options.PL then
            allRatings[options.PlayerName] = options.PL
        end
    end

    return allRatings
end

---@param playerOptions UIAutolobbyPlayer[]
---@return table<string, string>
function CreateDivisionsTable(playerOptions)
    ---@type table<string, string>
    local allDivisions = {}

    for slot, options in pairs(playerOptions) do
        if options.Human and options.PL then
            if options.DIV ~= "unlisted" then
                local division = options.DIV
                if options.SUBDIV and options.SUBDIV ~= "" then
                    division = division .. ' ' .. options.SUBDIV
                end
                allDivisions[options.PlayerName] = division
            end
        end
    end

    return allDivisions
end

---@param playerOptions UIAutolobbyPlayer[]
---@return table<string, string>
function CreateClanTagsTable(playerOptions)
    local allClanTags = {}

    for slot, options in pairs(playerOptions) do
        if options.PlayerClan then
            allClanTags[options.PlayerName] = options.PlayerClan
        end
    end

    return allClanTags
end

--- Prefetches a scenario to try and reduce the loading screen time.
---@param gameOptions UILobbyLaunchGameOptionsConfiguration
---@param gameMods UILobbyLaunchGameModsConfiguration[]
function Prefetch(gameOptions, gameMods)
    local scenarioPath = gameOptions.ScenarioFile
    if not scenarioPath then
        return
    end

    local scenarioFile = MapUtil.LoadScenario(gameOptions.ScenarioFile)
    if not scenarioFile then
        -- ???
        return
    end

    PrefetchSession(scenarioFile.map, gameMods, true)
end

--#endregion

-------------------------------------------------------------------------------
--#region Rejoin

---@param instance UIAutolobbyInstance
---@param lobbyParameters UIAutolobbyParameters
---@param joinParameters UIAutolobbyJoinParameters
function Rejoin(instance, lobbyParameters, joinParameters)
    local autolobbyModule = import("/lua/ui/lobby/autolobby.lua")

    -- start disposing threads to prevent race conditions
    instance.Trash:Destroy()

    ForkThread(
        function()
            instance:SendLaunchStatusToServer('Rejoining')

            -- prevent race condition on network
            WaitSeconds(1.0)

            -- inform peers and server that we're rejoining
            instance:BroadcastData({ Type = "UpdateLaunchStatus", LaunchStatus = 'Rejoining' })

            -- prevent race condition on network
            WaitSeconds(1.0)

            -- create a new lobby
            instance:Destroy()

            -- prevent race conditions
            WaitSeconds(1.0)
            autolobbyModule.CreateLobby(
                lobbyParameters.Protocol,
                lobbyParameters.LocalPort,
                lobbyParameters.DesiredPlayerName,
                lobbyParameters.LocalPlayerPeerId,
                lobbyParameters.NatTraversalProvider
            )

            -- wait a bit before we join
            WaitSeconds(1.0)

            autolobbyModule.JoinGame(joinParameters.Address, joinParameters.AsObserver,
                joinParameters.DesiredPlayerName,
                joinParameters.DesiredPeerId)
        end
    )
end

--#endregion

-------------------------------------------------------------------------------
--#region Threads

---@param instance UIAutolobbyInstance
function CheckForRejoinThread(instance)

    local rejoinThreshold = 3
    local rejoinCount = 0

    while not IsDestroyed(instance) do

        local model = AutolobbyModel.GetSingleton()
        local launchStatutes = model.LaunchStatutes()

        -- check if we're ready to launch
        if launchStatutes[model.LocalPeerId()] ~= 'Ready' then

            -- if we're not, check the status of peers
            local onePeerIsRejoining = false
            local onePeerIsReady = false
            for k, launchStatus in launchStatutes do
                onePeerIsReady = onePeerIsReady or (launchStatus == 'Ready')
                onePeerIsRejoining = onePeerIsRejoining or (launchStatus == 'Rejoining')
            end

            if onePeerIsReady then
                rejoinCount = rejoinCount + 1
            end

            -- try to not rejoin at the same time
            if onePeerIsRejoining then
                rejoinCount = 0
            end
        else
            rejoinCount = 0
        end

        -- if we reached the threshold, time to rejoin!
        if rejoinCount > rejoinThreshold then
            Rejoin(instance, instance.LobbyParameters, instance.JoinParameters)
        end

        WaitSeconds(1.0 + 1 * Random())
    end
end

--- Passes the local launch status to all peers.
---@param instance UIAutolobbyInstance
function ShareLaunchStatusThread(instance)
    while not IsDestroyed(instance) do
        local model = AutolobbyModel.GetSingleton()
        local launchStatus = CreateLaunchStatus(model.ConnectionMatrix(), model.PlayerCount())

        AutolobbyModel.SetPeerStatus(model, model.LocalPeerId(), launchStatus)

        -- update peers
        instance:BroadcastData({ Type = "UpdateLaunchStatus", LaunchStatus = launchStatus })

        -- update server
        instance:SendLaunchStatusToServer(launchStatus)

        WaitSeconds(2.0)
    end
end

---@param instance UIAutolobbyInstance
function LaunchThread(instance)
    while not IsDestroyed(instance) do
        local model = AutolobbyModel.GetSingleton()
        if CanLaunch(model.LaunchStatutes(), model.PlayerCount()) then

            WaitSeconds(5.0)
            if (not IsDestroyed(instance)) and CanLaunch(model.LaunchStatutes(), model.PlayerCount()) then

                local playerOptions = model.PlayerOptions()

                -- Army numbers need to be calculated: they are numbered incrementally in slot order.
                local slots = {}
                for slotIndex, _ in pairs(playerOptions) do
                    table.insert(slots, slotIndex)
                end
                table.sort(slots)

                -- send player options to the server
                for armyIndex, slotIndex in ipairs(slots) do
                    local options = playerOptions[slotIndex]
                    local ownerId = options.OwnerID
                    instance:SendPlayerOptionToServer(ownerId, 'Team', options.Team)
                    instance:SendPlayerOptionToServer(ownerId, 'Army', armyIndex)
                    instance:SendPlayerOptionToServer(ownerId, 'StartSpot', options.StartSpot)
                    instance:SendPlayerOptionToServer(ownerId, 'Faction', options.Faction)
                end

                -- tuck the rating / division / clan tables into the game
                -- options. By all means a hack, but this way they are
                -- available in both the sim and the UI
                local gameOptions = AutolobbyModel.StampLaunchTables(
                    model,
                    CreateRatingsTable(playerOptions),
                    CreateDivisionsTable(playerOptions),
                    CreateClanTagsTable(playerOptions)
                )

                -- create game configuration
                local gameConfiguration = {
                    GameMods = model.GameMods(),
                    GameOptions = gameOptions,
                    PlayerOptions = playerOptions,
                    Observers = {},
                }

                -- send it to all players and tell them to launch with the configuration
                instance:BroadcastData({ Type = "Launch", GameConfig = gameConfiguration })
                instance:LaunchGame(gameConfiguration)
            end
        end

        WaitSeconds(1.0)
    end
end

--#endregion

-------------------------------------------------------------------------------
--#region Message handlers
--
-- Invoked by `AutolobbyMessages.<type>.Handler` after the message has been
-- validated and accepted. They run asynchronously on each client.

---@param instance UIAutolobbyInstance
---@param data UIAutolobbyAddPlayerMessage
function ProcessAddPlayerMessage(instance, data)
    ---@type UIAutolobbyPlayer
    local playerOptions = data.PlayerOptions

    -- override some data
    playerOptions.OwnerID = data.SenderID
    playerOptions.PlayerName = instance:MakeValidPlayerName(playerOptions.OwnerID, playerOptions.PlayerName)

    local model = AutolobbyModel.GetSingleton()

    -- TODO: verify that the StartSpot is not occupied
    -- put the player where it belongs
    AutolobbyModel.SetPlayer(model, playerOptions.StartSpot, playerOptions)

    -- sync game options with the connected peer
    instance:SendData(data.SenderID, { Type = "UpdateGameOptions", GameOptions = model.GameOptions() })

    -- sync player options to all connected peers
    instance:BroadcastData({ Type = "UpdatePlayerOptions", PlayerOptions = model.PlayerOptions() })

    -- the scenario + ownership observers react to the PlayerOptions change
end

---@param instance UIAutolobbyInstance
---@param data UIAutolobbyUpdatePlayerOptionsMessage
function ProcessUpdatePlayerOptionsMessage(instance, data)
    -- a fresh table straight off the network; replace wholesale. The scenario +
    -- ownership observers react to the change.
    AutolobbyModel.GetSingleton().PlayerOptions:Set(data.PlayerOptions)
end

---@param instance UIAutolobbyInstance
---@param data UIAutolobbyUpdateGameOptionsMessage
function ProcessUpdateGameOptionsMessage(instance, data)
    local model = AutolobbyModel.GetSingleton()
    model.GameOptions:Set(data.GameOptions)

    Prefetch(model.GameOptions(), model.GameMods())

    -- the scenario observer reacts to the GameOptions change
end

---@param instance UIAutolobbyInstance
---@param data UIAutolobbyLaunchMessage
function ProcessLaunchMessage(instance, data)
    instance:LaunchGame(data.GameConfig)
end

---@param instance UIAutolobbyInstance
---@param data UIAutolobbyUpdateLaunchStatusMessage
function ProcessUpdateLaunchStatusMessage(instance, data)
    -- the matrix' Statuses observer reacts to the LaunchStatutes change
    AutolobbyModel.SetPeerStatus(AutolobbyModel.GetSingleton(), data.SenderID, data.LaunchStatus)
end

--#endregion

-------------------------------------------------------------------------------
--#region Connection events
--
-- The behaviour behind the engine callbacks of the same name. The instance's
-- callbacks forward here, passing themselves as `instance`.

--- Called as we're trying to host a lobby.
---@param instance UIAutolobbyInstance
function OnHosting(instance)
    local model = AutolobbyModel.GetSingleton()

    local localPeerId = instance:GetLocalPlayerID()
    model.LocalPeerId:Set(localPeerId)
    instance.LocalPlayerName = instance:GetLocalPlayerName()
    instance.HostID = localPeerId

    -- give ourself a seat at the table
    local hostPlayerOptions = instance:CreateLocalPlayer()
    hostPlayerOptions.OwnerID = localPeerId
    hostPlayerOptions.PlayerName = instance:MakeValidPlayerName(localPeerId, instance.LocalPlayerName)
    AutolobbyModel.SetPlayer(model, hostPlayerOptions.StartSpot, hostPlayerOptions)

    -- occasionally send data over the network to create pings on screen
    instance.Trash:Add(ForkThread(ShareLaunchStatusThread, instance))
    instance.Trash:Add(ForkThread(LaunchThread, instance))

    -- start prefetching the scenario
    Prefetch(model.GameOptions(), model.GameMods())

    instance:SendLaunchStatusToServer('Hosting')

    -- the scenario observer reacts to the PlayerOptions change
end

--- Called when the connection succeeds with the host.
---@param instance UIAutolobbyInstance
---@param localPeerId UILobbyPeerId
---@param newLocalName string
---@param hostPeerId string
function OnConnectionToHostEstablished(instance, localPeerId, newLocalName, hostPeerId)
    instance.LocalPlayerName = newLocalName
    AutolobbyModel.GetSingleton().LocalPeerId:Set(localPeerId)
    instance.HostID = hostPeerId

    -- occasionally send data over the network to create pings on screen
    instance.Trash:Add(ForkThread(ShareLaunchStatusThread, instance))
    -- instance.Trash:Add(ForkThread(CheckForRejoinThread, instance)) -- disabled, for now

    instance:SendData(instance.HostID, { Type = "AddPlayer", PlayerOptions = instance:CreateLocalPlayer() })
end

--- Called when a peer establishes a connection.
---@param instance UIAutolobbyInstance
---@param peerId UILobbyPeerId
---@param peerConnectedTo UILobbyPeerId[]    # all established connections for the given player
function OnEstablishedPeers(instance, peerId, peerConnectedTo)
    -- update server
    instance:SendEstablishedPeer(peerId)

    local model = AutolobbyModel.GetSingleton()

    -- seed an initial status for the peer and record its connections; the
    -- matrix' Statuses / Connections observers react to the changes
    AutolobbyModel.EnsurePeerStatus(model, peerId, 'Unknown')
    AutolobbyModel.SetPeerConnections(model, peerId, peerConnectedTo)
end

--- Called when the connection fails.
---@param instance UIAutolobbyInstance
function OnConnectionFailed(instance)
    -- try to rejoin
    Rejoin(instance, instance.LobbyParameters, instance.JoinParameters)
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: re-imports this module after a couple of frames so the
--- instance's forwarders resolve to the fresh functions.
function __moduleinfo.OnDirty()
    ForkThread(
        function()
            WaitFrames(2)
            import(__moduleinfo.name)
        end
    )
end

--#endregion
