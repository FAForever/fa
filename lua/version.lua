local Version = "3756d"
---@alias PATCH "3756d"
---@alias VERSION "1.5.3756d"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
