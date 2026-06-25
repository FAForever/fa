--******************************************************************************************************
--** Copyright (c) 2026 FAForever
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

-- The moho.lobby_methods object the engine instantiates (via InternalCreateLobby in
-- /lua/ui/lobby/lobby.lua). Thin shell: it validates/dispatches network traffic and
-- forwards behavioural callbacks to CustomLobbyController. Engine-ABI methods we
-- don't override (HostGame, JoinGame, GetLocalPlayerID, IsHost, ConnectToPeer, …)
-- are inherited from moho.lobby_methods.
--
-- Like AutolobbyInstance, this object does NOT hot-reload — keep behaviour in the
-- controller. See /lua/ui/lobby/customlobby/CLAUDE.md.

local MohoLobbyMethods = moho.lobby_methods

local CustomLobbyMessages = import("/lua/ui/lobby/customlobby/customlobbymessages.lua").CustomLobbyMessages
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbyLog = import("/lua/ui/lobby/customlobby/customlobbylog.lua")

---@class UICustomLobbyInstance : moho.lobby_methods
---@field Trash TrashBag
CustomLobbyInstance = Class(MohoLobbyMethods) {

    ---@param self UICustomLobbyInstance
    __init = function(self)
        self.Trash = TrashBag()
    end,

    ---------------------------------------------------------------------------
    --#region Engine interface (validated wrappers)

    --- Broadcasts data to all connected peers, after validating it.
    ---@param self UICustomLobbyInstance
    ---@param data table
    BroadcastData = function(self, data)
        local message = CustomLobbyMessages[data.Type]
        if not message then
            WARN("CustomLobby: blocked broadcast of unknown message type " .. tostring(data.Type))
            return
        end
        if not message.Validate(self, data) then
            WARN("CustomLobby: blocked broadcast of malformed message " .. tostring(data.Type))
            return
        end
        CustomLobbyLog.Broadcast(data)
        return MohoLobbyMethods.BroadcastData(self, data)
    end,

    --- Sends data to a single peer, after validating it.
    ---@param self UICustomLobbyInstance
    ---@param peerId UILobbyPeerId
    ---@param data table
    SendData = function(self, peerId, data)
        local message = CustomLobbyMessages[data.Type]
        if not message then
            WARN("CustomLobby: blocked send of unknown message type " .. tostring(data.Type))
            return
        end
        if not message.Validate(self, data) then
            WARN("CustomLobby: blocked send of malformed message " .. tostring(data.Type))
            return
        end
        CustomLobbyLog.Send(peerId, data)
        return MohoLobbyMethods.SendData(self, peerId, data)
    end,

    --- Tells the server a seated player's army setting at launch (host-only). No-op unless we're
    --- on the GPGNet path (the FAF client); a local test launch just skips it.
    ---@param self UICustomLobbyInstance
    ---@param peerId UILobbyPeerId
    ---@param key 'Team' | 'Army' | 'StartSpot' | 'Faction'
    ---@param value any
    SendPlayerOptionToServer = function(self, peerId, key, value)
        if self:IsHost() and GpgNetActive() then
            GpgNetSend('PlayerOption', peerId, key, value)
        end
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Engine callbacks (forwarded to the controller)

    ---@param self UICustomLobbyInstance
    Hosting = function(self)
        CustomLobbyController.OnHosting(self)
    end,

    ---@param self UICustomLobbyInstance
    ---@param localId UILobbyPeerId
    ---@param localName string
    ---@param hostId UILobbyPeerId
    ConnectionToHostEstablished = function(self, localId, localName, hostId)
        CustomLobbyController.OnConnectionToHostEstablished(self, localId, localName, hostId)
    end,

    ---@param self UICustomLobbyInstance
    ---@param reason string
    ConnectionFailed = function(self, reason)
        CustomLobbyController.OnConnectionFailed(self, reason)
    end,

    ---@param self UICustomLobbyInstance
    ---@param peerId UILobbyPeerId
    ---@param peerConnectedTo UILobbyPeerId[]
    EstablishedPeers = function(self, peerId, peerConnectedTo)
        -- barebones: connectivity matrix not modelled yet
    end,

    ---@param self UICustomLobbyInstance
    ---@param peerName string
    ---@param uid UILobbyPeerId
    PeerDisconnected = function(self, peerName, uid)
        CustomLobbyController.OnPeerDisconnected(self, peerName, uid)
    end,

    ---@param self UICustomLobbyInstance
    GameLaunched = function(self)
        CustomLobbyController.OnGameLaunched(self)
    end,

    ---@param self UICustomLobbyInstance
    ---@param reason string
    Ejected = function(self, reason)
        LOG("CustomLobby: ejected: " .. tostring(reason))
    end,

    ---@param self UICustomLobbyInstance
    ---@param text string
    SystemMessage = function(self, text)
        LOG("CustomLobby system: " .. tostring(text))
    end,

    ---@param self UICustomLobbyInstance
    GameConfigRequested = function(self)
    end,

    ---@param self UICustomLobbyInstance
    ---@param reasonKey string
    LaunchFailed = function(self, reasonKey)
        WARN("CustomLobby: launch failed: " .. tostring(reasonKey))
    end,

    --- Validates, authorises and routes an incoming message.
    ---@param self UICustomLobbyInstance
    ---@param data table
    DataReceived = function(self, data)
        local message = CustomLobbyMessages[data.Type]
        if not message then
            WARN("CustomLobby: ignoring unknown message type " .. tostring(data.Type) .. " from " .. tostring(data.SenderID))
            return
        end
        CustomLobbyLog.Received(data)
        if not message.Validate(self, data) then
            WARN("CustomLobby: ignoring malformed message " .. tostring(data.Type) .. " from " .. tostring(data.SenderID))
            return
        end
        if not message.Accept(self, data) then
            WARN("CustomLobby: rejected message " .. tostring(data.Type) .. " from " .. tostring(data.SenderID))
            return
        end
        message.Handler(self, data)
    end,

    --- Destroys the C-object and the trash bag.
    ---@param self UICustomLobbyInstance
    Destroy = function(self)
        self.Trash:Destroy()
        return MohoLobbyMethods.Destroy(self)
    end,

    --#endregion
}
