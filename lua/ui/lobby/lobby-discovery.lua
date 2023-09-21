
---@class UILobbyDiscoveryService : moho.discovery_service_methods
---@field OnRemoveGameCallbacks table<string, fun(index: number)>
---@field OnGameFoundCallbacks table<string, fun(index: number, configuration: table)>
---@field OnGameUpdatedCallbacks table<string, fun(index: number, configuration: table)>
LobbyDiscoveryService = ClassUI(moho.discovery_service_methods) {

    OnRemoveGameCallbacks = { },
    OnGameFoundCallbacks = { },
    OnGameUpdatedCallbacks = { },

    ---@param self UILobbyDiscoveryService
    ---@param callback fun(index: number)
    ---@param name string
    AddOnRemoveGameCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnConnectionToHostEstablishedCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnConnectionToHostEstablishedCallback'")
            return
        end

        self.OnRemoveGameCallbacks[name] = callback
    end,

    ---@param self UILobbyDiscoveryService
    ---@param callback fun(index: number, configuration: table)
    ---@param name string
    AddOnGameFoundCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnConnectionToHostEstablishedCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnConnectionToHostEstablishedCallback'")
            return
        end

        self.OnGameFoundCallbacks[name] = callback
    end,

    ---@param self UILobbyDiscoveryService
    ---@param callback fun(index: number, configuration: table)
    ---@param name string
    AddOnGameUpdatedCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnConnectionToHostEstablishedCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnConnectionToHostEstablishedCallback'")
            return
        end

        self.OnGameUpdatedCallbacks[name] = callback
    end,

    --- Engine event
    ---@param self UILobbyDiscoveryService
    ---@param index number
    RemoveGame = function(self, index)
        self:Debug(string.format("RemoveGame(%s)", tostring(index)))

        for name, callback in self.OnRemoveGameCallbacks do
            local ok, msg = pcall(callback)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'RemoveGame' failed: \r\n %s", name, msg))
            end
        end
    end,

    --- Engine event
    ---@param self UILobbyDiscoveryService
    ---@param index number
    ---@param gameConfig table
    GameFound = function(self, index, gameConfig)
        self:Debug(string.format("GameFound(%s, %s)", tostring(index), reprsl(gameConfig)))

        for name, callback in self.OnGameFoundCallbacks do
            local ok, msg = pcall(callback)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'GameFound' failed: \r\n %s", name, msg))
            end
        end
    end,

    --- Engine event
    ---@param self UILobbyDiscoveryService
    ---@param index number
    ---@param gameConfig table
    GameUpdated = function(self, index, gameConfig)
        self:Debug(string.format("EstablishedPeers(%s, %s)", tostring(index), reprsl(gameConfig)))

        for name, callback in self.OnGameUpdatedCallbacks do
            local ok, msg = pcall(callback)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'GameUpdated' failed: \r\n %s", name, msg))
            end
        end
    end,

    ---------------------------------------------------------------------------
    --#region Debugging

    Debugging = true,

    Debug = function(self, message)
        if self.Debugging then
            SPEW(string.format("UILobbyDiscoveryService: %s", message))
        end
    end,

    Log = function(self, message)
        LOG(string.format("UILobbyDiscoveryService: %s", message))
    end,

    Warn = function(self, message)
        WARN(string.format("UILobbyDiscoveryService: %s", message))
    end,

}

---@return UILobbyDiscoveryService
function CreateDiscoveryService()
    local service = InternalCreateDiscoveryService(LobbyDiscoveryService) --[[@as UILobbyDiscoveryService]]
    return service
end