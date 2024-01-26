
local Version = "3781"
---@alias PATCH "3781"
---@alias VERSION "1.5.3781"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
