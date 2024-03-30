
local Version = "3806"
---@alias PATCH "3806"
---@alias VERSION "1.5.3806"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
