
---@class UILobbyCommunicationData
---@field SenderID number
---@field Type string

---@class UILobbyCommunication : moho.lobby_methods
---@field Debugging boolean
---@field OnHostingCallbacks table<string, fun()>
---@field OnConnectionFailedCallbacks table<string, fun(reason: string)>
---@field OnConnectionToHostEstablishedCallbacks table<string, fun(ourID: string, hostID: string)>
---@field OnEjectedCallbacks table<string, fun(reason: string)>
---@field OnSystemMessageCallbacks table<string, fun(message: string)>
---@field OnDataReceivedCallbacks table<string, fun(message: UILobbyCommunicationData)>
---@field OnGameConfigRequestedCallbacks table<string, fun()>
---@field OnPeerDisconnectedCallbacks table<string, fun(peerName: string, peerUID: string)>
---@field OnGameLaunchedCallbacks table<string, fun()>
---@field OnLaunchFailedCallbacks table<string, fun(reason: string)>
LobbyCommunication = Class(moho.lobby_methods) {

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

    --- Engine event
    ---@param self UILobbyCommunication
    Hosting = function(self)
        self:Debug(string.format("Hosting()"))

        for name, callback in self.OnHostingCallbacks do
            local ok, msg = pcall(callback)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'Hosting' failed: \r\n %s", name, msg))
            end
        end
    end,

    --- Engine event
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

    --- Engine event
    ---@param self UILobbyCommunication
    ---@param ourID string
    ---@param hostID string
    ConnectionToHostEstablished = function(self, ourID, hostID)
        self:Debug(string.format("ConnectionToHostEstablished(%s, %s)", tostring(ourID), tostring(hostID)))

        for name, callback in self.OnConnectionToHostEstablishedCallbacks do
            local ok, msg = pcall(callback, ourID, hostID)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'ConnectionToHostEstablished' failed: \r\n %s", name, msg))
            end
        end
    end,

    --- Engine event
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

    --- Engine event
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

    --- Engine event
    ---@param self UILobbyCommunication
    ---@param data string
    DataReceived = function(self, data)
        self:Debug(string.format("DataReceived(%s)", reprsl(data)))

        -- TODO: do some kind of checksum?

        for name, callback in self.OnDataReceivedCallbacks do
            local ok, msg = pcall(callback, data)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'DataReceived' failed: \r\n %s", name, msg))
            end
        end
    end,

    --- Engine event
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

    --- Engine event
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

    --- Engine event
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

    --- Engine event
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

    ---------------------------------------------------------------------------
    --#region Debugging

    Debugging = true,

    Debug = function(self, message)
        if self.Debugging then
            SPEW(string.format("UILobbyCommunication: %s", message))
        end
    end,

    Log = function(self, message)
        LOG(string.format("UILobbyCommunication: %s", message))
    end,

    Warn = function(self, message)
        WARN(string.format("UILobbyCommunication: %s", message))
    end,
}

---@param port number
---@param localPlayerName string
---@param localPlayerUID string
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

