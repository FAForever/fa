
local Version = "3761"
---@alias PATCH "3761"
---@alias VERSION "1.5.3761"
---@return PATCH
function GetVersion()
    LOG('Supreme Commander: Forged Alliance version ' .. Version)
    return Version
end
