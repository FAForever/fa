local Version = "3747"
---@alias PATCH "3747"
---@alias VERSION "1.5.3747"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
