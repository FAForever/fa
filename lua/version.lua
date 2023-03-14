local Version = "3755"
---@alias PATCH "3755"
---@alias VERSION "1.5.3755"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
