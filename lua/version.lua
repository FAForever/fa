
local Version = "3808"
---@alias PATCH "3808"
---@alias VERSION "1.5.3808"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
