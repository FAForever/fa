
local Version = "3803"
---@alias PATCH "3803"
---@alias VERSION "1.5.3803"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
