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

local Utils = import("/lua/system/utils.lua")
local MapUtil = import("/lua/ui/maputil.lua")
local GameColors = import("/lua/gamecolors.lua")

local MohoLobbyMethods = moho.lobby_methods
local DebugComponent = import("/lua/shared/components/debugcomponent.lua").DebugComponent
local AutolobbyServerCommunicationsComponent = import("/lua/ui/lobby/autolobby/components/autolobbyservercommunicationscomponent.lua")
    .AutolobbyServerCommunicationsComponent

local AutolobbyArgumentsComponent = import("/lua/ui/lobby/autolobby/components/autolobbyarguments.lua").AutolobbyArgumentsComponent

local AutolobbyMessages = import("/lua/ui/lobby/autolobby/autolobbymessages.lua").AutolobbyMessages

local AutolobbyEngineStrings = {
    --  General info strings
    ['Connecting'] = "<LOC lobui_0083>Connecting to Game",
    ['AbortConnect'] = "<LOC lobui_0204>Abort Connect",
    ['TryingToConnect'] = "<LOC lobui_0331>Connecting...",
    ['TimedOut'] = "<LOC lobui_0205>%s timed out.",
    ['TimedOutToHost'] = "<LOC lobui_0206>Timed out to host.",
    ['Ejected'] = "<LOC lob_0000>You have been ejected: %s",
    ['ConnectionFailed'] = "<LOC lob_0001>Connection failed: %s",
    ['LaunchFailed'] = "<LOC lobui_0207>Launch failed: %s",
    ['LobbyFull'] = "<LOC lobui_0279>The game lobby is full.",

    --  Error reasons
    ['StartSpots'] = "<LOC lob_0002>The map does not support this number of players.",
    ['NoConfig'] = "<LOC lob_0003>No valid game configurations found.",
    ['NoObservers'] = "<LOC lob_0004>Observers not allowed.",
    ['KickedByHost'] = "<LOC lob_0005>Kicked by host.",
    ['GameLaunched'] = "<LOC lob_0008>Game was launched.",
    ['NoLaunchLimbo'] = "<LOC lob_0006>No clients allowed in limbo at launch",
    ['HostLeft'] = "<LOC lob_0007>Host abandoned lobby",
    ['LaunchRejected'] = "<LOC lob_0009>Some players are using an incompatible client version.",
}

-- associated textures are in `/textures/divisions/<division> <subdivision>.png` 
-- Make note of the space, which isn't there for "grandmaster" and "unlisted" divisions

---@alias Division
---| "bronze"
---| "silver"
---| "gold"
---| "diamond"
---| "master"
---| "grandmaster"
---| "unlisted"

---@alias Subdivision
---| "I"
---| "II"
---| "III"
---| "IV"
---| "V"
---| "" # when Division is grandmaster or unlisted

---@class UIAutolobbyPlayer: UILobbyLaunchPlayerConfiguration
---@field StartSpot number
---@field DEV number    # Related to rating/divisions
---@field MEAN number   # Related to rating/divisions
---@field NG number     # Related to rating/divisions
---@field DIV Division    # Related to rating/divisions
---@field SUBDIV Subdivision # Related to rating/divisions
---@field PL number     # Related to rating/divisions
---@field PlayerClan string

---@alias UIAutolobbyConnections boolean[][]
---@alias UIAutolobbyStatus UIPeerLaunchStatus[]

---@class UIAutolobbyParameters
---@field Protocol UILobbyProtocol
---@field LocalPort number
---@field MaxConnections number
---@field DesiredPlayerName string
---@field LocalPlayerPeerId UILobbyPeerId
---@field NatTraversalProvider any

---@class UIAutolobbyHostParameters
---@field GameName string
---@field ScenarioFile string   # path to the _scenario.lua file
---@field SinglePlayer boolean

---@class UIAutolobbyJoinParameters
---@field Address GPGNetAddress
---@field AsObserver boolean
---@field DesiredPlayerName string
---@field DesiredPeerId UILobbyPeerId

