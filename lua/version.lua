
local Version = "3766"
---@alias PATCH "3766"
---@alias VERSION "1.5.3766"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
