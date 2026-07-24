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

-- The `moho.lobby_methods` object the engine instantiates (via `InternalCreateLobby`
-- in autolobby.lua) and whose callbacks it calls. It is a thin shell:
--
-- - Engine-ABI wrappers (BroadcastData / SendData / ConnectToPeer / ...) stay here
--   because they override `moho` methods and add validation / debug spew.
-- - Command-line / engine-coupled creators (CreateLocalPlayer / CreateLocalGameOptions)
--   stay here because they lean on the mixed-in argument component.
-- - Callbacks that carry real behaviour forward to `AutolobbyController`, passing
--   `self`. That keeps the logic in a hot-reloadable, testable free-function module.
--
-- This object does NOT hot-reload — the live C object keeps its bound methods and
-- threads across a reload of this file, so edits here only take effect on the next
-- `CreateLobby`. Keep it thin; put behaviour in the controller.

local GameColors = import("/lua/gamecolors.lua")

local MohoLobbyMethods = moho.lobby_methods
local DebugComponent = import("/lua/shared/components/debugcomponent.lua").DebugComponent
local AutolobbyServerCommunicationsComponent = import("/lua/ui/lobby/autolobby/components/autolobbyservercommunicationscomponent.lua")
    .AutolobbyServerCommunicationsComponent

local AutolobbyArgumentsComponent = import("/lua/ui/lobby/autolobby/components/autolobbyarguments.lua").AutolobbyArgumentsComponent

local AutolobbyMessages = import("/lua/ui/lobby/autolobby/autolobbymessages.lua").AutolobbyMessages

local AutolobbyModel = import("/lua/ui/lobby/autolobby/autolobbymodel.lua")
local AutolobbyController = import("/lua/ui/lobby/autolobby/autolobbycontroller.lua")

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

