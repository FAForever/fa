--- Class CLobby
-- @classmod User.CLobby

---
--  void CLobby.ConnectToPeer(self,address,name,uid
function CLobby:ConnectToPeer()
end

---
--  void CLobby.DebugDump()
function CLobby:DebugDump()
end

---
--  CLobby.Destroy(self)
function CLobby:Destroy(self)
end

---
--  void CLobby.DisconnectFromPeer(self,uid
function CLobby:DisconnectFromPeer()
end

---
--  void CLobby.EjectPeer(self,targetID,reason)
function CLobby:EjectPeer(self, targetID, reason)
end

---
--  int CLobby.GetLocalPlayerID(self)
function CLobby:GetLocalPlayerID(self)
end

---
--  string CLobby.GetLocalPlayerName(self)
function CLobby:GetLocalPlayerName(self)
end

---
--  int-or-nil CLobby.GetLocalPort(self)
function CLobby:GetLocalPort(self)
end

---
--  table CLobby.GetPeer(self,uid)
function CLobby:GetPeer(self, uid)
end

---
--  table CLobby.GetPeers(self)
function CLobby:GetPeers(self)
end

---
--  void CLobby.HostGame(self)
function CLobby:HostGame(self)
end

---
--  bool CLobby.IsHost(self)
function CLobby:IsHost(self)
end

---
--  void CLobby.JoinGame(self, string-or-boxedInt32 address, string-or-nil remotePlayerName, string remotePlayerUID)
function CLobby:JoinGame(self,  string-or-boxedInt32 address,  string-or-nil remotePlayerName,  string remotePlayerUID)
end

---
--  void CLobby.LaunchGame(self,gameConfig)
function CLobby:LaunchGame(self, gameConfig)
end

---
--  string CLobby.MakeValidGameName(self,origName)
function CLobby:MakeValidGameName(self, origName)
end

---
--  string CLobby.MakeValidPlayerName(self,uid,origName)
function CLobby:MakeValidPlayerName(self, uid, origName)
end

---
--  void CLobby.SendData(self,targetID,table)
function CLobby:SendData(self, targetID, table)
end

---
--
function CLobby:moho.lobby_methods()
end

