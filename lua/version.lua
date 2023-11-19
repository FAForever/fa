
local Version = "3775"
---@alias PATCH "3775"
---@alias VERSION "1.5.3775"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
