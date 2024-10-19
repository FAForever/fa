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

local MohoLobbyMethods = moho.lobby_methods
local DebugComponent = import("/lua/shared/components/DebugComponent.lua").DebugComponent

local AutolobbyMessageHandlers = import("/lua/ui/lobby/autolobby/AutolobbyMessageHandlers.lua").AutolobbyMessageHandlers

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


--- Responsible for the behavior of the automated lobby.
---@class UIAutolobbyCommunications : moho.lobby_methods, DebugComponent
---@field Trash TrashBag
---@field InterfaceTrash TrashBag
---@field LocalID UILobbyPlayerId                           # a number that is stringified
---@field LocalPlayerName string                            # nickname
---@field HostID UILobbyPlayerId
---@field PlayerCount number
---@field GameOptions UILobbyLaunchGameOptionsConfiguration     # Is synced from the host to the others.
---@field PlayerOptions UIAutolobbyPlayer[]                     # Is synced from the host to the others.
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
        self.InterfaceTrash = self.Trash:Add(TrashBag())

        self.LocalID = "-1"
        self.LocalPlayerName = "Charlie"
        self.PlayerCount = tonumber(GetCommandLineArg("/players", 1)[1]) or 2
        self.Connections = {}
        self.HostID = "-1"

        self.GameOptions = self:CreateLocalGameOptions()
        self.PlayerOptions = {}
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

        info.Team = 1
        info.PlayerColor = 1
        info.ArmyColor = 1
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
        info.StartSpot = tonumber(GetCommandLineArg("/startspot", 1)[1]) or false

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
            local peerIdNumber = tonumber(peer.id) + 1
            for _, peerConnectedToId in peer.establishedPeers do
                local peerConnectedToIdNumber = tonumber(peerConnectedToId) + 1

                -- connection works both ways
                connections[peerIdNumber][peerConnectedToIdNumber] = true
                connections[peerConnectedToIdNumber][peerIdNumber] = true
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
            local peerIdNumber = tonumber(peer.id) + 1
            statuses[peerIdNumber] = peer.status
        end

        return statuses
    end,

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
        -- true iff we are connected to all peers
        local peers = self:GetPeers()
        local allLocalConnected = table.getsize(peers) == self.PlayerCount - 1

        if not allLocalConnected then
            return false
        end

        -- true iff all peers are connected to every of their peers
        for _, peer in peers do
            if not table.getsize(peer.establishedPeers) == self.PlayerCount - 1 then
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

            if canLaunch then
                ---@type UILobbyLaunchConfiguration
                local gameConfiguration = {
                    GameMods = {},
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
        while not IsDestroyed(self) do
            local peers = self:GetPeers()

            local connections = self:CreateConnectionsMatrix(peers)
            local statuses = self:CreateConnectionStatuses(peers)

            import("/lua/ui/lobby/autolobby/AutolobbyInterface.lua").GetSingleton()
                :UpdateConnections(connections)

            import("/lua/ui/lobby/autolobby/AutolobbyInterface.lua").GetSingleton()
                :UpdateConnectionStatuses(statuses)

            WaitFrames(1)
        end
    end,

    ---------------------------------------------------------------------------
    --#region Engine interface

    --- Broadcasts data to all (connected) peers.
    ---@param self UIAutolobbyCommunications
    ---@param data UILobbyData
    BroadcastData = function(self, data)
        self:DebugSpew("BroadcastData", data.Type)
        if not AutolobbyMessageHandlers[data.Type] then
            self:DebugWarn("Broadcasting unknown message type", data.Type)
        end

        return MohoLobbyMethods.BroadcastData(self, data)
    end,

    --- (Re)Connects to a peer.
    ---@param self any
    ---@param address any
    ---@param name any
    ---@param uid any
    ---@return nil
    ConnectToPeer = function(self, address, name, uid)
        self:DebugSpew("ConnectToPeer", address, name, uid)
        return MohoLobbyMethods.ConnectToPeer(self, address, name, uid)
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
    ---@param uid any
    ---@return nil
    DisconnectFromPeer = function(self, uid)
        self:DebugSpew("DisconnectFromPeer", uid)
        return MohoLobbyMethods.DisconnectFromPeer(self, uid)
    end,

    --- Ejects a peer from the lobby.
    ---@param self UIAutolobbyCommunications
    ---@param uid UILobbyPlayerId
    ---@param reason string
    ---@return nil
    EjectPeer = function(self, uid, reason)
        self:DebugSpew("EjectPeer", uid, reason)
        return MohoLobbyMethods.EjectPeer(self, uid, reason)
    end,

    --- Retrieves the local identifier.
    ---@param self UIAutolobbyCommunications
    ---@return UILobbyPlayerId
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
    ---@param uid UILobbyPlayerId
    ---@return Peer
    GetPeer = function(self, uid)
        self:DebugSpew("GetPeer", uid)
        return MohoLobbyMethods.GetPeer(self, uid)
    end,

    --- Retrieves information about all connected peers. See `GetPeer` to get information for a specific peer.
    ---@param self UIAutolobbyCommunications
    GetPeers = function(self)
        self:DebugSpew("GetPeers")
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
    ---@param remotePlayerUID UILobbyPlayerId
    ---@return nil
    JoinGame = function(self, address, remotePlayerName, remotePlayerUID)
        self:DebugSpew("JoinGame", address, remotePlayerName, remotePlayerUID)
        return MohoLobbyMethods.JoinGame(self, address, remotePlayerName, remotePlayerUID)
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
    ---@param uid UILobbyPlayerId
    ---@param name string
    ---@return string
    MakeValidPlayerName = function(self, uid, name)
        self:DebugSpew("MakeValidPlayerName", uid, name)
        return MohoLobbyMethods.MakeValidPlayerName(self, uid, name)
    end,

    ---@param self UIAutolobbyCommunications
    ---@param uid UILobbyPlayerId
    ---@param data UILobbyData
    ---@return nil
    SendData = function(self, uid, data)
        self:DebugSpew("SendData", uid, data.Type)
        if not AutolobbyMessageHandlers[data.Type] then
            self:DebugWarn("Sending unknown message type", data.Type, "to", uid)
        end

        return MohoLobbyMethods.SendData(self, uid, data)
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
        PrefetchSession(self.GameOptions.ScenarioFile, {}, true)

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
    ---@param localId string
    ---@param hostId string
    ConnectionToHostEstablished = function(self, localId, newLocalName, hostId)
        self:DebugSpew("ConnectionToHostEstablished", localId, newLocalName, hostId)
        self.LocalPlayerName = newLocalName
        self.LocalID = localId
        self.HostID = hostId

        GpgNetSendGameState('Lobby')

        -- occasionally send data over the network to create pings on screen
        self.Trash:Add(ForkThread(self.IsAliveThread, self))
        self.Trash:Add(ForkThread(self.ConnectionMatrixThread, self))

        self:SendData(self.HostID, { Type = "AddPlayer", PlayerOptions = self:CreateLocalPlayer() })
    end,

    --- Called by the engine when a peer establishes a connection.
    ---@param self UIAutolobbyCommunications
    ---@param playerId string
    ---@param playerConnectedTo string[]    # all established conenctions for the given player
    EstablishedPeers = function(self, playerId, playerConnectedTo)
        self:DebugSpew("EstablishedPeers", playerId, reprs(playerConnectedTo))
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
        local messageType = AutolobbyMessageHandlers[data.Type]

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
    ---@param otherId string
    PeerDisconnected = function(self, peerName, otherId)
        self:DebugSpew("PeerDisconnected", peerName, otherId)
    end,

    --- Called by the engine when the game is launched.
    ---@param self UIAutolobbyCommunications
    GameLaunched = function(self)
        self:DebugSpew("GameLaunched")

        -- GpgNetSend('GameState', 'Launching')
        self:Destroy()
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

        error("Autolobby communications", unpack(arg))
    end,

    --#endregion
}
