-- Logic and defaults for launching non-skirmish sessions
local Prefs = import("/lua/user/prefs.lua")
local MapUtils = import("/lua/ui/maputil.lua")
local aiTypes = import("/lua/ui/lobby/aitypes.lua").aitypes
local ModUtils = import("/lua/mods.lua")

-- The engine doesn't log errors when the command line launch errors, so we fix that here. 
local function error(string)
    WARN(string.format('Error launching session: %s\n%s', string, debug.traceback()))
    _G.error(string)
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
--- Pass quiet=true to get nil instead of an error when it doesn't resolve.
---@param mapName FileName | string
---@param quiet? boolean
---@return FileName?
function FixupMapName(mapName, quiet)
    if (not string.find(mapName, "/")) and (not string.find(mapName, "\\")) then
        local files = DiskFindFiles('/maps', mapName .. '_scenario.lua')
        if files[1] then
            mapName = files[1]
        elseif quiet then
            return nil
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
            if quiet then
                return nil
            end
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
    TeamShareOverflow = 'enabled',
    Share = 'ShareUntilDeath',
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

-- Command line flag for diverting into a fully lua configured game run.
local configuredSessionCommandTrigger = '/autorun'

--- Called by the engine using the `/map <mapPath>` launch arg
---@param mapName FileName
---@param isPerfTest any
function StartCommandLineSession(mapName, isPerfTest)
    -- Fully divert into a lua scripted session on `/autorun <config>`. All
    -- other command line arguments are disregarded, `mapName` is just passed
    -- so a warning can be given if it doesn't match a config provided value.
    if HasCommandLineArg(configuredSessionCommandTrigger) then
        return StartConfiguredSession(mapName)
    end

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

---@param uiMods? string[]
---@param simMods? string[]
---@return table<string, boolean>
local function BuildModList(uiMods, simMods)
    local mods = {}
    if uiMods ~= nil then
        for _, uid in uiMods do
            mods[uid] = true
        end
    else
        local selectedUIMods = ModUtils.GetUiMods()
        for _, mod in selectedUIMods do
            mods[mod.uid] = true
        end
    end
    if simMods ~= nil then
        for _, uid in simMods do
            mods[uid] = true
        end
    else
        local selectedGameMods = ModUtils.GetGameMods()
        for _, mod in selectedGameMods do
            mods[mod.uid] = true
        end
    end
    return mods
end

--- Functions to call, in registration order, whenever an autorun session ends
--- because a configured game-time or real-time limit was reached.
--- table.insert into this directly to add a listener
AutorunOnSessionEndListeners = {}

--- End the session for `reason` (one of "maxGameTime" / "maxRealTime"), after
--- giving every AutorunOnSessionEndListeners entry a chance to observe it.
---@param reason string
---@param start number
local function EndSessionWithReason(reason, start)
    local gameTime = GetGameTimeSeconds()
    local realTime = GetSystemTimeSeconds() - start
    for _, listener in AutorunOnSessionEndListeners do
        listener(reason, gameTime, realTime)
    end
    SessionEndGame()
end

--- Waits for the session to actually start, then applies an optional game
--- speed and ends the session once a configured game-time and/or real-time
--- limit is reached. No-op if none of the three are set.
---@param targetSpeed? number
---@param maxGameSeconds? number
---@param maxRealSeconds? number
local function ApplySimOptions(targetSpeed, maxGameSeconds, maxRealSeconds)
    local N = 100
    local start = GetSystemTimeSeconds()
    while not WorldIsPlaying() do
        coroutine.yield(N)
    end
    coroutine.yield(N)
    if targetSpeed then
        LOG("Setting game speed to: ", targetSpeed)
        SetGameSpeed(targetSpeed)
    end
    if maxGameSeconds and maxRealSeconds then
        -- Limit on both game time and real time
        while (
            ((GetSystemTimeSeconds() - start) < maxRealSeconds) and
            (GetGameTimeSeconds() < maxGameSeconds)
        ) do
            coroutine.yield(N)
        end
        LOG("Maximum game or real time reached, exiting.")
        EndSessionWithReason(
            (GetGameTimeSeconds() >= maxGameSeconds) and "maxGameTime" or "maxRealTime",
            start
        )
    elseif (not maxGameSeconds) and maxRealSeconds then
        -- Only limit on real time
        while (GetSystemTimeSeconds() - start) < maxRealSeconds do
            coroutine.yield(N)
        end
        LOG("Maximum real time reached, exiting.")
        EndSessionWithReason("maxRealTime", start)
    elseif maxGameSeconds and (not maxRealSeconds) then
        -- Only limit on game time
        while GetGameTimeSeconds() < maxGameSeconds do
            coroutine.yield(N)
        end
        LOG("Maximum game time reached, exiting.")
        EndSessionWithReason("maxGameTime", start)
    end
    -- else: no time limits configured, nothing to do
end

