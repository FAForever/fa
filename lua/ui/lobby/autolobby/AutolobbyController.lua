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

local GameColors = import("/lua/GameColors.lua")
local MohoLobbyMethods = moho.lobby_methods
local DebugComponent = import("/lua/shared/components/DebugComponent.lua").DebugComponent

local AutolobbyMessages = import("/lua/ui/lobby/autolobby/AutolobbyMessages.lua").AutolobbyMessages

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

---@class UIAutolobbyPlayer: UILobbyLaunchPlayerConfiguration
---@field StartSpot number
---@field DEV number    # Related to rating/divisions
---@field MEAN number   # Related to rating/divisions
---@field NG number     # Related to rating/divisions
---@field DIV string    # Related to rating/divisions
---@field SUBDIV string # Related to rating/divisions
---@field PL number     # Related to rating/divisions

---@alias UIAutolobbyConnections boolean[][]
---@alias UIAutolobbyStatus UIPeerStatus[]

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
---@class UIAutolobbyCommunications : moho.lobby_methods, DebugComponent
---@field Trash TrashBag
---@field LocalID UILobbyPeerId                             # a number that is stringified
---@field LocalPlayerName string                            # nickname
---@field HostID UILobbyPeerId
---@field PlayerCount number
---@field GameMods UILobbyLaunchGameModsConfiguration[]
---@field GameOptions UILobbyLaunchGameOptionsConfiguration     # Is synced from the host to the others.
---@field PlayerOptions UIAutolobbyPlayer[]                     # Is synced from the host to the others.
---@field PeerToIndexMapping table<UILobbyPeerId, number>
---@field DisconnectedPeers table<UILobbyPeerId, number>        #
---@field LobbyParameters? UIAutolobbyParameters                # Used for rejoining functionality
---@field HostParameters? UIAutolobbyHostParameters             # Used for rejoining functionality
---@field JoinParameters? UIAutolobbyJoinParameters             # Used for rejoining functionality
AutolobbyCommunications = Class(MohoLobbyMethods, DebugComponent) {

    BackgroundTextures = {
        "/menus02/background-paint01_bmp.dds",
        "/menus02/background-paint02_bmp.dds",
        "/menus02/background-paint03_bmp.dds",
        "/menus02/background-paint04_bmp.dds",
        "/menus02/background-paint05_bmp.dds",
    },

    ---@param self UIAutolobbyCommunications
    __init = function(self)
        self.Trash = TrashBag()

        self.LocalID = "-2"
        self.LocalPlayerName = "Charlie"
        self.PlayerCount = tonumber(GetCommandLineArg("/players", 1)[1]) or 2
        self.Connections = {}
        self.HostID = "-2"

        self.GameMods = {}
        self.GameOptions = self:CreateLocalGameOptions()
        self.PlayerOptions = {}
        self.PeerToIndexMapping = {}
        self.DisconnectedPeers = {}
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
        info.Team = tonumber(GetCommandLineArg("/team", 1)[1])
        info.StartSpot = tonumber(GetCommandLineArg("/startspot", 1)[1])

        -- determine army color based on start location
        info.PlayerColor = GameColors.MapToWarmCold(info.StartSpot)
        info.ArmyColor = GameColors.MapToWarmCold(info.StartSpot)

        -- retrieve rating
        info.DEV = tonumber(GetCommandLineArg("/deviation", 1)[1]) or 500
        info.MEAN = tonumber(GetCommandLineArg("/mean", 1)[1]) or 1500
        info.NG = tonumber(GetCommandLineArg("/numgames", 1)[1]) or 0
        info.DIV = (GetCommandLineArg("/division", 1)[1]) or ""
        info.SUBDIV = (GetCommandLineArg("/subdivision", 1)[1]) or ""
        info.PL = math.floor(info.MEAN - 3 * info.DEV)

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

            -- yep, great
            Ranked = true,
            Unranked = 'No',
        }

        -- process game options from the command line
        for name, value in Utils.GetCommandLineArgTable("/gameoptions") do
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
    ---@param peers Peer[]
    ---@return UIAutolobbyConnections
    CreateConnectionsMatrix = function(self, peers)
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
        for _, peer in peers do
            for _, peerConnectedToId in peer.establishedPeers do
                local peerIdNumber = self:PeerIdToIndex(peer.id)
                local peerConnectedToIdNumber = self:PeerIdToIndex(peerConnectedToId)

                -- connection works both ways
                if peerIdNumber and peerConnectedToIdNumber then
                    connections[peerIdNumber][peerConnectedToIdNumber] = true
                    connections[peerConnectedToIdNumber][peerIdNumber] = true
                end
            end
        end

        return connections
    end,

    ---@param self UIAutolobbyCommunications
    ---@param peers Peer[]
    ---@return UIPeerStatus[]
    CreateConnectionStatuses = function(self, peers)
        local statuses = {}
        for k = 1, self.PlayerCount do
            statuses[k] = 'None'
        end

        for _, peer in peers do
            local peerIdNumber = self:PeerIdToIndex(peer.id)
            if peerIdNumber then
                statuses[peerIdNumber] = peer.status
            end
        end

        return statuses
    end,

    --- Maps a peer id to an index that can be used in the interface. In
    --- practice the peer id can be all over the place, ranging from -1
    --- to numbers such as 35240. With this function we map it to a sane
    --- index that we can use in the interface.
    ---@param self UIAutolobbyCommunications
    ---@param peerId UILobbyPeerId
    ---@return number | false
    PeerIdToIndex = function(self, peerId)
        if type(peerId) ~= 'string' then
            self:DebugWarn("Invalid peer id", peerId)
            return false
        end

        -- happens when a peer disconnected from us, but not (yet) to other players
        if self.DisconnectedPeers[peerId] then
            return false
        end

        -- happens before the connection is established
        if peerId == "-1" then
            -- just return some index, but do not store it
            return table.getsize(self.PeerToIndexMapping) + 1
        end

        local index = self.PeerToIndexMapping[peerId]
        if not index then
            index = table.getsize(self.PeerToIndexMapping) + 1
            self.PeerToIndexMapping[peerId] = index
        end

        return index
    end,

    ---@param self UIAutolobbyCommunications
    ---@param gameOptions UILobbyLaunchGameOptionsConfiguration
    ---@param gameMods UILobbyLaunchGameModsConfiguration[]
    Prefetch = function(self, gameOptions, gameMods)
        local scenarioPath = gameOptions.ScenarioFile
        if not scenarioPath then
            return
        end

        local scenarioFile = MapUtil.LoadScenario(gameOptions.ScenarioFile)
        PrefetchSession(scenarioFile.map, gameMods, true)
    end,

    ---@param self UIAutolobbyCommunications
    ---@param lobbyParameters UIAutolobbyParameters
    ---@param joinParameters UIAutolobbyJoinParameters
    RejoinThread = function(self, lobbyParameters, joinParameters)
        local autolobbyModule = import("/lua/ui/lobby/autolobby.lua")

        WaitSeconds(2.0)

        self:Destroy()
        local newLobby = autolobbyModule.CreateLobby(
            lobbyParameters.Protocol,
            lobbyParameters.LocalPort,
            lobbyParameters.DesiredPlayerName,
            lobbyParameters.LocalPlayerPeerId,
            lobbyParameters.NatTraversalProvider
        )

        autolobbyModule.JoinGame(joinParameters.Address, joinParameters.AsObserver, joinParameters.DesiredPlayerName, joinParameters.DesiredPeerId)
    end,

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
        self:BroadcastData({ Type = "UpdatePlayerOptions", GameOptions = self.PlayerOptions })
    end,

    ---@param self UIAutolobbyCommunications
    ---@param data UIAutolobbyUpdatePlayerOptionsMessage
    ProcessUpdatePlayerOptionsMessage = function(self, data)
        self.PlayerOptions = data.PlayerOptions

        -- update UI for player options
        import("/lua/ui/lobby/autolobby/AutolobbyInterface.lua").GetSingleton()
            :UpdatePlayerOptions(self.PlayerOptions)
    end,

    ---@param self UIAutolobbyCommunications
    ---@param data UIAutolobbyUpdateGameOptionsMessage
    ProcessUpdateGameOptionsMessage = function(self, data)
        self.GameOptions = data.GameOptions

        self:Prefetch(self.GameOptions, self.GameMods)

        -- update UI for game options
        import("/lua/ui/lobby/autolobby/AutolobbyInterface.lua").GetSingleton()
            :UpdateGameOptions(self.GameOptions)
    end,

    ---@param self UIAutolobbyCommunications
    ---@param data UIAutolobbyLaunchMessage
    ProcessLaunchMessage = function(self, data)
        self:LaunchGame(data.GameConfig)
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Threads

    --- A thread to indicate that we're still around. Various properties such as ping are not updated
    --- until a message is received. This thread introduces occasional traffic between players.
    ---@param self UIAutolobbyCommunications
    IsAliveThread = function(self)
        while not IsDestroyed(self) do
            self:BroadcastData({ Type = "IsAlive" })
            WaitSeconds(0.5)
        end
    end,

    ---@param self any
    ---@param peers any
    ---@return boolean
    CheckForLaunch = function(self, peers)

        -- for debugging :)
        do return false end

        -- true iff we are connected to all peers
        local peers = self:GetPeers()



        -- check number of peers
        if table.getsize(peers) ~= self.PlayerCount - 1 then
            return false
        end

        -- check connection status
        for k, peer in peers do
            if peer.status ~= "Established" then
                return false
            end
        end

        -- check confirmed established connections of peers
        for _, peer in peers do
            if table.getsize(peer.establishedPeers) ~= self.PlayerCount - 1 then
                return false
            end
        end

        return true
    end,

    ---@param self UIAutolobbyCommunications
    CheckForLaunchThread = function(self)

        while not IsDestroyed(self) do

            local peers = self:GetPeers()
            local canLaunch = self:CheckForLaunch(peers)

            LOG("CanLaunch", canLaunch)
            if canLaunch then
                ---@type UILobbyLaunchConfiguration
                local gameConfiguration = {
                    GameMods = self.GameMods,
                    GameOptions = self.GameOptions,
                    PlayerOptions = self.PlayerOptions,
                    Observers = {},
                }

                -- delay slightly
                WaitSeconds(5)

                -- check again and if still good, we launch
                local peers = self:GetPeers()
                if self:CheckForLaunch(peers) then
                    self:BroadcastData({ Type = "Launch", GameConfig = gameConfiguration })
                    self:LaunchGame(gameConfiguration)
                end
            end

            WaitSeconds(5.0)
        end
    end,

    ---@param self UIAutolobbyCommunications
    ConnectionMatrixThread = function(self)
        -- right at the start it can be a little jumpy, so we wait a second
        WaitSeconds(1)

        while not IsDestroyed(self) do
            local peers = self:GetPeers()

            local connections = self:CreateConnectionsMatrix(peers)
            local statuses = self:CreateConnectionStatuses(peers)

            import("/lua/ui/lobby/autolobby/AutolobbyInterface.lua").GetSingleton()
                :UpdateConnections(connections)

            import("/lua/ui/lobby/autolobby/AutolobbyInterface.lua").GetSingleton()
                :UpdateConnectionStatuses(statuses)

            WaitFrames(10)
        end
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Engine interface

    --- Broadcasts data to all (connected) peers.
    ---@param self UIAutolobbyCommunications
    ---@param data UILobbyData
    BroadcastData = function(self, data)
        self:DebugSpew("BroadcastData", data.Type)
        if not AutolobbyMessages[data.Type] then
            self:DebugWarn("Broadcasting unknown message type", data.Type)
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

        -- inform the server of the event
        GpgNetSendDisconnected(peerId)

        -- reset mapping
        self.PeerToIndexMapping = {}
        self.DisconnectedPeers[peerId] = GetSystemTimeSeconds()

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
        GpgNetSendGameState('Launching')
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
        if not AutolobbyMessages[data.Type] then
            self:DebugWarn("Sending unknown message type", data.Type, "to", peerId)
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

        self.LocalID = self:GetLocalPlayerID()
        self.LocalPlayerName = self:GetLocalPlayerName()
        self.HostID = self:GetLocalPlayerID()

        -- give ourself a seat at the table
        local hostPlayerOptions = self:CreateLocalPlayer()
        hostPlayerOptions.OwnerID = self.LocalID
        hostPlayerOptions.PlayerName = self:MakeValidPlayerName(self.LocalID, self.LocalPlayerName)
        self.PlayerOptions[hostPlayerOptions.StartSpot] = hostPlayerOptions

        -- occasionally send data over the network to create pings on screen
        self.Trash:Add(ForkThread(self.IsAliveThread, self))
        self.Trash:Add(ForkThread(self.ConnectionMatrixThread, self))
        self.Trash:Add(ForkThread(self.CheckForLaunchThread, self))

        -- start prefetching the scenario
        self:Prefetch(self.GameOptions, self.GameMods)

        GpgNetSendGameState('Lobby')

        -- update UI for game options
        import("/lua/ui/lobby/autolobby/AutolobbyInterface.lua").GetSingleton()
            :UpdateGameOptions(self.GameOptions)
    end,

    --- Called by the engine as we're trying to join a lobby.
    ---@param self UIAutolobbyCommunications
    Connecting = function(self)
        self:DebugSpew("Connecting")
    end,

    --- Called by the engine when the connection fails.
    ---@param self UIAutolobbyCommunications
    ---@param reason string     # reason for connection failure, populated by the engine
    ConnectionFailed = function(self, reason)
        self:DebugSpew("ConnectionFailed", reason)
    end,

    --- Called by the engine when the connection succeeds with the host.
    ---@param self UIAutolobbyCommunications
    ---@param localPeerId UILobbyPeerId
    ---@param hostPeerId string
    ConnectionToHostEstablished = function(self, localPeerId, newLocalName, hostPeerId)
        self:DebugSpew("ConnectionToHostEstablished", localPeerId, newLocalName, hostPeerId)
        self.LocalPlayerName = newLocalName
        self.LocalID = localPeerId
        self.HostID = hostPeerId

        GpgNetSendGameState('Lobby')

        -- occasionally send data over the network to create pings on screen
        self.Trash:Add(ForkThread(self.IsAliveThread, self))
        self.Trash:Add(ForkThread(self.ConnectionMatrixThread, self))

        self:SendData(self.HostID, { Type = "AddPlayer", PlayerOptions = self:CreateLocalPlayer() })
    end,

    --- Called by the engine when a peer establishes a connection.
    ---@param self UIAutolobbyCommunications
    ---@param peerId UILobbyPeerId
    ---@param peerConnectedTo UILobbyPeerId[]    # all established conenctions for the given player
    EstablishedPeers = function(self, peerId, peerConnectedTo)
        self:DebugSpew("EstablishedPeers", peerId, reprs(peerConnectedTo))
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Lobby events

    --- Called by the engine when you are ejected from a lobby.
    ---@param self UIAutolobbyCommunications
    ---@param reason string     # reason for disconnection, populated by the host
    Ejected = function(self, reason)
        self:DebugSpew("Ejected", reason)
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

        ---@type UIAutolobbyMessageHandler?
        local messageType = AutolobbyMessages[data.Type]

        -- signal UI that we received something
        local peerIndex = self:PeerIdToIndex(data.SenderID)
        if peerIndex then
            import("/lua/ui/lobby/autolobby/AutolobbyInterface.lua").GetSingleton()
                :UpdateIsAliveStamp(peerIndex)
        end

        -- verify that the message type exists
        if not messageType then
            self:DebugError('Unknown message received: ', data.Type)
            return
        end

        -- verify that we can accept it
        if not messageType.Accept(self, data) then
            self:DebugWarn("Message rejected: ", data.Type)
            return
        end

        -- handle the message
        messageType.Handler(self, data)
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

        -- reset mapping
        self.PeerToIndexMapping = {}
        self.DisconnectedPeers[peerId] = GetSystemTimeSeconds()
    end,

    --- Called by the engine when the game is launched.
    ---@param self UIAutolobbyCommunications
    GameLaunched = function(self)
        self:DebugSpew("GameLaunched")

        -- clear out the interface
        import("/lua/ui/lobby/autolobby/AutolobbyInterface.lua").GetSingleton():Destroy()

        -- destroy ourselves, the game takes over the management of peers
        self:Destroy()

        GpgNetSend('GameState', 'Launching')
    end,

    --- Called by the engine when the launch failed.
    ---@param self UIAutolobbyCommunications
    ---@param reasonKey string
    LaunchFailed = function(self, reasonKey)
        self:DebugSpew("LaunchFailed", LOC(reasonKey))
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