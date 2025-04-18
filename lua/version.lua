local GameType = "GAF"
local Commit = "GAF Balance"
local Version = "1.5"

function GetVersion()
    LOG(string.format('Supreme Commander: Forged Alliance Lua version %s at %s (%s)', Version, GameType, Commit))
    return Version
end

function GetVersionData()
    return Version, GameType, Commit
end
