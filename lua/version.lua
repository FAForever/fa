
local Version = "3776"
---@alias PATCH "3776"
---@alias VERSION "1.5.3776"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
