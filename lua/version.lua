
local Version = "3772"
---@alias PATCH "3772"
---@alias VERSION "1.5.3772"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
