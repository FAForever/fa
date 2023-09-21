--- Flattened version of `WatchedGameData` that can interact with the engine
---@class GameData
---@field AutoTeams number[]
---@field ClosedSlots boolean[]
---@field GameMods ModInfo[]
---@field GameOptions GameOptions
---@field Observers PlayerData[]
---@field PlayerOptions PlayerData[]
---@field SpawnMex boolean[]

--- Watched version of `GameData` that can easily change with the lobby
---@class WatchedGameData : GameData
---@field GameMods table<string, true>
---@field Observers WatchedValueArray<PlayerData>
---@field PlayerOptions WatchedValueArray<PlayerData>

local PlayerData = import("/lua/ui/lobby/data/playerdata.lua").PlayerData
local WatchedValueArray = import("/lua/ui/lobby/data/watchedvalue/watchedvaluearray.lua").WatchedValueArray

--- Represents the gameInfo object.
-- Not actually a WatchedValueTable, as we don't want to handle the situation when these values are
-- actually reassigned (it'd muck up our event listeners, for one thing).
-- Not actually a class to make the serialisation semantics less of a brainmush.

---@param maxPlayerSlots number
---@param initialValues? GameData
---@return WatchedGameData
function CreateGameInfo(maxPlayerSlots, initialValues)
    local gameInfo = {
        GameOptions = initialValues.GameOptions or {},
        PlayerOptions = WatchedValueArray(maxPlayerSlots),
        Observers = WatchedValueArray(maxPlayerSlots),
        ClosedSlots = initialValues.ClosedSlots or {},
        SpawnMex = initialValues.SpawnMex or {},
        GameMods = initialValues.GameMods or {},
        AutoTeams = initialValues.AutoTeams or {}, -- Why isn't this part of GameOptions?
    }

    if not initialValues then
        return gameInfo
    end

    -- Unflatten the PlayerOptions and Observers
    for k, v in initialValues.PlayerOptions do
        gameInfo.PlayerOptions[k] = PlayerData(v)
    end

    for k, v in initialValues.Observers do
        gameInfo.Observers[k] = PlayerData(v)
    end

    return gameInfo
end

--- Given a gameInfo object returned from CreateGameInfo, flatten it into a serialisable table.
---@param gameInfo WatchedGameData
---@return GameData
function Flatten(gameInfo)
    -- PlayerOptions is a WatchedValueArray<PlayerInfo>, so needs recursive flattening.
    local deeplyFlatPlayerOptions = {}
    for k, v in gameInfo.PlayerOptions:pairs() do
        if v ~= nil then
            deeplyFlatPlayerOptions[k] = v:AsTable()
        else
            deeplyFlatPlayerOptions[k] = nil
        end
    end

    local deeplyFlatObservers = {}
    for k, v in gameInfo.Observers:pairs() do
        if v ~= nil then
            deeplyFlatObservers[k] = v:AsTable()
        else
            deeplyFlatObservers[k] = nil
        end
    end

    return {
        GameOptions = gameInfo.GameOptions,
        PlayerOptions = deeplyFlatPlayerOptions,
        Observers = deeplyFlatObservers,
        ClosedSlots = gameInfo.ClosedSlots,
        SpawnMex = gameInfo.SpawnMex,
        GameMods = gameInfo.GameMods,
        AutoTeams = gameInfo.AutoTeams,
    }
end
