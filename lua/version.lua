
local Version = "3800"
---@alias PATCH "3800"
---@alias VERSION "1.5.3800"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
