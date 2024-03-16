
local Version = "3802"
---@alias PATCH "3802"
---@alias VERSION "1.5.3802"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
