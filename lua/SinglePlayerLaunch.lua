-- Logic and defaults for launching non-skirmish sessions
local Prefs = import("/lua/user/prefs.lua")
local MapUtils = import("/lua/ui/maputil.lua")
local aiTypes = import("/lua/ui/lobby/aitypes.lua").aitypes

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

function GetRandomFaction()
    return math.random(table.getn(import("/lua/factions.lua").Factions))
end

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




function FixupMapName(mapName)
    if (not string.find(mapName, "/")) and (not string.find(mapName, "\\")) then
        mapName = "/maps/" .. mapName .. "/" .. mapName .. "_scenario.lua"
    end
    return mapName
end


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

local function GetCommandLineOptions(isPerfTest)
    local options = table.copy(defaultOptions)

    if isPerfTest then
        options.FogOfWar = 'none'
    elseif HasCommandLineArg("/nofog") then
        options.FogOfWar = 'none'
    end

    local norush = GetCommandLineArg("/norush", 1)
    if norush then
        options.NoRushOption = norush[1]
    end

    if HasCommandLineArg("/predeployed") then
        options.PrebuiltUnits = 'On'
    end

    local victory = GetCommandLineArg("/victory", 1)
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
        ai = aitypes[1].key
    end

    LOG('ai=' .. repr(ai))

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

    local armies = sessionInfo.scenarioInfo.Configurations.standard.teams[1].armies

    local numColors = table.getn(import("/lua/gamecolors.lua").GameColors.PlayerColors)

    for index, name in armies do
        sessionInfo.teamInfo[index] = import("/lua/ui/lobby/lobbycomm.lua").GetDefaultPlayerOptions(sessionInfo.playerName)
        if index == 1 then
            sessionInfo.teamInfo[index].PlayerName = sessionInfo.playerName
            sessionInfo.teamInfo[index].Faction = faction
            sessionInfo.teamInfo[index].Human = true
        else
            sessionInfo.teamInfo[index].AIPersonality = 'rush'
            sessionInfo.teamInfo[index].Faction = GetRandomFaction()
            sessionInfo.teamInfo[index].PlayerName = GetRandomName(sessionInfo.teamInfo[index].Faction, sessionInfo.teamInfo[index].AIPersonality)
            sessionInfo.teamInfo[index].Human = false
        end
        sessionInfo.teamInfo[index].ArmyName = name
        sessionInfo.teamInfo[index].PlayerColor = math.mod(index, numColors)
        sessionInfo.teamInfo[index].ArmyColor = math.mod(index, numColors)
    end

    local extras = MapUtils.GetExtraArmies(sessionInfo.scenarioInfo)
    if extras then
        for k,armyName in extras do
            local index = table.getn(sessionInfo.teamInfo) + 1
            sessionInfo.teamInfo[index] = import("/lua/ui/lobby/lobbycomm.lua").GetDefaultPlayerOptions("civilian")
            sessionInfo.teamInfo[index].PlayerName = 'civilian'
            sessionInfo.teamInfo[index].Civilian = true
            sessionInfo.teamInfo[index].ArmyName = armyName
            sessionInfo.teamInfo[index].Human = false
        end
    end

    Prefs.SetToCurrentProfile('LoadingFaction', faction)

    return sessionInfo
end

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
            difficulty = tonumber(GetCommandLineArg("/diff", 1)[1])
        end
        local faction = false
        if HasCommandLineArg("/faction") then
            faction = GetCommandLineArg("/faction", 1)[1]
        end
        sessionInfo = SetupCampaignSession(scenario, difficulty, faction)
    else
        sessionInfo = SetupCommandLineSkirmish(scenario, isPerfTest)
    end
    LaunchSinglePlayerSession(sessionInfo)
end
