local Version = "3749"
---@alias PATCH "3749"
---@alias VERSION "1.5.3749"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
