---@meta

---@class moho.lobby_methods : Destroyable
local CLobby = {}

---@alias GPGNetAddress string | number

---@class Peer
---@field establishedPeers string[]
---@field id string
---@field ping number
---@field name string
---@field quiet number
---@field status string

--- Broadcasts information to all peers. See `SendData` for sending to a specific peer.
---@param data CommunicationData
function CLobby:BroadcastData(data)
end

--- Connect to a new peer. The peer will now show up in `GetPeer` and `GetPeers`
---@param address GPGNetAddress # includes the port
---@param name string
---@param uid string
function CLobby:ConnectToPeer(address, name, uid)
end

---
function CLobby:DebugDump()
end

--- Destroys the lobby, disconnecting all peers and the lobby can no longer be discovered.
function CLobby:Destroy()
end

--- Disconnect from a peer. The peer will no longer show in `GetPeer` and `GetPeers`.
---@param uid string
function CLobby:DisconnectFromPeer(uid)
end

--- Eject a peer from the lobby. The peer will no longer show in `GetPeer` and `GetPeers`.
---@param targetID string
---@param reason string
function CLobby:EjectPeer(targetID, reason)
end

--- Retrieves the local client identifier.
---@return number
function CLobby:GetLocalPlayerID()
end

--- Retrieves the local player name
---@return string
function CLobby:GetLocalPlayerName()
end

--- Retrieves the local port
---@return number | nil
function CLobby:GetLocalPort()
end

--- Retrieves a specific peer
---@param uid string
---@return Peer
function CLobby:GetPeer(uid)
end

--- Retrieves all peers
---@return Peer[]
function CLobby:GetPeers()
end

--- Once hosted the lobby can be found by the discovery service. See `JoinGame` to join a hosted game.
function CLobby:HostGame()
end

--- Retrieves the flag indicating if the local client is the host
---@return boolean
function CLobby:IsHost()
end

--- Joins a lobby hosted by another peer. See `HostGame` to host a game.
---@param address GPGNetAddress
---@param remotePlayerName? string | nil
---@param remotePlayerUID? string
function CLobby:JoinGame(address, remotePlayerName, remotePlayerUID)
end

---
---@param gameConfig GameData
function CLobby:LaunchGame(gameConfig)
end

--- Creates a unique, alternative game name if that is required
---@param origName string
---@return string
function CLobby:MakeValidGameName(origName)
end

--- Creates a unique, alternative player name if that is required
---@param uid string
---@param origName string
---@return string
function CLobby:MakeValidPlayerName(uid, origName)
end

--- Sends data to a specific peer. See `BroadcastData` for sending to all peers.
---@param targetID string
---@param data CommunicationData
function CLobby:SendData(targetID, data)
end

return CLobby
