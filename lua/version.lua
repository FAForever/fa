local GameType = "GAF"

local Commit = "GAF Balance"

local Version = "2"
---@alias PATCH "2"
---@alias VERSION "2"
---@return PATCH
function GetVersion()
    LOG(string.format('Supreme Commander: Forged Alliance Lua version %s at %s (%s)', Version, GameType, Commit))
    return Version
end

---@return PATCH
---@return string # game type
---@return string # commit hash
function GetVersionData()
    return Version, GameType, Commit
end
