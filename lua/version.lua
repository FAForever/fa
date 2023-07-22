
local Version = "3762"
---@alias PATCH "3762"
---@alias VERSION "1.5.3762"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
