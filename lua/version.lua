
local Version = "3811"
---@alias PATCH "3811"
---@alias VERSION "1.5.3811"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
