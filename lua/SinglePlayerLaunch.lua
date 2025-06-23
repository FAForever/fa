-- Logic and defaults for launching non-skirmish sessions
local Prefs = import("/lua/user/prefs.lua")
local MapUtils = import("/lua/ui/maputil.lua")
local aiTypes = import("/lua/ui/lobby/aitypes.lua").aitypes

local error = function(string)
    WARN(string.format('Error launching session: %s\n%s', string, debug.traceback()))
    error(string)
end

---@param faction integer
---@param aiKey string
---@return LocalizedString
function GetRandomName(faction, aiKey)
    WARN('GRN: ',faction)
    local aiNames = import("/lua/ui/lobby/ainames.lua").ainames
    local factions = import("/lua/factions.lua").Factions

    faction = faction or (math.random(table.getn(factions)))

    local name = aiNames[factions[faction].Key][math.random(table.getn(aiNames[factions[faction].Key]))]

    if aiKey then
        local aiName = "AI"
        for index, value in aiTypes do
            if aiKey == value.key then
                aiName = value.name
            end
        end
        name = name .. " (" .. LOC(aiName) .. ")"
    end

    return name
end

---@return integer
function GetRandomFaction()
    return math.random(table.getn(import("/lua/factions.lua").Factions))--[[@as integer]]
end

---@param scenarioInfo UIScenarioInfoFile
function VerifyScenarioConfiguration(scenarioInfo)
    if scenarioInfo == nil then
        error("VerifyScenarioConfiguration - no scenarioInfo")
    end

    if scenarioInfo.Configurations == nil or scenarioInfo.Configurations.standard == nil or scenarioInfo.Configurations.standard.teams == nil then
        error("VerifyScenarioConfiguration - scenarios require the standard team configuration")
    end

    if scenarioInfo.Configurations.standard.teams[1].name ~= 'FFA' then
        error("VerifyScenarioConfiguration - scenarios require all teams be set up as FFA")
    end

    if scenarioInfo.Configurations.standard.teams[1].armies == nil then
        error("VerifyScenarioConfiguration - scenarios require at least one army")
    end
end



-- Note that the map name must include the full path, it won't try to guess the path based on name
---@param scenario UILobbyScenarioInfo
---@param difficulty integer
---@param inFaction? Faction
---@param campaignFlowInfo? table
---@param isTutorial? boolean
---@return table
function SetupCampaignSession(scenario, difficulty, inFaction, campaignFlowInfo, isTutorial)
    local factions = import("/lua/factions.lua").Factions
    local faction = inFaction or 1
    if not scenario then
        error("SetupCampaignSession - scenario required")
    end
    VerifyScenarioConfiguration(scenario)

    if not difficulty then
        error("SetupCampaignSession - difficulty required")
    end

    local sessionInfo = {}

    sessionInfo.playerName = Prefs.GetFromCurrentProfile('Name') or 'Player'
    sessionInfo.createReplay = false
    sessionInfo.scenarioInfo = scenario

    local armies = sessionInfo.scenarioInfo.Configurations.standard.teams[1].armies

    sessionInfo.teamInfo = {}

    for index, name in armies do
        sessionInfo.teamInfo[index] = import("/lua/ui/lobby/lobbycomm.lua").GetDefaultPlayerOptions(sessionInfo.playerName)
        if index == 1 then
            sessionInfo.teamInfo[index].PlayerName = sessionInfo.playerName
            sessionInfo.teamInfo[index].Faction = faction
        else
            sessionInfo.teamInfo[index].PlayerName = name
            sessionInfo.teamInfo[index].Human = false
            sessionInfo.teamInfo[index].Faction = 1
        end
        sessionInfo.teamInfo[index].ArmyName = name
    end

    sessionInfo.scenarioInfo.Options = {}
    sessionInfo.scenarioInfo.Options.FogOfWar = 'explored'
    sessionInfo.scenarioInfo.Options.Difficulty = difficulty
    sessionInfo.scenarioInfo.Options.DoNotShareUnitCap = true
    sessionInfo.scenarioInfo.Options.Timeouts = -1
    sessionInfo.scenarioInfo.Options.GameSpeed = 'normal'
    sessionInfo.scenarioInfo.Options.FACampaignFaction = factions[faction].Key
    -- Copy campaign flow information for the front end to use when ending the game
    -- or when restoring from a saved game
    if campaignFlowInfo then
        sessionInfo.scenarioInfo.campaignInfo = campaignFlowInfo
    end

    if isTutorial and (isTutorial == true) then
        sessionInfo.scenarioInfo.tutorial = true
    end

    Prefs.SetToCurrentProfile('LoadingFaction', faction)

    sessionInfo.scenarioMods = import("/lua/mods.lua").GetCampaignMods(sessionInfo.scenarioInfo)
    LOG('sessioninfo: ', repr(sessionInfo.teamInfo))
    return sessionInfo
end


