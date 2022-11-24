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

---
---@param data CommunicationData
function CLobby:BroadcastData(data)
end

---
---@param address GPGNetAddress # includes the port
---@param name string
---@param uid string
function CLobby:ConnectToPeer(address, name, uid)
end

---
function CLobby:DebugDump()
end

---
function CLobby:Destroy()
end

---
---@param uid string
function CLobby:DisconnectFromPeer(uid)
end

---
---@param targetID string
---@param reason string
function CLobby:EjectPeer(targetID, reason)
end

---
---@return number
function CLobby:GetLocalPlayerID()
end

---
---@return string
function CLobby:GetLocalPlayerName()
end

---
---@return number | nil
function CLobby:GetLocalPort()
end

---
---@param uid string
---@return Peer
function CLobby:GetPeer(uid)
end

---
---@return Peer[]
function CLobby:GetPeers()
end

---
function CLobby:HostGame()
end

---
---@return boolean
function CLobby:IsHost()
end

---
---@param address GPGNetAddress
---@param remotePlayerName string | nil
---@param remotePlayerUID string
function CLobby:JoinGame(address, remotePlayerName, remotePlayerUID)
end

---
---@param gameConfig GameData
function CLobby:LaunchGame(gameConfig)
end

---
---@param origName string
---@return string
function CLobby:MakeValidGameName(origName)
end

---
---@param uid string
---@param origName string
---@return string
function CLobby:MakeValidPlayerName(uid, origName)
end

---
---@param targetID string
---@param data CommunicationData
function CLobby:SendData(targetID, data)
end

return CLobby
