
local Version = "3771"
---@alias PATCH "3771"
---@alias VERSION "1.5.3771"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