--- Gets the scenario file from a map name if it isn't a scenario file already.
---@param mapName FileName | string
---@return FileName
function FixupMapName(mapName)
    if (not string.find(mapName, "/")) and (not string.find(mapName, "\\")) then
        local files = DiskFindFiles('/maps', mapName .. '_scenario.lua')
        if files[1] then
            mapName = files[1]
        else
            error('Could not find scenario file for map name "' .. mapName .. '"')
        end
    else
        -- FAF map folders are versioned but the engine doesn't expect that.
        -- So when the user passes in a name instead of a path the engine gives us what it thinks
        -- is the correct scenario path `"/maps/<name.v0001>/<name.v0001>_scenario.lua"`
        -- So we remove the versioning from the scenario file name.
        -- There should really be some map util to do this.

        mapName = string.gsub(mapName, ".v%d%d%d%d_scenario.lua", "_scenario.lua")
        local info = DiskGetFileInfo(mapName)
        if not info then
            error('Map scenario file does not exist at location "' .. mapName .. '"')
        end
    end
    ---@cast mapName FileName
    return mapName
end

---@type GameOptions
local defaultOptions = {
    FogOfWar = 'explored',
    NoRushOption = 'Off',
    PrebuiltUnits = 'Off',
    Difficulty = 2,
    DoNotShareUnitCap = true,
    Timeouts = -1,
    GameSpeed = 'normal',
    UnitCap = '500',
    Victory = 'sandbox',
    CheatsEnabled = 'true',
    CivilianAlliance = 'enemy',
}

--- Gets the game options with changes from the command line args:
--- - `/nofog`
--- - `/norush <duration>`
--- - `/predeployed`
--- - `/victory <VictoryCondition>`
--- - `/diff <Difficulty>`
---@param isPerfTest boolean
---@return GameOptions
local function GetCommandLineOptions(isPerfTest)
    local options = table.copy(defaultOptions)

    if isPerfTest then
        options.FogOfWar = 'none'
    elseif HasCommandLineArg("/nofog") then
        options.FogOfWar = 'none'
    end

    local norush = GetCommandLineArg("/norush", 1) --[[@as number|string?[] ]]
    if norush then
        options.NoRushOption = norush[1]
    end

    if HasCommandLineArg("/predeployed") then
        options.PrebuiltUnits = 'On'
    end

    local victory = GetCommandLineArg("/victory", 1) --[[@as string?[] ]]
    if victory then
        options.Victory = victory[1]
    end

    local diff = GetCommandLineArg("/diff", 1)
    if diff then
        options.Difficulty = tonumber(diff[1])
    end

    return options
end


function SetupBotSession(mapName)
    if not mapName then
        error("SetupBotSession - mapName required")
    end

    mapName = FixupMapName(mapName)

    local sessionInfo = {}

    sessionInfo.playerName = Prefs.GetFromCurrentProfile('Name') or 'Player'
    sessionInfo.createReplay = false

    sessionInfo.scenarioInfo = import("/lua/ui/maputil.lua").LoadScenario(mapName)
    if not sessionInfo.scenarioInfo then
        error("Unable to load map " .. mapName)
    end

    VerifyScenarioConfiguration(sessionInfo.scenarioInfo)

    local armies = sessionInfo.scenarioInfo.Configurations.standard.teams[1].armies

    sessionInfo.teamInfo = {}

    local numColors = table.getn(import("/lua/gamecolors.lua").GameColors.PlayerColors)

    local ai
    local aiopt = GetCommandLineArg("/ai", 1)
    if aiopt then
        ai = aiopt[1]
    else
        ai = aiTypes[1].key
    end

    for index, name in armies do
        sessionInfo.teamInfo[index] = import("/lua/ui/lobby/lobbycomm.lua").GetDefaultPlayerOptions(sessionInfo.playerName)
        sessionInfo.teamInfo[index].PlayerName = name
        sessionInfo.teamInfo[index].ArmyName = name
        sessionInfo.teamInfo[index].Faction = GetRandomFaction()
        sessionInfo.teamInfo[index].Human = false
        sessionInfo.teamInfo[index].PlayerColor = math.mod(index, numColors)
        sessionInfo.teamInfo[index].ArmyColor = math.mod(index, numColors)
        sessionInfo.teamInfo[index].AIPersonality = ai
    end

    sessionInfo.scenarioInfo.Options = GetCommandLineOptions(false)
    sessionInfo.scenarioMods = import("/lua/mods.lua").GetCampaignMods(sessionInfo.scenarioInfo)

    local seed = GetCommandLineArg("/seed", 1)
    if seed then
        sessionInfo.RandomSeed = tonumber(seed[1])
    end

    return sessionInfo
end


