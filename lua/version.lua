
local Version = "3805"
---@alias PATCH "3805"
---@alias VERSION "1.5.3805"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
