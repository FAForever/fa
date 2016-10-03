-- logic and defaults for launching non-skirmish sessions
local Prefs = import('/lua/user/prefs.lua')
local MapUtils = import('/lua/ui/maputil.lua')
local Factions = import('/lua/factions.lua').Factions
local PlayerColors = import('/lua/gameColors.lua').GameColors.PlayerColors
local GetDefaultPlayerOptions = import('/lua/ui/lobby/lobbyComm.lua').GetDefaultPlayerOptions

local CmdlineOptions = {
                            ai='ai', fog='FogOfWar', norush='NoRushOption', predeployed='PrebuiltUnits', victory='Victory', diff='Difficulty', seed='RandomSeed', perftest='PerfTest',
                            timeouts='Timeouts', speed='GameSpeed', tutorial='Tutorial'
                        }

local campaignOptions = {
    FogOfWar = 'explored',
    NoRushOption = 'Off',
    Difficulty = 2,
    Timeouts = -1,
    GameSpeed = 'normal',
    UnitCap = '1000',
}

local defaultOptions = {
    FogOfWar = 'explored',
    NoRushOption = 'Off',
    PrebuiltUnits = 'Off',
    Difficulty = 2,
    Timeouts = -1,
    GameSpeed = 'normal',
    UnitCap = '1000',
    Victory = 'sandbox',
    CheatsEnabled = 'true',
    CivilianAlliance = 'enemy',
}

function MapPath(mapName)
    if not string.find(mapName, "[/\\]") then
        mapName = string.format("/maps/%s/%s_scenario.lua", mapName, mapName)
    end

    return mapName
end

function GetFaction(faction)
    if not faction then
        return math.random(table.getn(Factions))
    else
        return faction
    end
end

function GetRandomName(faction, aiKey)
    local names = import('/lua/ui/lobby/ainames.lua').ainames[Factions[faction].Key]
    local name = names[math.random(table.getn(names))]

    if aiKey then
        local aiTypes = import('/lua/ui/lobby/aitypes.lua').aitypes
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


function SetupBotSession(mapName)
    if not mapName then
        error("SetupBotSession - mapName required")
    end

    local options = {map=mapName}

    local aiopt = GetCommandLineArg("/ai", 1)
    if aiopt then
        options.ai = aiopt[1] or 'rush'
    else
        aitypes = import('/lua/ui/lobby/aitypes.lua').aitypes
        options.ai = aitypes[1].key
    end

    return InitSessionInfo(options)
end

local function ParseCommandLineOptions(options)
    local v
    for c, k in CmdlineOptions do
        v = GetCommandLineArg('/' .. c, 1)
        if v then
            options[k] = v[1]
        end
    end

    local faction = GetCommandLineArg("/faction", 1)
    if faction then
        local n_factions = table.getsize(Factions)

        faction = tonumber(faction[1])
        if faction < 1 or faction > n_factions then
            error("SetupCommandLineSession - selected faction index " .. faction .. " must be between 1 and " .. n_factions)
        end
    else
        faction = GetFaction()
    end

    options.faction = faction

    return options
end

function InitOptions(sessionInfo, options)
    local o = {}
    if not options.campaign then
        o = table.copy(defaultOptions)
    else
        o = table.copy(campaignOptions)
    end

    for _, k in CmdlineOptions do
        o[k] = options[k] or o[k]
    end

    sessionInfo.scenarioInfo.Options = o

    if options.RandomSeed then
        sessionInfo.RandomSeed = options.RandomSeed
    end

    if options.campaign then
        if options.tutorial then
            sessionInfo.scenarioInfo.tutorial = true
        end

        sessionInfo.scenarioInfo.campaignInfo = options.campaignFlowInfo
        sessionInfo.scenarioInfo.Options.FACampaignFaction = Factions[options.faction].Key
    end
end

local function InitTeamInfo(sessionInfo, options)
    local teamInfo = {}
    local armies = sessionInfo.scenarioInfo.Configurations.standard.teams[1].armies
    local n_armies = table.getsize(armies)
    local extras =  MapUtils.GetExtraArmies(sessionInfo.scenarioInfo)
    local n_colors = table.getsize(PlayerColors)

    local team
    for i, name in table.concatenate(armies, extras or {}) do
        team = GetDefaultPlayerOptions()
        team.ArmyName = name
        team.PlayerColor = math.mod(i, n_colors)

        team.ArmyColor = math.mod(i, n_colors)
        team.Human = false

        if i == 1 then
            team.Human = true
            team.PlayerName = sessionInfo.playerName
            team.Faction=GetFaction(options.faction)


        elseif i <= n_armies then
            team.Faction = GetFaction()
            if options.ai and not options.campaign then
                team.AIPersonality = options.ai
                team.PlayerName = GetRandomName(team.Faction, team.AIPersonality)
            else
                team.PlayerName = name
            end
        else
            team.PlayerName = 'civilian'
            team.Civilian = true
        end

        teamInfo[i] = team
        if not (options.ai or options.campaign) then -- play without other players
            break
        end
    end

    sessionInfo.teamInfo = teamInfo
end

local function InitSessionInfo(options)
    local sessionInfo = {teamInfo={}, playerName=Prefs.GetFromCurrentProfile('Name') or 'Player', createReplay=false}
    if options.scenario then
        sessionInfo.scenarioInfo = options.scenario
    else
        local filename = MapPath(options.map or 'scmp_009')
        sessionInfo.scenarioInfo = MapUtils.LoadScenario(filename)
    end

    if not sessionInfo.scenarioInfo then
        error("Unable to load map " .. mapName)
    end

    VerifyScenarioConfiguration(sessionInfo.scenarioInfo)
    sessionInfo.scenarioMods = import('/lua/mods.lua').GetCampaignMods(sessionInfo.scenarioInfo)

    ParseCommandLineOptions(options)
    InitOptions(sessionInfo, options)
    InitTeamInfo(sessionInfo, options)

    return sessionInfo
end


function SetupCampaignSession(scenario, difficulty, inFaction, campaignFlowInfo, isTutorial)
    local options = {
                        scenario=scenario, diff=difficulty, faction=inFaction or 1,
                        campaignFlowInfo=campaignFlowInfo, tutorial=isTutorial,
                        campaign=true, speed='normal', timeouts='-1'
                    }

   local sessionInfo = InitSessionInfo(options)
   return sessionInfo
end

local function SetupCommandLineSkirmish(scenario, isPerfTest)
    local options = {map=scenario, perftest=isPerfTest}
    return InitSessionInfo(options)
end

function StartCommandLineSession(mapName, isPerfTest)
    local options = {map=mapName, perftest=isPerfTest}
    sessionInfo = InitSessionInfo(options)
    Prefs.SetToCurrentProfile('LoadingFaction', options.faction)
    LaunchSinglePlayerSession(sessionInfo)
end
