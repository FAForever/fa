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

return CDiscoveryService