local function SetupCommandLineSkirmish(scenario, isPerfTest)

    local faction
    if HasCommandLineArg("/faction") then
        faction = tonumber(GetCommandLineArg("/faction", 1)[1])
        local maxFaction = table.getn(import("/lua/factions.lua").Factions)
        if faction < 1 or faction > maxFaction then
            error("SetupCommandLineSession - selected faction index " .. faction .. " must be between 1 and " ..  maxFaction)
        end
    else
        faction = GetRandomFaction()
    end

    VerifyScenarioConfiguration(scenario)

    scenario.Options = GetCommandLineOptions(isPerfTest)

    sessionInfo = { }
    sessionInfo.playerName = Prefs.GetFromCurrentProfile('Name') or 'Player'
    sessionInfo.createReplay = true
    sessionInfo.scenarioInfo = scenario
    sessionInfo.teamInfo = {}
    sessionInfo.scenarioMods = import("/lua/mods.lua").GetCampaignMods(scenario)

    local seed = GetCommandLineArg("/seed", 1)
    if seed then
        sessionInfo.RandomSeed = tonumber(seed[1])
    elseif isPerfTest then
        sessionInfo.RandomSeed = 2071971
    end

    local GetDefaultPlayerOptions = import("/lua/ui/lobby/lobbycomm.lua").GetDefaultPlayerOptions
    local armies = sessionInfo.scenarioInfo.Configurations.standard.teams[1].armies
    local numColors = table.getn(import("/lua/gamecolors.lua").GameColors.PlayerColors)

    local playerOptions = GetDefaultPlayerOptions(sessionInfo.playerName)
    playerOptions.PlayerName = sessionInfo.playerName
    playerOptions.Faction = faction
    playerOptions.Human = true
    playerOptions.ArmyName = armies[1]
    playerOptions.PlayerColor = math.mod(1, numColors)
    playerOptions.ArmyColor = math.mod(1, numColors)
    sessionInfo.teamInfo[1] = playerOptions

    if not HasCommandLineArg("/noAi") then
        local name
        for index = 2, table.getn(armies) do
            name = armies[index]
            local aiOptions = GetDefaultPlayerOptions(sessionInfo.playerName)
            aiOptions.AIPersonality = 'rush'
            aiOptions.Faction = GetRandomFaction()
            aiOptions.PlayerName = GetRandomName(aiOptions.Faction, aiOptions.AIPersonality)
            aiOptions.Human = false
            aiOptions.ArmyName = name
            aiOptions.PlayerColor = math.mod(index, numColors)
            aiOptions.ArmyColor = math.mod(index, numColors)
            sessionInfo.teamInfo[index] = aiOptions
        end
    end

    local extras = MapUtils.GetExtraArmies(sessionInfo.scenarioInfo)
    if extras then
        for k,armyName in extras do
            local index = table.getn(sessionInfo.teamInfo) + 1
            sessionInfo.teamInfo[index] = GetDefaultPlayerOptions("civilian")
            sessionInfo.teamInfo[index].PlayerName = 'civilian'
            sessionInfo.teamInfo[index].Civilian = true
            sessionInfo.teamInfo[index].ArmyName = armyName
            sessionInfo.teamInfo[index].Human = false
        end
    end

    local index = table.getn(sessionInfo.teamInfo) + 1
    local enemyCivOptions = GetDefaultPlayerOptions("Civilian")
    enemyCivOptions = GetDefaultPlayerOptions("Civilian")
    enemyCivOptions.Civilian = true
    enemyCivOptions.ArmyName = 'ARMY_17'
    enemyCivOptions.Human = false
    sessionInfo.teamInfo[index] = enemyCivOptions
    index = index + 1
    local neutralCivOptions = GetDefaultPlayerOptions("Civilian")
    neutralCivOptions.Civilian = true
    neutralCivOptions.ArmyName = 'NEUTRAL_CIVILIAN'
    neutralCivOptions.Human = false
    sessionInfo.teamInfo[index] = neutralCivOptions

    Prefs.SetToCurrentProfile('LoadingFaction', faction)

    return sessionInfo
end

--- Called by the engine using the `/map <mapPath>` launch arg
---@param mapName FileName
---@param isPerfTest any
function StartCommandLineSession(mapName, isPerfTest)
    if not mapName then
        error("SetupCommandLineSession - mapName required")
    end

    mapName = FixupMapName(mapName)

    local scenario = import("/lua/ui/maputil.lua").LoadScenario(mapName)
    if not scenario then
        error("Unable to load map " .. mapName)
    end

    local sessionInfo
    if scenario.type == 'campaign' then
        local difficulty = 2
        if HasCommandLineArg("/diff") then
            difficulty = tonumber(GetCommandLineArg("/diff", 1)[1])--[[@as integer]]
        end
        ---@type Faction
        local faction = false
        if HasCommandLineArg("/faction") then
            faction = GetCommandLineArg("/faction", 1)[1]--[[@as integer]]
        end
        sessionInfo = SetupCampaignSession(scenario, difficulty, faction)
    else
        sessionInfo = SetupCommandLineSkirmish(scenario, isPerfTest)
    end
    LaunchSinglePlayerSession(sessionInfo)
end
