
local Version = "3769"
---@alias PATCH "3769"
---@alias VERSION "1.5.3769"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
