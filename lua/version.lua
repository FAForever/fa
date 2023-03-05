local Version = "3754"
---@alias PATCH "3754"
---@alias VERSION "1.5.3754"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