--- Responsible for the behavior of the automated lobby.
---@class UIAutolobbyCommunications : moho.lobby_methods, DebugComponent, UIAutolobbyServerCommunicationsComponent, UIAutolobbyArgumentsComponent
---@field Trash TrashBag
---@field LocalPeerId UILobbyPeerId                             # a number that is stringified
---@field LocalPlayerName string                            # nickname
---@field HostID UILobbyPeerId
---@field PlayerCount number                                        # Originates from the command line
---@field GameMods UILobbyLaunchGameModsConfiguration[]
---@field GameOptions UILobbyLaunchGameOptionsConfiguration         # Is synced from the host via `SendData` or `BroadcastData`.
---@field PlayerOptions UIAutolobbyPlayer[]                         # Is synced from the host via `SendData` or `BroadcastData`.
---@field ConnectionMatrix table<UILobbyPeerId, UILobbyPeerId[]>    # Is synced between players via `EstablishedPeers`
---@field LaunchStatutes table<UILobbyPeerId, UIPeerLaunchStatus>  # Is synced between players via `BroadcastData`
---@field LobbyParameters? UIAutolobbyParameters                # Used for rejoining functionality
---@field HostParameters? UIAutolobbyHostParameters             # Used for rejoining functionality
---@field JoinParameters? UIAutolobbyJoinParameters             # Used for rejoining functionality
AutolobbyCommunications = Class(MohoLobbyMethods, AutolobbyServerCommunicationsComponent, AutolobbyArgumentsComponent, DebugComponent) {

    ---@param self UIAutolobbyCommunications
    __init = function(self)
        self.Trash = TrashBag()

        self.LocalPeerId = "-2"
        self.LocalPlayerName = "Charlie"
        self.PlayerCount = self:GetCommandLineArgumentNumber("/players", 2)
        self.HostID = "-2"

        self.GameMods = {}
        self.GameOptions = self:CreateLocalGameOptions()
        self.PlayerOptions = {}
        self.LaunchStatutes = {}
        self.ConnectionMatrix = {}
    end,

    ---@param self UIAutolobbyCommunications
    __post_init = function(self)

    end,

    --- Creates a table that represents the local player settings. This represents the initial player. It can be edited by the host accordingly.
    ---@param self UIAutolobbyCommunications
    ---@return UIAutolobbyPlayer
    CreateLocalPlayer = function(self)
        ---@type UIAutolobbyPlayer
        local info = {}

        info.Human = true
        info.Civilian = false

        -- determine player name
        info.PlayerName = self.LocalPlayerName or self:GetLocalPlayerName() or "player"

        -- retrieve faction
        info.Faction = 1
        local factionData = import("/lua/factions.lua")
        for index, tbl in factionData.Factions do
            if HasCommandLineArg("/" .. tbl.Key) then
                info.Faction = index
                break
            end
        end

        -- retrieve team and start spot
        info.Team = self:GetCommandLineArgumentNumber("/team", -1)
        info.StartSpot = self:GetCommandLineArgumentNumber("/startspot", -1)

        -- determine army color based on start location
        info.PlayerColor = GameColors.MapToWarmCold(info.StartSpot)
        info.ArmyColor = GameColors.MapToWarmCold(info.StartSpot)

        -- retrieve rating
        info.DEV = self:GetCommandLineArgumentNumber("/deviation", 500)
        info.MEAN = self:GetCommandLineArgumentNumber("/mean", 1500)
        info.NG = self:GetCommandLineArgumentNumber("/numgames", 0)
        info.DIV = self:GetCommandLineArgumentString("/division", "")
        info.SUBDIV = self:GetCommandLineArgumentString("/subdivision", "")
        info.PL = math.floor(info.MEAN - 3 * info.DEV)
        info.PlayerClan = self:GetCommandLineArgumentString("/clan", "")

        return info
    end,

    --- Creates a table that represents the local game options.
    ---@param self UIAutolobbyCommunications
    ---@return UILobbyLaunchGameOptionsConfiguration
    CreateLocalGameOptions = function(self)
        ---@type UILobbyLaunchGameOptionsConfiguration
        local options = {
            Score = 'no',
            TeamSpawn = 'fixed',
            TeamLock = 'locked',
            Victory = 'demoralization',
            Timeouts = '3',
            CheatsEnabled = 'false',
            CivilianAlliance = 'enemy',
            RevealCivilians = 'Yes',
            GameSpeed = 'normal',
            FogOfWar = 'explored',
            UnitCap = '1500',
            PrebuiltUnits = 'Off',
            Share = 'FullShare',
            ShareUnitCap = 'allies',
            DisconnectionDelay02 = '90',
            DisconnectShare = 'SameAsShare',
            DisconnectShareCommanders = 'Explode',

            -- yep, great
            Ranked = true,
            Unranked = 'No',
        }

        -- process game options from the command line
        for name, value in self:GetCommandLineArgumentArray("/gameoptions") do
            if name and value then
                options[name] = value
            else
                LOG("Malformed gameoption. ignoring name: " .. repr(name) .. " and value: " .. repr(value))
            end
        end

        return options
    end,

    ---------------------------------------------------------------------------
    --#region Utilities

    ---@param self UIAutolobbyCommunications
    ---@param playerOptions UIAutolobbyPlayer[]
    ---@param connectionMatrix table<UILobbyPeerId, UILobbyPeerId[]>
    ---@return UIAutolobbyConnections
    CreateConnectionsMatrix = function(self, playerOptions, connectionMatrix)
        ---@type UIAutolobbyConnections
        local connections = {}

        -- initial setup
        for y = 1, self.PlayerCount do
            connections[y] = {}
            for x = 1, self.PlayerCount do
                connections[y][x] = false
            end
        end

        -- populate the matrix
        for peerId, establishedPeers in connectionMatrix do
            for _, peerConnectedToId in establishedPeers do
                local peerIdNumber = self:PeerIdToIndex(playerOptions, peerId)
                local peerConnectedToIdNumber = self:PeerIdToIndex(playerOptions, peerConnectedToId)

                -- connection works both ways
                if peerIdNumber and peerConnectedToIdNumber then
                    if peerIdNumber > self.PlayerCount or peerConnectedToIdNumber > self.PlayerCount then
                        self:DebugWarn("Invalid peer id", peerIdNumber, peerConnectedToIdNumber)
                    else
                        connections[peerIdNumber][peerConnectedToIdNumber] = true
                        connections[peerConnectedToIdNumber][peerIdNumber] = true
                    end
                end
            end
        end

        return connections
    end,

    ---@param self UIAutolobbyCommunications
    ---@param playerOptions UIAutolobbyPlayer[]
    ---@param statuses table<UILobbyPeerId, UIPeerLaunchStatus>
    ---@return UIAutolobbyStatus
    CreateConnectionStatuses = function(self, playerOptions, statuses)
        local output = {}
        for peerId, launchStatus in statuses do
            local peerIdNumber = self:PeerIdToIndex(playerOptions, peerId)
            if peerIdNumber then
                output[peerIdNumber] = launchStatus
            end
        end

        return output
    end,

    ---@param self UIAutolobbyCommunications
    ---@param playerCount number
    ---@param localIndex number
    ---@return boolean[][]
    CreateOwnershipMatrix = function(self, playerCount, localIndex)
        local output = {}
        for y = 1, playerCount do
            output[y] = {}
            for x = 1, playerCount do
                output[y][x] = false
            end
        end

        for k = 1, playerCount do
            output[localIndex][k] = true
            output[k][localIndex] = true
        end
        return output
    end,

    --- Determines the launch status of the local peer.
    ---@param self UIAutolobbyCommunications
    ---@param connectionMatrix table<UILobbyPeerId, UILobbyPeerId[]>
    ---@return UIPeerLaunchStatus
    CreateLaunchStatus = function(self, connectionMatrix)
        -- check number of peers
        local validPeerCount = self.PlayerCount - 1
        if table.getsize(connectionMatrix) < validPeerCount then
            return 'Missing local peers'
        end

        return 'Ready'
    end,

    ---@param self UIAutolobbyCommunications
    ---@param playerOptions UIAutolobbyPlayer[]
    ---@return table<string, number>
    CreateRatingsTable = function(self, playerOptions)
        ---@type table<string, number>
        local allRatings = {}

        for slot, options in pairs(playerOptions) do
            if options.Human and options.PL then
                allRatings[options.PlayerName] = options.PL
            end
        end

        return allRatings
    end,

    ---@param self UIAutolobbyCommunications
    ---@param playerOptions UIAutolobbyPlayer[]
    ---@return table<string, string>
    CreateDivisionsTable = function(self, playerOptions)
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
    end,

    ---@param self UIAutolobbyCommunications
    ---@param playerOptions UIAutolobbyPlayer[]
    ---@return table<string, string>
    CreateClanTagsTable = function(self, playerOptions)
        local allClanTags = {}

        for slot, options in pairs(playerOptions) do
            if options.PlayerClan then
                allClanTags[options.PlayerName] = options.PlayerClan
            end
        end

        return allClanTags
    end,

    --- Verifies whether we can launch the game.
    ---@param self UIAutolobbyCommunications
    ---@param peerStatus UIAutolobbyStatus
    ---@return boolean
    CanLaunch = function(self, peerStatus)
        -- check if we know of all peers
        if table.getsize(peerStatus) ~= self.PlayerCount then
            return false
        end

        -- check if all peers are ready for launch
        for k, launchStatus in peerStatus do
            if launchStatus ~= 'Ready' then
                return false
            end
        end

        return true
    end,

    --- Maps a peer id to an index that can be used in the interface. In
    --- practice the peer id can be all over the place, ranging from -1
    --- to numbers such as 35240. With this function we map it to a sane
    --- index that we can use in the interface.
    ---@param self UIAutolobbyCommunications
    ---@param playerOptions UIAutolobbyPlayer[]
    ---@param peerId UILobbyPeerId
    ---@return number | false
    PeerIdToIndex = function(self, playerOptions, peerId)
        if type(peerId) ~= 'string' then
            self:DebugWarn("Invalid peer id", peerId)
            return false
        end

        -- try to find matching player options
        if playerOptions then
            for k, options in playerOptions do
                if options.OwnerID == peerId then
                    if options.StartSpot then
                        return options.StartSpot
                    end
                end
            end
        end

        return false
    end,

    --- Prefetches a scenario to try and reduce the loading screen time.
    ---@param self UIAutolobbyCommunications
    ---@param gameOptions UILobbyLaunchGameOptionsConfiguration
    ---@param gameMods UILobbyLaunchGameModsConfiguration[]
    Prefetch = function(self, gameOptions, gameMods)
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
    end,

    ---@param self UIAutolobbyCommunications
    ---@param lobbyParameters UIAutolobbyParameters
    ---@param joinParameters UIAutolobbyJoinParameters
    Rejoin = function(self, lobbyParameters, joinParameters)
        local autolobbyModule = import("/lua/ui/lobby/autolobby.lua")

        -- start disposing threads to prevent race conditions
        self.Trash:Destroy()

        ForkThread(
            function()
                self:SendLaunchStatusToServer('Rejoining')

                -- prevent race condition on network
                WaitSeconds(1.0)

                -- inform peers and server that we're rejoining
                self:BroadcastData({ Type = "UpdateLaunchStatus", LaunchStatus = 'Rejoining' })

                -- prevent race condition on network
                WaitSeconds(1.0)

                -- create a new lobby
                self:Destroy()

                -- prevent race conditions
                WaitSeconds(1.0)
                local newLobby = autolobbyModule.CreateLobby(
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
    end,


    ---------------------------------------------------------------------------
    --#region Threads

    ---@param self UIAutolobbyCommunications
    CheckForRejoinThread = function(self)

        local rejoinThreshold = 3
        local rejoinCount = 0

        while not IsDestroyed(self) do

            -- check if we're ready to launch
            if self.LaunchStatutes[self.LocalPeerId] ~= 'Ready' then

                -- if we're not, check the status of peers
                local onePeerIsRejoining = false
                local onePeerIsReady = false
                for k, launchStatus in self.LaunchStatutes do
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
                self:Rejoin(self.LobbyParameters, self.JoinParameters)
            end

            WaitSeconds(1.0 + 1 * Random())
        end
    end,

    --- Passes the local launch status to all peers.
    ---@param self UIAutolobbyCommunications
    ShareLaunchStatusThread = function(self)
        while not IsDestroyed(self) do
            local launchStatus = self:CreateLaunchStatus(self.ConnectionMatrix)
            self.LaunchStatutes[self.LocalPeerId] = launchStatus

            -- update peers
            self:BroadcastData({ Type = "UpdateLaunchStatus", LaunchStatus = launchStatus })

            -- update server
            self:SendLaunchStatusToServer(launchStatus)

            -- update UI for launch statuses
            import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
                :UpdateLaunchStatuses(self:CreateConnectionStatuses(self.PlayerOptions, self.LaunchStatutes))

            WaitSeconds(2.0)
        end
    end,

    ---@param self UIAutolobbyCommunications
    LaunchThread = function(self)
        while not IsDestroyed(self) do
            if self:CanLaunch(self.LaunchStatutes) then

                WaitSeconds(5.0)
                if (not IsDestroyed(self)) and self:CanLaunch(self.LaunchStatutes) then

                    -- send player options to the server
                    for slot, playerOptions in self.PlayerOptions do
                        local ownerId = playerOptions.OwnerID
                        self:SendPlayerOptionToServer(ownerId, 'Team', playerOptions.Team)
                        self:SendPlayerOptionToServer(ownerId, 'Army', playerOptions.StartSpot)
                        self:SendPlayerOptionToServer(ownerId, 'StartSpot', playerOptions.StartSpot)
                        self:SendPlayerOptionToServer(ownerId, 'Faction', playerOptions.Faction)
                    end

                    -- tuck them into the game options. By all means a hack, but
                    -- this way they are available in both the sim and the UI
                    self.GameOptions.Ratings = self:CreateRatingsTable(self.PlayerOptions)
                    self.GameOptions.Divisions = self:CreateDivisionsTable(self.PlayerOptions)
                    self.GameOptions.ClanTags = self:CreateClanTagsTable(self.PlayerOptions)

                    -- create game configuration
                    local gameConfiguration = {
                        GameMods = self.GameMods,
                        GameOptions = self.GameOptions,
                        PlayerOptions = self.PlayerOptions,
                        Observers = {},
                    }

                    -- send it to all players and tell them to launch with the configuration
                    self:BroadcastData({ Type = "Launch", GameConfig = gameConfiguration })
                    self:LaunchGame(gameConfiguration)
                end
            end

            WaitSeconds(1.0)
        end
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Message Handlers
    --
    -- All the message functions in this section run asynchroniously on each
    -- client. They are responsible for processing the data received from
    -- other peers. Validation is done in `AutolobbyMessages` before the message
    -- processed.

    ---@param self UIAutolobbyCommunications
    ---@param data UIAutolobbyAddPlayerMessage
    ProcessAddPlayerMessage = function(self, data)
        ---@type UIAutolobbyPlayer
        local playerOptions = data.PlayerOptions

        -- override some data
        playerOptions.OwnerID = data.SenderID
        playerOptions.PlayerName = self:MakeValidPlayerName(playerOptions.OwnerID, playerOptions.PlayerName)

        -- TODO: verify that the StartSpot is not occupied
        -- put the player where it belongs
        self.PlayerOptions[playerOptions.StartSpot] = playerOptions

        -- sync game options with the connected peer
        self:SendData(data.SenderID, { Type = "UpdateGameOptions", GameOptions = self.GameOptions })

        -- sync player options to all connected peers
        self:BroadcastData({ Type = "UpdatePlayerOptions", PlayerOptions = self.PlayerOptions })

        -- update UI for player options
        import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
            :UpdateScenario(self.GameOptions.ScenarioFile, self.PlayerOptions)

        local localIndex = self:PeerIdToIndex(self.PlayerOptions, self.LocalPeerId)
        if localIndex then
            local ownershipMatrix = self:CreateOwnershipMatrix(self.PlayerCount, localIndex)
            import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
                :UpdateOwnership(ownershipMatrix)
        end
    end,

    ---@param self UIAutolobbyCommunications
    ---@param data UIAutolobbyUpdatePlayerOptionsMessage
    ProcessUpdatePlayerOptionsMessage = function(self, data)
        self.PlayerOptions = data.PlayerOptions

        -- update UI for player options
        import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
            :UpdateScenario(self.GameOptions.ScenarioFile, self.PlayerOptions)

        local localIndex = self:PeerIdToIndex(self.PlayerOptions, self.LocalPeerId)
        if localIndex then
            local ownershipMatrix = self:CreateOwnershipMatrix(self.PlayerCount, localIndex)
            -- update UI for player options
            import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
                :UpdateOwnership(ownershipMatrix)
        end
    end,

    ---@param self UIAutolobbyCommunications
    ---@param data UIAutolobbyUpdateGameOptionsMessage
    ProcessUpdateGameOptionsMessage = function(self, data)
        self.GameOptions = data.GameOptions

        self:Prefetch(self.GameOptions, self.GameMods)

        -- update UI for game options
        import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
            :UpdateScenario(self.GameOptions.ScenarioFile, self.PlayerOptions)
    end,

    ---@param self UIAutolobbyCommunications
    ---@param data UIAutolobbyLaunchMessage
    ProcessLaunchMessage = function(self, data)
        self:LaunchGame(data.GameConfig)
    end,

    ---@param self UIAutolobbyCommunications
    ---@param data UIAutolobbyUpdateLaunchStatusMessage
    ProcessUpdateLaunchStatusMessage = function(self, data)
        self.LaunchStatutes[data.SenderID] = data.LaunchStatus

        -- update UI for launch statuses
        import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
            :UpdateLaunchStatuses(self:CreateConnectionStatuses(self.PlayerOptions, self.LaunchStatutes))
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Engine interface

    --- Broadcasts data to all (connected) peers.
    ---@param self UIAutolobbyCommunications
    ---@param data UILobbyData
    BroadcastData = function(self, data)
        self:DebugSpew("BroadcastData", data.Type)

        -- validate message type
        local message = AutolobbyMessages[data.Type]
        if not message then
            self:DebugWarn("Blocked broadcasting unknown message type", data.Type)
            return
        end

        -- validate message format
        if not message.Validate(self, data) then
            self:DebugWarn("Blocked broadcasting malformed message of type", data.Type)
            return
        end

        return MohoLobbyMethods.BroadcastData(self, data)
    end,

    --- (Re)Connects to a peer.
    ---@param self any
    ---@param address any
    ---@param name any
    ---@param peerId UILobbyPeerId
    ---@return nil
    ConnectToPeer = function(self, address, name, peerId)
        self:DebugSpew("ConnectToPeer", address, name, peerId)
        return MohoLobbyMethods.ConnectToPeer(self, address, name, peerId)
    end,

    --- ???
    ---@param self UIAutolobbyCommunications
    ---@return nil
    DebugDump = function(self)
        self:DebugSpew("DebugDump")
        return MohoLobbyMethods.DebugDump(self)
    end,

    --- Destroys the C-object and all the (UI) entities in the trash bag.
    ---@param self UIAutolobbyCommunications
    ---@return nil
    Destroy = function(self)
        self:DebugSpew("Destroy")

        self.Trash:Destroy()
        return MohoLobbyMethods.Destroy(self)
    end,

    --- Disconnects from a peer.
    --- See also `ConnectToPeer` to connect
    ---@param self UIAutolobbyCommunications
    ---@param peerId UILobbyPeerId
    ---@return nil
    DisconnectFromPeer = function(self, peerId)
        self:DebugSpew("DisconnectFromPeer", peerId)

        return MohoLobbyMethods.DisconnectFromPeer(self, peerId)
    end,

    --- Ejects a peer from the lobby.
    ---@param self UIAutolobbyCommunications
    ---@param peerId UILobbyPeerId
    ---@param reason string
    ---@return nil
    EjectPeer = function(self, peerId, reason)
        self:DebugSpew("EjectPeer", peerId, reason)
        return MohoLobbyMethods.EjectPeer(self, peerId, reason)
    end,

    --- Retrieves the local identifier.
    ---@param self UIAutolobbyCommunications
    ---@return UILobbyPeerId
    GetLocalPlayerID = function(self)
        self:DebugSpew("GetLocalPlayerID")
        return MohoLobbyMethods.GetLocalPlayerID(self)
    end,

    --- Retrieves the local name. Note that this name can be overwritten by the host via `MakeValidPlayerName`
    ---@param self UIAutolobbyCommunications
    ---@return string
    GetLocalPlayerName = function(self)
        self:DebugSpew("GetLocalPlayerName")
        return MohoLobbyMethods.GetLocalPlayerName(self)
    end,

    --- Retrieves the local port.
    ---@param self any
    ---@return number|nil
    GetLocalPort = function(self)
        self:DebugSpew("GetLocalPort")
        return MohoLobbyMethods.GetLocalPort(self)
    end,

    --- Retrieves information about a peer. See `GetPeers` to get the same information for all connected peers.
    ---@param self UIAutolobbyCommunications
    ---@param peerId UILobbyPeerId
    ---@return Peer
    GetPeer = function(self, peerId)
        self:DebugSpew("GetPeer", peerId)
        return MohoLobbyMethods.GetPeer(self, peerId)
    end,

    --- Retrieves information about all connected peers. See `GetPeer` to get information for a specific peer.
    ---@param self UIAutolobbyCommunications
    GetPeers = function(self)
        -- self:DebugSpew("GetPeers")
        return MohoLobbyMethods.GetPeers(self)
    end,

    --- Transforms the lobby to be discoveryable and joinable for other players.
    ---@param self UIAutolobbyCommunications
    ---@return nil
    HostGame = function(self)
        self:DebugSpew("HostGame")
        return MohoLobbyMethods.HostGame(self)
    end,

    --- Retrieves whether the local client is the host.
    ---@param self any
    ---@return boolean
    IsHost = function(self)
        self:DebugSpew("IsHost")
        return MohoLobbyMethods.IsHost(self)
    end,

    --- Join a lobby that is set to be a host.
    ---@param self UIAutolobbyCommunications
    ---@param address GPGNetAddress
    ---@param remotePlayerName string
    ---@param remotePlayerPeerId UILobbyPeerId
    ---@return nil
    JoinGame = function(self, address, remotePlayerName, remotePlayerPeerId)
        self:DebugSpew("JoinGame", address, remotePlayerName, remotePlayerPeerId)
        return MohoLobbyMethods.JoinGame(self, address, remotePlayerName, remotePlayerPeerId)
    end,

    --- Launches the game for the local client. The game configuration that is passed in should originate from the host.
    ---@param self UIAutolobbyCommunications
    ---@param gameConfig UILobbyLaunchConfiguration
    ---@return nil
    LaunchGame = function(self, gameConfig)
        self:DebugSpew("LaunchGame")
        self:DebugSpew(reprs(gameConfig, { depth = 10 }))

        return MohoLobbyMethods.LaunchGame(self, gameConfig)
    end,

    --- Returns a valid game name.
    ---@param self UIAutolobbyCommunications
    ---@param name string
    ---@return string
    MakeValidGameName = function(self, name)

        self:DebugSpew("MakeValidGameName", name)
        return MohoLobbyMethods.MakeValidGameName(self, name)
    end,

    --- Returns a valid player name.
    ---@param self UIAutolobbyCommunications
    ---@param peerId UILobbyPeerId
    ---@param name string
    ---@return string
    MakeValidPlayerName = function(self, peerId, name)
        self:DebugSpew("MakeValidPlayerName", peerId, name)
        return MohoLobbyMethods.MakeValidPlayerName(self, peerId, name)
    end,

    ---@param self UIAutolobbyCommunications
    ---@param peerId UILobbyPeerId
    ---@param data UILobbyData
    ---@return nil
    SendData = function(self, peerId, data)
        self:DebugSpew("SendData", peerId, data.Type)

        -- validate message type
        local message = AutolobbyMessages[data.Type]
        if not message then
            self:DebugWarn("Blocked sending unknown message type", data.Type, "to", peerId)
            return
        end

        -- validate message type
        if not message.Validate(self, data) then
            self:DebugWarn("Blocked sending malformed message of type", data.Type, "to", peerId)
            return
        end

        return MohoLobbyMethods.SendData(self, peerId, data)
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Connection events

    --- Called by the engine as we're trying to host a lobby.
    ---@param self UIAutolobbyCommunications
    Hosting = function(self)
        self:DebugSpew("Hosting")

        self.LocalPeerId = self:GetLocalPlayerID()
        self.LocalPlayerName = self:GetLocalPlayerName()
        self.HostID = self:GetLocalPlayerID()

        -- give ourself a seat at the table
        local hostPlayerOptions = self:CreateLocalPlayer()
        hostPlayerOptions.OwnerID = self.LocalPeerId
        hostPlayerOptions.PlayerName = self:MakeValidPlayerName(self.LocalPeerId, self.LocalPlayerName)
        self.PlayerOptions[hostPlayerOptions.StartSpot] = hostPlayerOptions

        -- occasionally send data over the network to create pings on screen
        self.Trash:Add(ForkThread(self.ShareLaunchStatusThread, self))
        self.Trash:Add(ForkThread(self.LaunchThread, self))

        -- start prefetching the scenario
        self:Prefetch(self.GameOptions, self.GameMods)

        self:SendLaunchStatusToServer('Hosting')

        -- update UI for game options
        import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
            :UpdateScenario(self.GameOptions.ScenarioFile, self.PlayerOptions)
    end,

    --- Called by the engine as we're trying to join a lobby.
    ---@param self UIAutolobbyCommunications
    Connecting = function(self)
        self:DebugSpew("Connecting")
        self:SendLaunchStatusToServer('Connecting')
    end,

    --- Called by the engine when the connection fails.
    ---@param self UIAutolobbyCommunications
    ---@param reason string     # reason for connection failure, populated by the engine
    ConnectionFailed = function(self, reason)
        self:DebugSpew("ConnectionFailed", reason)

        -- try to rejoin
        self:Rejoin(self.LobbyParameters, self.JoinParameters)
    end,

    --- Called by the engine when the connection succeeds with the host.
    ---@param self UIAutolobbyCommunications
    ---@param localPeerId UILobbyPeerId
    ---@param hostPeerId string
    ConnectionToHostEstablished = function(self, localPeerId, newLocalName, hostPeerId)
        self:DebugSpew("ConnectionToHostEstablished", localPeerId, newLocalName, hostPeerId)
        self.LocalPlayerName = newLocalName
        self.LocalPeerId = localPeerId
        self.HostID = hostPeerId

        -- occasionally send data over the network to create pings on screen
        self.Trash:Add(ForkThread(self.ShareLaunchStatusThread, self))
        -- self.Trash:Add(ForkThread(self.CheckForRejoinThread, self)) -- disabled, for now

        self:SendData(self.HostID, { Type = "AddPlayer", PlayerOptions = self:CreateLocalPlayer() })
    end,

    --- Called by the engine when a peer establishes a connection.
    ---@param self UIAutolobbyCommunications
    ---@param peerId UILobbyPeerId
    ---@param peerConnectedTo UILobbyPeerId[]    # all established conenctions for the given player
    EstablishedPeers = function(self, peerId, peerConnectedTo)
        self:DebugSpew("EstablishedPeers", peerId, reprs(peerConnectedTo))

        -- update server
        self:SendEstablishedPeer(peerId)

        self.LaunchStatutes[peerId] = self.LaunchStatutes[peerId] or 'Unknown'
        -- update UI for launch statuses
        import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
            :UpdateLaunchStatuses(self:CreateConnectionStatuses(self.PlayerOptions, self.LaunchStatutes))

        -- update the matrix and the UI
        self.ConnectionMatrix[peerId] = peerConnectedTo
        local connections = self:CreateConnectionsMatrix(self.PlayerOptions, self.ConnectionMatrix)
        import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
            :UpdateConnections(connections)
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Lobby events

    --- Called by the engine when you are ejected from a lobby.
    ---@param self UIAutolobbyCommunications
    ---@param reason string     # reason for disconnection, populated by the host
    Ejected = function(self, reason)
        self:DebugSpew("Ejected", reason)
        self:SendLaunchStatusToServer('Ejected')
    end,

    --- ???
    ---@param self UIAutolobbyCommunications
    ---@param text string
    SystemMessage = function(self, text)
        self:DebugSpew("SystemMessage", text)
    end,

    --- Called by the engine when we receive data from other players. There is no checking to see if the data is legitimate, these need to be done in Lua.
    ---
    --- Data can be send via `BroadcastData` and/or `SendData`.
    ---@param self UIAutolobbyCommunications
    ---@param data UILobbyReceivedMessage
    DataReceived = function(self, data)
        self:DebugSpew("DataReceived", data.Type, data.SenderID, data.SenderName)

        -- signal UI that we received something
        local peerIndex = self:PeerIdToIndex(self.PlayerOptions, data.SenderID)
        if peerIndex then
            import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
                :UpdateIsAliveStamp(peerIndex)
        end

        -- validate message type
        local message = AutolobbyMessages[data.Type]
        if not message then
            self:DebugWarn("Ignoring unknown message type", data.Type, "from", data.SenderID)
            return
        end

        -- validate message data
        if not message.Validate(self, data) then
            self:DebugWarn("Ignoring malformed message of type", data.Type, "from", data.SenderID)
            return
        end

        -- validate message source
        if not message.Accept(self, data) then
            self:DebugWarn("Message rejected: ", data.Type)
            return
        end

        -- handle the message
        message.Handler(self, data)
    end,

    --- Called by the engine when the game configuration is requested by the discovery service.
    ---@param self UIAutolobbyCommunications
    GameConfigRequested = function(self)
        self:DebugSpew("GameConfigRequested")
    end,

    --- Called by the engine when a peer disconnects.
    ---@param self UIAutolobbyCommunications
    ---@param peerName string
    ---@param peerId UILobbyPeerId
    PeerDisconnected = function(self, peerName, peerId)
        self:DebugSpew("PeerDisconnected", peerName, peerId)
        self:SendDisconnectedPeer(peerId)
    end,

    --- Called by the engine when the game is launched.
    ---@param self UIAutolobbyCommunications
    GameLaunched = function(self)
        self:DebugSpew("GameLaunched")

        -- clear out the interface
        import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton():Destroy()

        -- destroy ourselves, the game takes over the management of peers
        self:Destroy()

        self:SendGameStateToServer('Launching')
    end,

    --- Called by the engine when the launch failed.
    ---@param self UIAutolobbyCommunications
    ---@param reasonKey string
    LaunchFailed = function(self, reasonKey)
        self:DebugSpew("LaunchFailed", LOC(reasonKey))
        self:SendLaunchStatusToServer('Failed')
    end,

    --#endregion

    --#region Debugging

    ---@param self UIAutolobbyCommunications
    ---@param ... any
    DebugSpew = function(self, ...)
        if not self.EnabledSpewing then
            return
        end

        SPEW("Autolobby communications", unpack(arg))
    end,


    ---@param self UIAutolobbyCommunications
    ---@param ... any
    DebugLog = function(self, ...)
        if not self.EnabledLogging then
            return
        end

        LOG("Autolobby communications", unpack(arg))
    end,

    ---@param self UIAutolobbyCommunications
    ---@param ... any
    DebugWarn = function(self, ...)
        if not self.EnabledWarnings then
            return
        end

        WARN("Autolobby communications", unpack(arg))
    end,

    ---@param self UIAutolobbyCommunications
    ---@param ... any
    DebugError = function(self, ...)
        if not self.EnabledErrors then
            return
        end

        local message = "Autolobby communications"
        for _, arg in ipairs(arg) do
            message = message .. "\t" .. tostring(arg)
        end

        error(message)
    end,

    --#endregion
}
