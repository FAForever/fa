
local Version = "3765"
---@alias PATCH "3765"
---@alias VERSION "1.5.3765"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
