
local Version = "3777"
---@alias PATCH "3777"
---@alias VERSION "1.5.3777"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
