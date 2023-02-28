local Version = "3753"
---@alias PATCH "3753"
---@alias VERSION "1.5.3753"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
