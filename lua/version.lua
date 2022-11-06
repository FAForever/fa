local Version = "3746"
---@alias PATCH "3746"
---@alias VERSION "1.5.3746"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
