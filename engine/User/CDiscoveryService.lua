---@meta

---@class UILobbydDiscoveryInfo
---@field Address string        # 192.168.1.12:57061
---@field GameName string
---@field HostedBy string       # username, e.g. 'jip'
---@field Hostname string       # name of the device 
---@field Options GameOptions | { ScenarioFile: string }   # set of all game options
---@field PlayerCount number
---@field ProductCode 'SC' | 'SC1X' | 'FAF'
---@field Protocol 'UDP' | 'TCP' | 'None'

---@class moho.discovery_service_methods : Destroyable
local CDiscoveryService = {}

--- Retrieves the current number of lobbies
---@return number
function CDiscoveryService:GetGameCount()
end

--- Resets the discovery service, effectively clearing all lobbies
function CDiscoveryService:Reset()
end

function CDiscoveryService:Destroy()
end

--- Called by the engine when a new lobby answers the discovery request, with the 0-based index of
--- the lobby and the configuration it sent.
---@see moho.lobby_methods.GameConfigRequested # Returns the configuration, on the host
---@type nil | fun(self: UILobbyDiscoveryService, index: integer, gameConfig: UILobbydDiscoveryInfo)
CDiscoveryService.GameFound = nil

--- Called by the engine when a known lobby answers the discovery request again, with the 0-based
--- index of the lobby and the configuration it sent.
---@see moho.lobby_methods.GameConfigRequested # Returns the configuration, on the host
---@type nil | fun(self: UILobbyDiscoveryService, index: integer, gameConfig: UILobbydDiscoveryInfo)
CDiscoveryService.GameUpdated = nil

--- Called by the engine when a lobby stops answering or the service is reset, with the 0-based
--- index of the lobby. Indices of the lobbies after it shift down by one.
---@type nil | fun(self: UILobbyDiscoveryService, index: integer)
CDiscoveryService.RemoveGame = nil

return CDiscoveryService