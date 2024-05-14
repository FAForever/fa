
local Version = "3809"
---@alias PATCH "3809"
---@alias VERSION "1.5.3809"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
