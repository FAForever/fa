local Version = "3744"
---@alias PATCH "3744"
---@alias VERSION "1.5.3744"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
