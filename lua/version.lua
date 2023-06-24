
local Version = "3759"
---@alias PATCH "3759"
---@alias VERSION "1.5.3759"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
