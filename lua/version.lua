
local Version = "3807"
---@alias PATCH "3807"
---@alias VERSION "1.5.3807"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
