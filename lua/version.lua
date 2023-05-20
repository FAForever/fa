local Version = "3757"
---@alias PATCH "3757"
---@alias VERSION "1.5.3757"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
