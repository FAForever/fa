--*****************************************************************************
--* File: lua/modules/ui/lobby/autolobby.lua
--* Author: Sam Demulling
--* Summary: Autolaunching games from GPGNet.  This is intentionally designed
--* to have no user options as GPGNet is setting them for the player.
--*
--* Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************
--* FAF notes:
--* Automatch games are configured by the lobby server by sending parameters
--* to the FAF client which then relays that configuration to autolobby.lua
--* through command line arguments.
--*****************************************************************************

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

---@type UIAutolobbyCommunications | false
local AutolobbyCommunicationsInstance = false

--- Responsible for the behavior of the automated lobby.
---@class UIAutolobbyCommunications : moho.lobby_methods, DebugComponent
---@field Trash TrashBag
---@field InterfaceTrash TrashBag
---@field LocalID UILobbyPlayerId                           # a number that is stringified
---@field LocalPlayerName string                            # nickname
---@field LocalConnectedTo table<UILobbyPlayerId, boolean>                              # list of other player identifiers that we're connected to
---@field OthersConnectedTo table<UILobbyPlayerId, table<UILobbyPlayerId, boolean>>     # list of list ofother player identifiers that other players are connected to
---@field HostID UILobbyPlayerId
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
        self.ConnectedTo = {}
        self.OthersConnectedTo = {}
        self.HostID = "-1"

        self.GameOptions = self:CreateLocalGameOptions()
        self.PlayerOptions = {}
    end,

    ---@param self UIAutolobbyCommunications
    __init_post = function(self)

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

    --- A thread to indicate that we're still around. Various properties such as ping are not updated
    --- until a message is received. This thread introduces occasional traffic between players.
    ---@param self UIAutolobbyCommunications
    IsAliveThread = function(self)
        while not IsDestroyed(self) do
            self:BroadcastData({ Type = "IsAlive" })
            WaitSeconds(1.0)
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


    EjectPeer = function(self, uid, reason)
        self:DebugSpew("EjectPeer", uid, reason)
        return MohoLobbyMethods.EjectPeer(self, uid, reason)
    end,

    GetLocalPlayerID = function(self)
        self:DebugSpew("GetLocalPlayerID")
        return MohoLobbyMethods.GetLocalPlayerID(self)
    end,

    GetLocalPlayerName = function(self)
        self:DebugSpew("GetLocalPlayerName")
        return MohoLobbyMethods.GetLocalPlayerName(self)
    end,

    GetLocalPort = function(self)
        self:DebugSpew("GetLocalPort")
        return MohoLobbyMethods.GetLocalPort(self)
    end,

    GetPeer = function(self, uid)
        self:DebugSpew("GetPeer", uid)
        return MohoLobbyMethods.GetPeer(self, uid)
    end,

    GetPeers = function(self)
        self:DebugSpew("GetPeers")
        return MohoLobbyMethods.GetPeers(self)
    end,

    HostGame = function(self)
        self:DebugSpew("HostGame")
        return MohoLobbyMethods.HostGame(self)
    end,

    IsHost = function(self)
        self:DebugSpew("IsHost")
        return MohoLobbyMethods.IsHost(self)
    end,

    JoinGame = function(self, address, remotePlayerName, remotePlayerUID)
        self:DebugSpew("JoinGame", address, remotePlayerName, remotePlayerUID)
        return MohoLobbyMethods.JoinGame(self, address, remotePlayerName, remotePlayerUID)
    end,

    LaunchGame = function(self, gameConfig)
        self:DebugSpew("LaunchGame", gameConfig)
        return MohoLobbyMethods.LaunchGame(self, gameConfig)
    end,

    MakeValidGameName = function(self, name)

        self:DebugSpew("MakeValidGameName", name)
        return MohoLobbyMethods.MakeValidGameName(self, name)
    end,

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

        -- occasionally send data over the network to create pings on screen
        self.Trash:Add(ForkThread(self.IsAliveThread, self))

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

        -- occasionally send data over the network to create pings on screen
        self.Trash:Add(ForkThread(self.IsAliveThread, self))
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
    end,

    --- Called by the engine when the launch failed.
    ---@param self UIAutolobbyCommunications
    ---@param reasonKey string
    LaunchFailed = function(self, reasonKey)
        self:DebugSpew("LaunchFailed", reasonKey)
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

--- Creates the lobby communications, called (indirectly) by the engine.
---@param protocol any
---@param localPort any
---@param desiredPlayerName any
---@param localPlayerUID any
---@param natTraversalProvider any
function CreateLobby(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)
    LOG("CreateLobby", protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)

    local maxConnections = 16
    AutolobbyCommunicationsInstance = InternalCreateLobby(
        AutolobbyCommunications,
        protocol, localPort, maxConnections, desiredPlayerName,
        localPlayerUID, natTraversalProvider
    )

    -- create the singleton for the interface
    import("/lua/ui/lobby/autolobby/AutolobbyInterface.lua").GetSingleton()
end

--- Instantiates a lobby instance by hosting one.
---
--- Assumes that the lobby communications to be initialized by calling `CreateLobby`.
---@param gameName any
---@param scenarioFileName any
---@param singlePlayer any
function HostGame(gameName, scenarioFileName, singlePlayer)
    LOG("HostGame", gameName, scenarioFileName, singlePlayer)

    if AutolobbyCommunicationsInstance then
        AutolobbyCommunicationsInstance.GameOptions.ScenarioFile = string.gsub(scenarioFileName,
            ".v%d%d%d%d_scenario.lua",
            "_scenario.lua")
        AutolobbyCommunicationsInstance:HostGame()
    end

    -- start with a loading dialog
    import("/lua/ui/lobby/autolobby/AutolobbyInterface.lua").GetSingleton()
        :CreateLoadingDialog()
end

--- Joins an instantiated lobby instance.
---
--- Assumes that the lobby communications to be initialized by calling `CreateLobby`.
---@param address any
---@param asObserver any
---@param playerName any
---@param uid any
function JoinGame(address, asObserver, playerName, uid)
    LOG("JoinGame", address, asObserver, playerName, uid)

    if AutolobbyCommunicationsInstance then
        AutolobbyCommunicationsInstance:JoinGame(address, playerName, uid)
    end

    -- start with a loading dialog
    import("/lua/ui/lobby/autolobby/AutolobbyInterface.lua").GetSingleton()
        :CreateLoadingDialog()
end

--- Called by the engine.
---@param addressAndPort any
---@param name any
---@param uid any
function ConnectToPeer(addressAndPort, name, uid)
    LOG("ConnectToPeer", addressAndPort, name, uid)

    if AutolobbyCommunicationsInstance then
        AutolobbyCommunicationsInstance:ConnectToPeer(addressAndPort, name, uid)
    end
end

--- Called by the engine.
---@param uid any
---@param doNotUpdateView any
function DisconnectFromPeer(uid, doNotUpdateView)
    LOG("DisconnectFromPeer", uid, doNotUpdateView)

    if AutolobbyCommunicationsInstance then
        AutolobbyCommunicationsInstance:DisconnectFromPeer(uid)
    end
end