--- The engine's lobby object. Owns the engine ABI; forwards behaviour to
--- `AutolobbyController`. The synced state lives in `AutolobbyModel`; the fields
--- kept here are controller-internal (identity + rejoin parameters).
---@class UIAutolobbyInstance : moho.lobby_methods, DebugComponent, UIAutolobbyServerCommunicationsComponent, UIAutolobbyArgumentsComponent
---@field Trash TrashBag
---@field LocalPlayerName string                            # nickname
---@field HostID UILobbyPeerId
---@field LobbyParameters? UIAutolobbyParameters                # Used for rejoining functionality
---@field HostParameters? UIAutolobbyHostParameters             # Used for rejoining functionality
---@field JoinParameters? UIAutolobbyJoinParameters             # Used for rejoining functionality
AutolobbyInstance = Class(MohoLobbyMethods, AutolobbyServerCommunicationsComponent, AutolobbyArgumentsComponent, DebugComponent) {

    ---@param self UIAutolobbyInstance
    __init = function(self)
        self.Trash = TrashBag()

        self.LocalPlayerName = "Charlie"
        self.HostID = "-2"

        -- The model singleton is created in `autolobby.lua > CreateLobby`
        -- before the lobby (and thus this instance) is instantiated. Seed
        -- the initial state here.
        local model = AutolobbyModel.GetSingleton()
        model.LocalPeerId:Set("-2")
        model.GameMods:Set({})
        model.GameOptions:Set(self:CreateLocalGameOptions())
        model.PlayerOptions:Set({})
        model.LaunchStatutes:Set({})
        model.ConnectionMatrix:Set({})
    end,

    ---@param self UIAutolobbyInstance
    __post_init = function(self)

    end,

    --- Creates a table that represents the local player settings. This represents the initial player. It can be edited by the host accordingly.
    ---@param self UIAutolobbyInstance
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
    ---@param self UIAutolobbyInstance
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
            TeamShareOverflow = "enabled",

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
    --#region Engine interface

    --- Broadcasts data to all (connected) peers.
    ---@param self UIAutolobbyInstance
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
    ---@param self UIAutolobbyInstance
    ---@return nil
    DebugDump = function(self)
        self:DebugSpew("DebugDump")
        return MohoLobbyMethods.DebugDump(self)
    end,

    --- Destroys the C-object and all the (UI) entities in the trash bag.
    ---@param self UIAutolobbyInstance
    ---@return nil
    Destroy = function(self)
        self:DebugSpew("Destroy")

        self.Trash:Destroy()
        return MohoLobbyMethods.Destroy(self)
    end,

    --- Disconnects from a peer.
    --- See also `ConnectToPeer` to connect
    ---@param self UIAutolobbyInstance
    ---@param peerId UILobbyPeerId
    ---@return nil
    DisconnectFromPeer = function(self, peerId)
        self:DebugSpew("DisconnectFromPeer", peerId)

        return MohoLobbyMethods.DisconnectFromPeer(self, peerId)
    end,

    --- Ejects a peer from the lobby.
    ---@param self UIAutolobbyInstance
    ---@param peerId UILobbyPeerId
    ---@param reason string
    ---@return nil
    EjectPeer = function(self, peerId, reason)
        self:DebugSpew("EjectPeer", peerId, reason)
        return MohoLobbyMethods.EjectPeer(self, peerId, reason)
    end,

    --- Retrieves the local identifier.
    ---@param self UIAutolobbyInstance
    ---@return UILobbyPeerId
    GetLocalPlayerID = function(self)
        self:DebugSpew("GetLocalPlayerID")
        return MohoLobbyMethods.GetLocalPlayerID(self)
    end,

    --- Retrieves the local name. Note that this name can be overwritten by the host via `MakeValidPlayerName`
    ---@param self UIAutolobbyInstance
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
    ---@param self UIAutolobbyInstance
    ---@param peerId UILobbyPeerId
    ---@return Peer
    GetPeer = function(self, peerId)
        self:DebugSpew("GetPeer", peerId)
        return MohoLobbyMethods.GetPeer(self, peerId)
    end,

    --- Retrieves information about all connected peers. See `GetPeer` to get information for a specific peer.
    ---@param self UIAutolobbyInstance
    GetPeers = function(self)
        -- self:DebugSpew("GetPeers")
        return MohoLobbyMethods.GetPeers(self)
    end,

    --- Transforms the lobby to be discoveryable and joinable for other players.
    ---@param self UIAutolobbyInstance
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
    ---@param self UIAutolobbyInstance
    ---@param address GPGNetAddress
    ---@param remotePlayerName string
    ---@param remotePlayerPeerId UILobbyPeerId
    ---@return nil
    JoinGame = function(self, address, remotePlayerName, remotePlayerPeerId)
        self:DebugSpew("JoinGame", address, remotePlayerName, remotePlayerPeerId)
        return MohoLobbyMethods.JoinGame(self, address, remotePlayerName, remotePlayerPeerId)
    end,

    --- Launches the game for the local client. The game configuration that is passed in should originate from the host.
    ---@param self UIAutolobbyInstance
    ---@param gameConfig UILobbyLaunchConfiguration
    ---@return nil
    LaunchGame = function(self, gameConfig)
        self:DebugSpew("LaunchGame")
        self:DebugSpew(reprs(gameConfig, { depth = 10 }))

        return MohoLobbyMethods.LaunchGame(self, gameConfig)
    end,

    --- Returns a valid game name.
    ---@param self UIAutolobbyInstance
    ---@param name string
    ---@return string
    MakeValidGameName = function(self, name)

        self:DebugSpew("MakeValidGameName", name)
        return MohoLobbyMethods.MakeValidGameName(self, name)
    end,

    --- Returns a valid player name.
    ---@param self UIAutolobbyInstance
    ---@param peerId UILobbyPeerId
    ---@param name string
    ---@return string
    MakeValidPlayerName = function(self, peerId, name)
        self:DebugSpew("MakeValidPlayerName", peerId, name)
        return MohoLobbyMethods.MakeValidPlayerName(self, peerId, name)
    end,

    ---@param self UIAutolobbyInstance
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
    --
    -- Callbacks with real behaviour forward to `AutolobbyController`; the
    -- trivial ones (just a server status update) stay inline.

    --- Called by the engine as we're trying to host a lobby.
    ---@param self UIAutolobbyInstance
    Hosting = function(self)
        self:DebugSpew("Hosting")
        AutolobbyController.OnHosting(self)
    end,

    --- Called by the engine as we're trying to join a lobby.
    ---@param self UIAutolobbyInstance
    Connecting = function(self)
        self:DebugSpew("Connecting")
        self:SendLaunchStatusToServer('Connecting')
    end,

    --- Called by the engine when the connection fails.
    ---@param self UIAutolobbyInstance
    ---@param reason string     # reason for connection failure, populated by the engine
    ConnectionFailed = function(self, reason)
        self:DebugSpew("ConnectionFailed", reason)
        AutolobbyController.OnConnectionFailed(self)
    end,

    --- Called by the engine when the connection succeeds with the host.
    ---@param self UIAutolobbyInstance
    ---@param localPeerId UILobbyPeerId
    ---@param newLocalName string
    ---@param hostPeerId string
    ConnectionToHostEstablished = function(self, localPeerId, newLocalName, hostPeerId)
        self:DebugSpew("ConnectionToHostEstablished", localPeerId, newLocalName, hostPeerId)
        AutolobbyController.OnConnectionToHostEstablished(self, localPeerId, newLocalName, hostPeerId)
    end,

    --- Called by the engine when a peer establishes a connection.
    ---@param self UIAutolobbyInstance
    ---@param peerId UILobbyPeerId
    ---@param peerConnectedTo UILobbyPeerId[]    # all established conenctions for the given player
    EstablishedPeers = function(self, peerId, peerConnectedTo)
        self:DebugSpew("EstablishedPeers", peerId, reprs(peerConnectedTo))
        AutolobbyController.OnEstablishedPeers(self, peerId, peerConnectedTo)
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Lobby events

    --- Called by the engine when you are ejected from a lobby.
    ---@param self UIAutolobbyInstance
    ---@param reason string     # reason for disconnection, populated by the host
    Ejected = function(self, reason)
        self:DebugSpew("Ejected", reason)
        self:SendLaunchStatusToServer('Ejected')
    end,

    --- ???
    ---@param self UIAutolobbyInstance
    ---@param text string
    SystemMessage = function(self, text)
        self:DebugSpew("SystemMessage", text)
    end,

    --- Called by the engine when we receive data from other players. There is no checking to see if the data is legitimate, these need to be done in Lua.
    ---
    --- Data can be send via `BroadcastData` and/or `SendData`.
    ---@param self UIAutolobbyInstance
    ---@param data UILobbyReceivedMessage
    DataReceived = function(self, data)
        -- make it more convenient to debug malicious traffic
        SPEW(string.format("Received data of type %s from %s (%s)", tostring(data.Type), tostring(data.SenderID), tostring(data.SenderName)))

        -- signal UI that we received something; a fresh stamp table fires the
        -- view's IsAlive observer even for repeated pulses from the same peer
        local model = AutolobbyModel.GetSingleton()
        local peerIndex = AutolobbyModel.PeerIdToIndex(model.PlayerOptions(), data.SenderID)
        if peerIndex then
            model.IsAliveStamp:Set({ Index = peerIndex, Time = GetSystemTimeSeconds() })
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

        -- handle the message (the handler routes to `AutolobbyController`)
        message.Handler(self, data)
    end,

    --- Called by the engine when the game configuration is requested by the discovery service.
    ---@param self UIAutolobbyInstance
    GameConfigRequested = function(self)
        self:DebugSpew("GameConfigRequested")
    end,

    --- Called by the engine when a peer disconnects.
    ---@param self UIAutolobbyInstance
    ---@param peerName string
    ---@param peerId UILobbyPeerId
    PeerDisconnected = function(self, peerName, peerId)
        self:DebugSpew("PeerDisconnected", peerName, peerId)
        self:SendDisconnectedPeer(peerId)
    end,

    --- Called by the engine when the game is launched.
    ---@param self UIAutolobbyInstance
    GameLaunched = function(self)
        self:DebugSpew("GameLaunched")

        -- clear out the interface
        import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton():Destroy()

        -- destroy ourselves, the game takes over the management of peers
        self:Destroy()

        self:SendGameStateToServer('Launching')
    end,

    --- Called by the engine when the launch failed.
    ---@param self UIAutolobbyInstance
    ---@param reasonKey string
    LaunchFailed = function(self, reasonKey)
        self:DebugSpew("LaunchFailed", LOC(reasonKey))
        self:SendLaunchStatusToServer('Failed')
    end,

    --#endregion

    --#region Debugging

    ---@param self UIAutolobbyInstance
    ---@param ... any
    DebugSpew = function(self, ...)
        if not self.EnabledSpewing then
            return
        end

        SPEW("Autolobby instance", unpack(arg))
    end,


    ---@param self UIAutolobbyInstance
    ---@param ... any
    DebugLog = function(self, ...)
        if not self.EnabledLogging then
            return
        end

        LOG("Autolobby instance", unpack(arg))
    end,

    ---@param self UIAutolobbyInstance
    ---@param ... any
    DebugWarn = function(self, ...)
        if not self.EnabledWarnings then
            return
        end

        WARN("Autolobby instance", unpack(arg))
    end,

    ---@param self UIAutolobbyInstance
    ---@param ... any
    DebugError = function(self, ...)
        if not self.EnabledErrors then
            return
        end

        local message = "Autolobby instance"
        for _, arg in ipairs(arg) do
            message = message .. "\t" .. tostring(arg)
        end

        error(message)
    end,

    --#endregion
}
