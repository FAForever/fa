
local Version = "3768"
---@alias PATCH "3768"
---@alias VERSION "1.5.3768"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
