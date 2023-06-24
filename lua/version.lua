
local Version = "3758"
---@alias PATCH "3758"
---@alias VERSION "1.5.3758"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
