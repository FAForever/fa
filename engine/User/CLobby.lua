---@declare-global
---@class moho.lobby_methods
local CLobby = {}

---
function CLobby:BroadcastData()
end

---
function CLobby:ConnectToPeer(address, name, uid)
end

---
function CLobby:DebugDump()
end

---
function CLobby:Destroy()
end

---
function CLobby:DisconnectFromPeer(uid)
end

---
function CLobby:EjectPeer(targetID, reason)
end

---
---@return integer
function CLobby:GetLocalPlayerID()
end

---
---@return string
function CLobby:GetLocalPlayerName()
end

---
---@return integer | nil
function CLobby:GetLocalPort()
end

---
---@return table
function CLobby:GetPeer(uid)
end

---
---@return table
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
function CLobby:JoinGame(string-or-boxedInt32 address,  string-or-nil remotePlayerName, string remotePlayerUID)
end

---
function CLobby:LaunchGame(gameConfig)
end

---
---@return string
function CLobby:MakeValidGameName(origName)
end

---
---@return string
function CLobby:MakeValidPlayerName(uid, origName)
end

---
function CLobby:SendData(targetID, table)
end

return CLobby

