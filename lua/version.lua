local Version = "3752"
---@alias PATCH "3752"
---@alias VERSION "1.5.3752"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
