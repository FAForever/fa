
local Version = "3810"
---@alias PATCH "3810"
---@alias VERSION "1.5.3810"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
