
---@class UILobbydDiscoveryInfo
---@field Address string        # 192.168.1.12:57061
---@field GameName string
---@field HostedBy string       # username, e.g. 'jip'
---@field Hostname string       # name of the device 
---@field Options GameOptions | { ScenarioFile: string }   # set of all game options
---@field PlayerCount number
---@field ProductCode 'SC' | 'SC1X' | 'FAF'
---@field Protocol 'UDP' | 'TCP' | 'None'

---@class UILobbyDiscoveryService : moho.discovery_service_methods
---@field OnRemoveGameCallbacks table<string, fun(index: number)>
---@field OnGameFoundCallbacks table<string, fun(index: number, configuration: UILobbydDiscoveryInfo)>
---@field OnGameUpdatedCallbacks table<string, fun(index: number, configuration: UILobbydDiscoveryInfo)>
LobbyDiscoveryService = ClassUI(moho.discovery_service_methods) {

    OnRemoveGameCallbacks = { },
    OnGameFoundCallbacks = { },
    OnGameUpdatedCallbacks = { },

    ---@param self UILobbyDiscoveryService
    ---@param callback fun(index: number)
    ---@param name string
    AddOnRemoveGameCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnRemoveGameCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnRemoveGameCallback'")
            return
        end

        self.OnRemoveGameCallbacks[name] = callback
    end,

    ---@param self UILobbyDiscoveryService
    ---@param callback fun(index: number, configuration: UILobbydDiscoveryInfo)
    ---@param name string
    AddOnGameFoundCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnGameFoundCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnGameFoundCallback'")
            return
        end

        self.OnGameFoundCallbacks[name] = callback
    end,

    ---@param self UILobbyDiscoveryService
    ---@param callback fun(index: number, configuration: UILobbydDiscoveryInfo)
    ---@param name string
    AddOnGameUpdatedCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnGameUpdatedCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnGameUpdatedCallback'")
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
            local ok, msg = pcall(callback, index)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'RemoveGame' failed: \r\n %s", name, msg))
            end
        end
    end,

    --- Engine event
    ---@param self UILobbyDiscoveryService
    ---@param index number
    ---@param gameConfig UILobbydDiscoveryInfo
    GameFound = function(self, index, gameConfig)
        self:Debug(string.format("GameFound(%s, %s)", tostring(index), reprs(gameConfig)))

        for name, callback in self.OnGameFoundCallbacks do
            local ok, msg = pcall(callback, index, gameConfig)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'GameFound' failed: \r\n %s", name, msg))
            end
        end
    end,

    --- Engine event
    ---@param self UILobbyDiscoveryService
    ---@param index number
    ---@param gameConfig UILobbydDiscoveryInfo
    GameUpdated = function(self, index, gameConfig)
        self:Debug(string.format("GameUpdated(%s, %s)", tostring(index), reprs(gameConfig)))

        for name, callback in self.OnGameUpdatedCallbacks do
            local ok, msg = pcall(callback, index, gameConfig)
            if not ok then
                self:Warn(string.format("Callback '%s' for 'GameUpdated' failed: \r\n %s", name, msg))
            end
        end
    end,

    ---------------------------------------------------------------------------
    --#region Debugging

    Debugging = true,

    ---@param self UILobbyDiscoveryService
    ---@param message string
    Debug = function(self, message)
        if self.Debugging then
            SPEW(string.format("UILobbyDiscoveryService: %s", message))
        end
    end,

    ---@param self UILobbyDiscoveryService
    ---@param message string
    Log = function(self, message)
        LOG(string.format("UILobbyDiscoveryService: %s", message))
    end,

    ---@param self UILobbyDiscoveryService
    ---@param message string
    Warn = function(self, message)
        WARN(string.format("UILobbyDiscoveryService: %s", message))
    end,

}

---@return UILobbyDiscoveryService
function CreateDiscoveryService()
    local service = InternalCreateDiscoveryService(LobbyDiscoveryService) --[[@as UILobbyDiscoveryService]]
    return service
end