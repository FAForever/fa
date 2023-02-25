local Version = "3751"
---@alias PATCH "3751"
---@alias VERSION "1.5.3751"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
