
local Version = "3767"
---@alias PATCH "3767"
---@alias VERSION "1.5.3767"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
