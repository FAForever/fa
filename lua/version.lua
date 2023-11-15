
local Version = "3774"
---@alias PATCH "3774"
---@alias VERSION "1.5.3774"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
