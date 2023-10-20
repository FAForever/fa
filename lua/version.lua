
local Version = "3770"
---@alias PATCH "3770"
---@alias VERSION "1.5.3770"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
