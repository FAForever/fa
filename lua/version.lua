
local Version = "3779"
---@alias PATCH "3779"
---@alias VERSION "1.5.3779"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
