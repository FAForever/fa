-- 
--  Lobby communications and common services
-- 


quietTimeout = 30000.0 -- milliseconds to wait before booting people
maxPlayerSlots = 16
maxConnections = 16 -- count doesn't include ourself.

Strings = {
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

--- @Deprecated
-- Used only by autolobby. Use PlayerData class instead.
function GetDefaultPlayerOptions(playerName)
    return {
        Team = 1,
        PlayerColor = 1,
        ArmyColor = 1,
        StartSpot = 1,
        Ready = false,
        Faction = table.getn(import("/lua/factions.lua").Factions) + 1, -- max faction + 1 tells lobby to pick random faction
        PlayerName = playerName or "player",
        AIPersonality = "",
        Human = true,
        Civilian = false,
    }
end

---@class UILobbyDiscoveryService : moho.discovery_service_methods
DiscoveryService = Class(moho.discovery_service_methods) {

    --- Called by the engine to remove a lobby from the list of lobbies
    ---@param self UILobbyDiscoveryService
    ---@param index number
    RemoveGame = function(self, index)
        LOG('DiscoveryService.RemoveGame(' .. tostring(index) .. ')')
    end,

    --- Called by the engine when a new lobby is found
    ---@param self UILobbyDiscoveryService
    ---@param index number
    ---@param gameConfig UILobbydDiscoveryInfo
    GameFound = function(self, index, gameConfig)
        LOG('DiscoveryService.GameFound(' .. tostring(index) .. ')')
        LOG(repr(gameConfig))
    end,

    --- Called by the engine when a lobby is updated
    ---@param self UILobbyDiscoveryService
    ---@param index number
    ---@param gameConfig UILobbydDiscoveryInfo
    GameUpdated = function(self, index, gameConfig)
        LOG('DiscoveryService.GameUpdated(' .. tostring(index) .. ')')
        LOG(repr(gameConfig))
    end,
}

---@return UILobbyDiscoveryService
function CreateDiscoveryService()
    local service = InternalCreateDiscoveryService(DiscoveryService)
    LOG('*** DISC CREATE: ', service)
    return service
end

--- Will have other fields attached to it, depending on `Type`
---@class CommunicationData : table
---@field SenderID number       # provided by the engine
---@field Type string           # type of message

---@class UILobbyCommunication : moho.lobby_methods
LobbyComm = Class(moho.lobby_methods) {

    ---------------------------------------------------------------------------
    --#region Events that should be overridden

    ---@param self UILobbyCommunication
    Hosting = function(self) end,

    ---@param self UILobbyCommunication
    ---@param reason string
    ConnectionFailed = function(self, reason) end,

    ---@param self UILobbyCommunication
    ---@param localId number
    ---@param hostId number
    ConnectionToHostEstablished = function(self, localId, hostId) end,

    ---@param self UILobbyCommunication
    ---@param reason string
    Ejected = function(self, reason) end,

    ---@param self UILobbyCommunication
    ---@param text string
    SystemMessage = function(self, text)
        LOG('System: ' .. text)
    end,

    ---@param self UILobbyCommunication
    ---@param data CommunicationData
    DataReceived = function(self, data)  end,

    ---@param self UILobbyCommunication
    GameConfigRequested = function(self) end,

    ---@param self UILobbyCommunication
    ---@param peerName string
    ---@param uid string
    PeerDisconnected = function(self, peerName, uid)
        LOG('Peer Disconnected : (name=' .. peerName .. ', uid=' .. uid .. ')')
    end,

    ---@param self UILobbyCommunication
    GameLaunched = function(self) end,

    ---@param self UILobbyCommunication
    ---@param reasonKey string
    LaunchFailed = function(self, reasonKey) end,

    --#endregion

    ---@param self UILobbyCommunication
    LaunchGame = function(self, info)
        SavePreferences()
        moho.lobby_methods.LaunchGame(self, info)
    end,
}

---@param protocol UILobbyProtocols
---@param localport number
---@param localPlayerName string
---@param localPlayerUID? string
---@param natTraversalProvider? userdata
---@return UILobbyCommunication
function CreateLobbyComm(protocol, localport, localPlayerName, localPlayerUID, natTraversalProvider)
    return InternalCreateLobby(LobbyComm, protocol, localport, maxConnections, localPlayerName, localPlayerUID, natTraversalProvider)
end