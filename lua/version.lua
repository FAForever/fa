
local Version = "3773"
---@alias PATCH "3773"
---@alias VERSION "1.5.3773"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
