---@class PlayerData
---@field AIPersonality string
---@field ArmyColor number pulls from `PlayerColor`
---@field BadMap boolean
---@field Civilian boolean
---@field Country string | false
---@field DEV number
---@field Faction number
---@field Human boolean
---@field MEAN number
---@field NG number number of games
---@field ObserverListIndex number
---@field OwnerID number | false
---@field PL number player rating
---@field PlayerClan number
---@field PlayerColor number
---@field PlayerName string
---@field Ready boolean
---@field StartSpot number
---@field Team number


local WatchedValueTable = import("/lua/ui/lobby/data/watchedvalue/watchedvaluetable.lua").WatchedValueTable

-- The default values (and the only valid keyset) for a PlayerData object.
local DEFAULT_MAPPING = {
    Team = 1,
    -- Both PlayerColor and ArmyColor must be set for the game to start.
    -- This is retarded.
    PlayerColor = 1,
    ArmyColor = 1,
    StartSpot = 1,
    Ready = false,
    Faction = table.getn(import("/lua/factions.lua").Factions) + 1, -- Random faction
    PlayerClan = "",
    PlayerName = "player",
    AIPersonality = "",
    Human = true,
    Civilian = false,
    OwnerID = false,
    BadMap = false,
    ObserverListIndex = -1,

    -- Rating stuff. Perhaps wants its own table? Definitely wants renaming.
    MEAN = 0,
    DEV = 0,
    PL = 0,  -- Rating
    NG = 0,  -- Number of games.

    Country = false,
}

-- Represents player data using the magic of lazy variables.
---@class WatchedPlayerData : PlayerData, WatchedValueTable
PlayerData = ClassUI(WatchedValueTable) {
    -- Create a new PlayerData object for the given player name.
    __init = function(self, initialMapping)
        local mapping = table.assimilate(initialMapping, DEFAULT_MAPPING)
        mapping.ArmyColor = mapping.PlayerColor
        WatchedValueTable.__init(self, mapping)
    end
}
