--*****************************************************************************
--* File: lua/ui/lobby/aiutils.lua
--* Summary: AI type/option loading and AI player-data/rating helpers
--*          extracted from lobby.lua for maintainability.
--*****************************************************************************


-- Upvalues injected by lobby.lua via AIUtils.Init()
local gameInfo
local MapUtil
local LobbyComm
local hostID
local PlayerData
local IsColorFree
local GetAvailableColor

-- AI type tables owned by this module. Rebuilt by RefreshAITypes().
local aitypes
local AIKeys = {}
local AIStrings = {}
local AITooltips = {}

function Init(deps)
    gameInfo          = deps.gameInfo
    MapUtil           = deps.MapUtil
    LobbyComm         = deps.LobbyComm
    hostID            = deps.hostID
    PlayerData        = deps.PlayerData
    IsColorFree       = deps.IsColorFree
    GetAvailableColor = deps.GetAvailableColor
end

--- (Re)load the AI type tables from aitypes.lua.
-- Uveso - aitypes inside aitypes.lua are now also available as a function.
function RefreshAITypes()
    AIKeys = {}
    AIStrings = {}
    AITooltips = {}
    aitypes = import("/lua/ui/lobby/aitypes.lua").GetAItypes()
    for _, aidata in aitypes do
        table.insert(AIKeys, aidata.key)
        table.insert(AIStrings, aidata.name)
        table.insert(AITooltips, 'aitype_'..aidata.key)
    end
end

function GetKeys()
    return AIKeys
end

function GetStrings()
    return AIStrings
end

function GetTooltips()
    return AITooltips
end

--- Append AI lobby options contributed by sim mods to the given AIOpts table.
-- Mutates AIOpts in place; duplicate keys (already present) are skipped.
function ImportModAIOptions(AIOpts)
    local simMods = import("/lua/mods.lua").AllMods()
    local OptionData
    local alreadyStored
    for Index, ModData in simMods do
        if exists(ModData.location..'/lua/AI/LobbyOptions/lobbyoptions.lua') then
            OptionData = import(ModData.location..'/lua/AI/LobbyOptions/lobbyoptions.lua').AIOpts
            for s, t in OptionData do
                -- check, if we have this option already stored
                alreadyStored = false
                for k, v in AIOpts do
                    if v.key == t.key then
                        alreadyStored = true
                        break
                    end
                end
                if not alreadyStored then
                    table.insert(AIOpts, t)
                end
            end
        end
    end
end

--- Compute an estimation of the rating of the given AI. The values originate from 'aitypes.lua'
---@param gameOptions table
---@param aiLobbyProperties AILobbyProperties
---@return number
function ComputeAIRating(gameOptions, aiLobbyProperties)

    if not aiLobbyProperties then
        return 0
    end

    if not aiLobbyProperties.rating then
        return 0
    end

    if not gameInfo.GameOptions.ScenarioFile then
        return 0
    end

    -- try and take into account map
    local scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
    if not (scenarioInfo and scenarioInfo.size and scenarioInfo.size[1] and scenarioInfo.size[2]) then
        return 0
    end

    -- clamp the value
    local maparea = math.max(scenarioInfo.size[1], scenarioInfo.size[2])
    if maparea < 256 then
        maparea = 256
    elseif maparea > 4096 then
        maparea = 4096
    end

    -- process various multipliers to determine rating
    local mapMultiplier = aiLobbyProperties.ratingMapMultiplier[maparea] or 1.0
    local cheatBuildMultiplier = (tonumber(gameOptions.BuildMult) or 1.0) - 1.0
    local cheatResourceMultiplier = (tonumber(gameOptions.CheatMult) or 1.0) - 1.0

    -- compute the rating
    local cheatBuildValue = (aiLobbyProperties.ratingBuildMultiplier or 0.0) * cheatBuildMultiplier
    local cheatResourceValue = (aiLobbyProperties.ratingCheatMultiplier or 0.0) * cheatResourceMultiplier
    local cheatOmniValue = (gameOptions.OmniCheat == 'on' and aiLobbyProperties.ratingOmniBonus) or 0.0
    local rating = mapMultiplier * (aiLobbyProperties.rating + cheatBuildValue + cheatResourceValue + cheatOmniValue)

    -- prevent very low numbers
    if rating < aiLobbyProperties.ratingNegativeThreshold then
        rating = aiLobbyProperties.ratingNegativeThreshold + (rating - aiLobbyProperties.ratingNegativeThreshold) * 0.2
    end

    return math.floor(rating)
end

function GetAIPlayerData(name, AIPersonality, slot)
   local AIColor
   -- gets the color of the player/AI occupying the slot directly prior if available
    for i = 1, LobbyComm.maxPlayerSlots do
        if gameInfo.PlayerOptions[i].StartSpot == slot then
            if IsColorFree(gameInfo.PlayerOptions[i].PlayerColor, slot) then
                AIColor =  gameInfo.PlayerOptions[i].PlayerColor
            end
            break
        end
    end
    if not AIColor then
        AIColor = GetAvailableColor()
    end

    -- retrieve properties from AI table
    ---@type AILobbyProperties | nil
    local aiLobbyProperties = nil
    for k, entry in aitypes do
        if entry.key == AIPersonality then
            aiLobbyProperties = entry
        end
    end
    local iRating = ComputeAIRating(gameInfo.GameOptions, aiLobbyProperties)

    return PlayerData(
        {
            OwnerID = hostID,
            PlayerName = name,
            Ready = true,
            Human = false,
            AIPersonality = AIPersonality,
            PlayerColor = AIColor,
            ArmyColor = AIColor,

            PL = iRating,
            MEAN = iRating,
            DEV = 0,

            -- keep track of the AI lobby properties for easier access
            AILobbyProperties = aiLobbyProperties,
        }
)
end

