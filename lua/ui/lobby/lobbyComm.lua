#
# Lobby communications and common services
#
quietTimeout = 30000.0 -- milliseconds to wait before booting people
maxPlayerSlots = 16
maxConnections = 16 -- count doesn't include ourself.

Strings = {
    # General info strings
    ['Connecting'] = "<LOC lobui_0083>Connecting to Game",
    ['AbortConnect'] = "<LOC lobui_0204>Abort Connect",
    ['TryingToConnect'] = "<LOC lobui_0331>Connecting...",
    ['TimedOut'] = "<LOC lobui_0205>%s timed out.",
    ['TimedOutToHost'] = "<LOC lobui_0206>Timed out to host.",
    ['Ejected'] = "<LOC lob_0000>You have been ejected: %s",
    ['ConnectionFailed'] = "<LOC lob_0001>Connection failed: %s",
    ['LaunchFailed'] = "<LOC lobui_0207>Launch failed: %s",
    ['LobbyFull'] = "<LOC lobui_0279>The game lobby is full.",

    # Error reasons
    ['StartSpots'] = "<LOC lob_0002>The map does not support this number of players.",
    ['NoConfig'] = "<LOC lob_0003>No valid game configurations found.",
    ['NoObservers'] = "<LOC lob_0004>Observers not allowed.",
    ['KickedByHost'] = "<LOC lob_0005>Kicked by host.",
    ['GameLaunched'] = "<LOC lob_0008>Game was launched.",
    ['NoLaunchLimbo'] = "<LOC lob_0006>No clients allowed in limbo at launch",
    ['HostLeft'] = "<LOC lob_0007>Host abandoned lobby",
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
        Faction = table.getn(import('/lua/factions.lua').Factions) + 1, --max faction + 1 tells lobby to pick random faction
        PlayerName = playerName or "player",
        AIPersonality = "",
        Human = true,
        Civilian = false,
    }
end

DiscoveryService = Class(moho.discovery_service_methods) {
    RemoveGame = function(self, index)
                     LOG('DiscoveryService.RemoveGame(' .. tostring(index) .. ')')
                 end,
    GameFound = function(self, index, gameConfig)
                    LOG('DiscoveryService.GameFound(' .. tostring(index) .. ')')
                    LOG(repr(gameConfig))
                end,
    GameUpdated = function(self, index, gameConfig)
                      LOG('DiscoveryService.GameUpdated(' .. tostring(index) .. ')')
                      LOG(repr(gameConfig))
                  end,
}

function CreateDiscoveryService()
    local service = InternalCreateDiscoveryService(DiscoveryService)
    LOG('*** DISC CREATE: ', service)
    return service
end

LobbyComm = Class(moho.lobby_methods) {

    # General events you should override
    Hosting = function(self) end,
    ConnectionFailed = function(self, reason) end,
    ConnectionToHostEstablished = function(self,ourID,hostID) end,
    GameLaunched = function(self) end,
    Ejected = function(self,reason) end,
    SystemMessage = function(self, text) LOG('System: ' .. text) end,
    DataReceived = function(self, data)  end,
    GameConfigRequested = function(self) end,
    PeerDisconnected = function(self,peerName,uid) LOG ('Peer Disconnected : (name=' .. peerName .. ', uid=' .. uid .. ')') end,
    LaunchFailed = function(self,reasonKey) end,

    # native void SendData(self, targetID, data)
    # native void BroadcastData(self,data)
    # native void Destroy(self)
    # native bool IsHost(self)
    # native table GetPeers(self)
    # native int GetPlayerCount(self)
    # native string GetLocalPlayerName(self)
    # native void EjectPeer(self, targetID, reason)
    # native string MakeValidGameName(self,desiredName)
    # native string MakeValidPlayerName(self,uid,desiredName)
    # native void HostGame(self)
    # native void JoinGame(self, addressStr, string-or-nil remotePlayerName, remotePlayerUIDStr)
    # native void LaunchGame(self,gameInfo)
    # native void DebugDump(self)
    # native string GetLocalPlayerID(self)
    # native int-or-nil GetLocalPort(self)

    # Used by GPGNET
    # native void ConnectToPeer(addressStr,port,name,uidStr)
    # native void DisconnectFromPeer(uidStr)
}

function CreateLobbyComm(protocol, localport, localPlayerName, localPlayerUID, natTraversalProvider)
    return InternalCreateLobby(LobbyComm, protocol, localport, maxConnections, localPlayerName, localPlayerUID, natTraversalProvider)
end
