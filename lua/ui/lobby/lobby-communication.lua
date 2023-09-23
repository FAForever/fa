
--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
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

---@class UILobbyCommunicationData
---@field SenderID number
---@field Type string

---@class UILobbyCommunication : moho.lobby_methods
---@field Debugging boolean
---@field OnConnectingCallbacks table<string, fun()>
---@field OnHostingCallbacks table<string, fun()>
---@field OnConnectionFailedCallbacks table<string, fun(reason: string)>
---@field OnConnectionToHostEstablishedCallbacks table<string, fun(localID: number, localName, hostID: number)>
---@field OnEjectedCallbacks table<string, fun(reason: string)>
---@field OnSystemMessageCallbacks table<string, fun(message: string)>
---@field OnDataReceivedCallbacks table<string, fun(message: UILobbyCommunicationData)>
---@field OnGameConfigRequestedCallbacks table<string, fun()>
---@field OnPeerDisconnectedCallbacks table<string, fun(peerName: string, peerUID: string)>
---@field OnEstablishedPeersCallbacks table<string, fun(peerUID: string, connectedPeers: string[])>
---@field OnGameLaunchedCallbacks table<string, fun()>
---@field OnLaunchFailedCallbacks table<string, fun(reason: string)>
LobbyCommunication = Class(moho.lobby_methods) {

    HostID = -1,

    LocalID = -1,
    LocalName = "<unknown>",

    OnConnectingCallbacks = { },
    OnHostingCallbacks = { },
    OnConnectionFailedCallbacks = { },
    OnConnectionToHostEstablishedCallbacks = { },
    OnEjectedCallbacks = { },
    OnSystemMessageCallbacks = { },
    OnDataReceivedCallbacks = { },
    OnGameConfigRequestedCallbacks = { },
    OnPeerDisconnectedCallbacks = { },
    OnGameLaunchedCallbacks = { },
    OnLaunchFailedCallbacks = { },
    OnEstablishedPeersCallbacks = { },

    ---------------------------------------------------------------------------
    --#region Engine events

    ---@param self UILobbyCommunication
    Connecting = function(self)
        self:Debug(string.format("Connecting()"))

        for name, callback in self.OnConnectingCallbacks do
            local ok, msg = pcall(callback)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'Connecting' failed: \r\n %s", name, msg))
            end
        end
    end,

    ---@param self UILobbyCommunication
    Hosting = function(self)
        self:Debug(string.format("Hosting()"))

        self.LocalID = self:GetLocalPlayerID()
        self.HostId = self:GetLocalPlayerID()

        for name, callback in self.OnHostingCallbacks do
            local ok, msg = pcall(callback)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'Hosting' failed: \r\n %s", name, msg))
            end
        end
    end,

    ---@param self UILobbyCommunication
    ---@param reason string
    ConnectionFailed = function(self, reason)
        self:Debug(string.format("ConnectionFailed(%s)", tostring(reason)))

        for name, callback in self.OnConnectionFailedCallbacks do
            local ok, msg = pcall(callback, reason)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'ConnectionFailed' failed: \r\n %s", name, msg))
            end
        end
    end,

    ---@param self UILobbyCommunication
    ---@param localID number
    ---@param hostID number
    ConnectionToHostEstablished = function(self, localID, ourName, hostID)
        self:Debug(string.format("ConnectionToHostEstablished(%s, %s, %s)", tostring(localID), tostring(ourName), tostring(hostID)))

        self.LocalID = localID
        self.HostId = hostID

        for name, callback in self.OnConnectionToHostEstablishedCallbacks do
            local ok, msg = pcall(callback, localID, hostID)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'ConnectionToHostEstablished' failed: \r\n %s", name, msg))
            end
        end
    end,

    ---@param self UILobbyCommunication
    ---@param reason string
    Ejected = function(self, reason) 
        self:Debug(string.format("Ejected(%s)", tostring(reason)))

        for name, callback in self.OnEjectedCallbacks do
            local ok, msg = pcall(callback, reason)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'Ejected' failed: \r\n %s", name, msg))
            end
        end
    end,

    ---@param self UILobbyCommunication
    ---@param text string
    SystemMessage = function(self, text)
        self:Debug(string.format("SystemMessage(%s)", tostring(text)))

        for name, callback in self.OnSystemMessageCallbacks do
            local ok, msg = pcall(callback, text)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'SystemMessage' failed: \r\n %s", name, msg))
            end
        end
    end,

    ---@param self UILobbyCommunication
    ---@param data string
    DataReceived = function(self, data)
        self:Debug(string.format("DataReceived(%s)", reprs(data)))

        -- TODO: do some kind of checksum?

        for name, callback in self.OnDataReceivedCallbacks do
            local ok, msg = pcall(callback, data)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'DataReceived' failed: \r\n %s", name, msg))
            end
        end
    end,

    ---@param self UILobbyCommunication
    GameConfigRequested = function(self)
        self:Debug(string.format("PeerDisconnected()"))

        for name, callback in self.OnGameConfigRequestedCallbacks do
            local ok, msg = pcall(callback)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'GameConfigRequested' failed: \r\n %s", name, msg))
            end
        end
    end,

    ---@param self UILobbyCommunication
    ---@param peerName string
    ---@param uid string
    PeerDisconnected = function(self, peerName, uid)
        self:Debug(string.format("PeerDisconnected(%s, %s)", tostring(peerName), tostring(uid)))

        for name, callback in self.OnPeerDisconnectedCallbacks do
            local ok, msg = pcall(callback,peerName, uid)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'PeerDisconnected' failed: \r\n %s", name, msg))
            end
        end
    end,

    ---@param self UILobbyCommunication
    GameLaunched = function(self)
        self:Debug("GameLaunched()")

        for name, callback in self.OnGameLaunchedCallbacks do
            local ok, msg = pcall(callback)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'GameLaunched' failed: \r\n %s", name, msg))
            end
        end
    end,

    ---@param self UILobbyCommunication
    ---@param reasonKey string
    LaunchFailed = function(self, reasonKey)
        self:Debug("LaunchFailed()")

        for name, callback in self.OnLaunchFailedCallbacks do
            local ok, msg = pcall(callback, reasonKey)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'LaunchFailed' failed: \r\n %s", name, msg))
            end
        end
    end,

    ---@param self UILobbyCommunication
    ---@param peerUID string # peer id that the message is about
    ---@param connectedPeers string[] # player ids that are connected to the peer
    EstablishedPeers = function(self, peerUID, connectedPeers)
        self:Debug(string.format("EstablishedPeers(%s, %s)", tostring(peerUID), reprs(connectedPeers)))

        for name, callback in self.OnEstablishedPeersCallbacks do
            local ok, msg = pcall(callback,peerUID, connectedPeers)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'EstablishedPeers' failed: \r\n %s", name, msg))
            end
        end
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Event callbacks

    ---@param self UILobbyCommunication
    ---@param callback fun()
    ---@param name string
    AddOnHostingCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for 'AddOnHostingCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnHostingCallback'")
            return
        end

        self.OnHostingCallbacks[name] = callback
    end,

    ---@param self UILobbyCommunication
    ---@param callback fun()
    ---@param name string
    AddOnConnectingCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for 'AddOnConnectingCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnConnectingCallback'")
            return
        end

        self.OnConnectingCallbacks[name] = callback
    end,

    ---@param self UILobbyCommunication
    ---@param callback fun(reason: string)
    ---@param name string
    AddOnConnectionFailedCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnConnectionFailedCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnConnectionFailedCallback'")
            return
        end

        self.OnConnectionFailedCallbacks[name] = callback
    end,

    ---@param self UILobbyCommunication
    ---@param callback fun(ourID: string, hostID: string)
    ---@param name string
    AddOnConnectionToHostEstablishedCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnConnectionToHostEstablishedCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnConnectionToHostEstablishedCallback'")
            return
        end

        self.OnConnectionToHostEstablishedCallbacks[name] = callback
    end,

    ---@param self UILobbyCommunication
    ---@param callback fun(reason: string)
    ---@param name string
    AddOnEjectedCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnEjectedCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnEjectedCallback'")
            return
        end

        self.OnEjectedCallbacks[name] = callback
    end,

    ---@param self UILobbyCommunication
    ---@param callback fun(message: string)
    ---@param name string
    AddOnSystemMessageCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnSystemMessageCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnSystemMessageCallback'")
            return
        end

        self.OnSystemMessageCallbacks[name] = callback
    end,

    ---@param self UILobbyCommunication
    ---@param callback fun(message: UILobbyCommunicationData)
    ---@param name string
    AddOnDataReceivedCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnDataReceivedCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnDataReceivedCallback'")
            return
        end

        self.OnDataReceivedCallbacks[name] = callback
    end,

    ---@param self UILobbyCommunication
    ---@param callback fun()
    ---@param name string
    AddOnGameConfigRequestedCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnGameConfigRequestedCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnGameConfigRequestedCallback'")
            return
        end

        self.OnGameConfigRequestedCallbacks[name] = callback
    end,

    ---@param self UILobbyCommunication
    ---@param callback fun(peerName: string, peerUID: string)
    ---@param name string
    AddOnPeerDisconnectedCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnPeerDisconnectedCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnPeerDisconnectedCallback'")
            return
        end

        self.OnPeerDisconnectedCallbacks[name] = callback
    end,

    ---@param self UILobbyCommunication
    ---@param callback fun()
    ---@param name string
    AddOnGameLaunchedCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnGameLaunchedCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnGameLaunchedCallback'")
            return
        end

        self.OnGameLaunchedCallbacks[name] = callback
    end,

    ---@param self UILobbyCommunication
    ---@param callback fun(reason: string)
    ---@param name string
    AddOnLaunchFailedCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnLaunchFailedCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnLaunchFailedCallback'")
            return
        end

        self.OnLaunchFailedCallbacks[name] = callback
    end,

    ---@param self UILobbyCommunication
    ---@param callback fun(peerUID: string, connectedPeers: string[])
    ---@param name string
    AddOnEstablishedPeersCallbacks = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnLaunchFailedCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnLaunchFailedCallback'")
            return
        end

        self.OnEstablishedPeersCallbacks[name] = callback
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Debugging

    Debugging = true,

    ---@param self UILobbyCommunication
    ---@param message string
    Debug = function(self, message)
        if self.Debugging then
            SPEW(string.format("UILobbyCommunication: %s", message))
        end
    end,

    ---@param self UILobbyCommunication
    ---@param message string
    Log = function(self, message)
        LOG(string.format("UILobbyCommunication: %s", message))
    end,

    ---@param self UILobbyCommunication
    ---@param message string
    Warn = function(self, message)
        WARN(string.format("UILobbyCommunication: %s", message))
    end,
}

---@param port number
---@param localPlayerName string
---@param localPlayerUID? string
---@return UILobbyCommunication
CreateLobbyCommunications = function(port, localPlayerName, localPlayerUID)
    return InternalCreateLobby (
        LobbyCommunication,
        "UDP",
        port,
        8,
        localPlayerName,
        localPlayerUID,
        nil
    ) --[[@as UILobbyCommunication]]
end

