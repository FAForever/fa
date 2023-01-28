local Version = "3750"
---@alias PATCH "3750"
---@alias VERSION "1.5.3750"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
