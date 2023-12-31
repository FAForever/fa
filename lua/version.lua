
local Version = "3778"
---@alias PATCH "3778"
---@alias VERSION "1.5.3778"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
