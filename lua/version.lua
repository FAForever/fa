local Version = "3748"
---@alias PATCH "3748"
---@alias VERSION "1.5.3748"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
