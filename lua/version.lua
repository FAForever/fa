
local Version = "3763"
---@alias PATCH "3763"
---@alias VERSION "1.5.3763"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
