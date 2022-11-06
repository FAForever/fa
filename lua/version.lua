local Version = "3745"
---@alias PATCH "3745"
---@alias VERSION "1.5.3745"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
