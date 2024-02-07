
local Version = "3801"
---@alias PATCH "3801"
---@alias VERSION "1.5.3801"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
