
local Version = "3804"
---@alias PATCH "3804"
---@alias VERSION "1.5.3804"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
