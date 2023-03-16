local Version = "3756"
---@alias PATCH "3756"
---@alias VERSION "1.5.3756"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
