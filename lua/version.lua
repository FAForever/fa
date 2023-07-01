
local Version = "3760"
---@alias PATCH "3760"
---@alias VERSION "1.5.3760"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