--- Launch a full session configuration (map, scenario/session options, mods,
--- armies, script, time limits) from the Lua file given by `/autorun <configPath>`.
--- Lets a scripted/headless caller launch a fully specified single-player
--- session without going through the lobby UI.
---@param mapName FileName
function StartConfiguredSession(mapName)
    local configLocation = GetCommandLineArg(configuredSessionCommandTrigger, 1)[1]
    if not configLocation then
        error("No config location specified, check your "..configuredSessionCommandTrigger.." argument")
    end
    if string.sub(configLocation, 1, 1) ~= "/" then
        configLocation = "/config/"..configLocation
    end
    _ALERT("Loading game configuration from:", configLocation)
    local config = import(configLocation).config
    if not config then
        error("Config not found, please check the mounted "..configLocation.." file")
    end

    if config.mapName then
        local configMapName = FixupMapName(config.mapName)
        -- If the mapName appears to be valid on the command line then warn if
        -- it gets overridden by a config value.
        local cliMapName = FixupMapName(mapName, true)
        if cliMapName and cliMapName ~= configMapName then
            WARN("Command line provided map name (\""..mapName.."\") overridden by value from config (\""..configMapName.."\")")
        end
        mapName = configMapName
    else
        mapName = FixupMapName(mapName)
    end
    local scenario = MapUtils.LoadScenario(mapName)
    if not scenario then
        error("Unable to load map " .. mapName)
    end
    VerifyScenarioConfiguration(scenario)

    -- Same GameOptions defaults as a `/map`-launched session (defaultOptions,
    -- above), with values overridden where sepcified from the autorun config.
    -- Additional options can exist in the config, which are also set here.
    scenario.Options = table.copy(defaultOptions)
    for k, v in (config.scenario or {}) do
        scenario.Options[k] = v
    end

    if config.script then
        scenario.autorunScript = config.script
    end
    -- Arbitrary session-wide data (not tied to any one army), fetch in-game
    -- with AutorunGetGlobalData(). Per-army data (armyConfig.data, below) is
    -- the equivalent for one AI brain.
    scenario.autorunGlobalData = config.data
    scenario.autorunBrainData = {}

    local sessionInfo = {}
    sessionInfo.scenarioInfo = scenario
    sessionInfo.playerName = Prefs.GetFromCurrentProfile('Name') or 'Player'
    local sessionConfig = config.session or {}
    sessionInfo.createReplay = false
    if sessionConfig.createReplay ~= nil then
        sessionInfo.createReplay = sessionConfig.createReplay
    end
    sessionInfo.RandomSeed = sessionConfig.RandomSeed or Random()

    local modsConfig = config.mods or {}
    local mods = BuildModList(modsConfig.ui, modsConfig.sim)
    sessionInfo.scenarioMods = ModUtils.GetGameMods(mods)
    ModUtils.SetSelectedMods(mods)

    sessionInfo.teamInfo = {}
    local armies = scenario.Configurations.standard.teams[1].armies
    local numColors = table.getn(import("/lua/gamecolors.lua").GameColors.PlayerColors)
    local humanFound = false
    for _, armyConfig in config.armies do
        local armyIndex = armyConfig.spawn
        if (not armyIndex) or (armyIndex <= 0) or (armyIndex > table.getn(armies)) then
            error("Invalid army spawn "..tostring(armyIndex))
        end
        local armyName = armies[armyIndex]
        sessionInfo.teamInfo[armyIndex] = {}
        sessionInfo.teamInfo[armyIndex].ArmyName = armyName
        sessionInfo.teamInfo[armyIndex].Faction = armyConfig.faction or GetRandomFaction()
        sessionInfo.teamInfo[armyIndex].PlayerColor = armyConfig.colourIndex or math.mod(armyIndex, numColors)
        sessionInfo.teamInfo[armyIndex].ArmyColor = armyConfig.colourIndex or math.mod(armyIndex, numColors)
        if not armyConfig.aikey then
            sessionInfo.teamInfo[armyIndex].Human = true
            sessionInfo.playerName = armyConfig.name or sessionInfo.playerName
            sessionInfo.teamInfo[armyIndex].PlayerName = sessionInfo.playerName
            if humanFound then
                error("Only a single human can play per game")
            end
            humanFound = true
        else
            sessionInfo.teamInfo[armyIndex].AIPersonality = armyConfig.aikey
            sessionInfo.teamInfo[armyIndex].Human = false
            sessionInfo.teamInfo[armyIndex].PlayerName = armyConfig.name
                or GetRandomName(sessionInfo.teamInfo[armyIndex].Faction, sessionInfo.teamInfo[armyIndex].AIPersonality)
        end
        scenario.autorunBrainData[armyIndex] = armyConfig.data
    end

    local extras = MapUtils.GetExtraArmies(scenario)
    if extras then
        for _, armyName in extras do
            local index = table.getn(sessionInfo.teamInfo) + 1
            sessionInfo.teamInfo[index] = import("/lua/ui/lobby/lobbycomm.lua").GetDefaultPlayerOptions("civilian")
            sessionInfo.teamInfo[index].PlayerName = 'civilian'
            sessionInfo.teamInfo[index].Civilian = true
            sessionInfo.teamInfo[index].ArmyName = armyName
            sessionInfo.teamInfo[index].Human = false
        end
    end

    local sim = config.sim or {}
    if sim.targetSpeed or sim.maxGameSeconds or sim.maxRealSeconds then
        ForkThread(function()
            ApplySimOptions(sim.targetSpeed, sim.maxGameSeconds, sim.maxRealSeconds)
        end)
    end

    LaunchSinglePlayerSession(sessionInfo)
end
