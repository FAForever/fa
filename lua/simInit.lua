-- ==========================================================================================
-- * File       : lua/simInit.lua
-- * Authors    : Gas Powered Games, FAF Community, HUSSAR
-- * Summary    : This is the sim-specific top-level lua initialization file. It is run at initialization time to set up all lua state for the sim.
-- * Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ==========================================================================================
-- Initialization order within the sim:
--   1. __blueprints is filled in from preloaded data
--   2. simInit.lua [this file] runs. It sets up infrastructure necessary to make Lua classes work etc.
--   if starting a new session:
--     3a. ScenarioInfo is setup with info about the scenario
--     4a. SetupSession() is called
--     5a. Armies, brains, recon databases, and other underlying game facilities are created
--     6a. BeginSession() is called, which loads the actual scenario data and starts the game
--   otherwise (loading a old session):
--     3b. The saved lua state is deserialized
-- ==========================================================================================

doscript '/lua/globalInit.lua'

-- Do global initialization and set up common global functions
local tableShuffle = table.shuffle
local unitsrestrictionsUp = import('/lua/ui/lobby/UnitsRestrictions.lua')
local entityUp = import('/lua/sim/Entity.lua')
local tableFind = table.find
local doscript = doscript
local CPrefetchSetUpdate = moho.CPrefetchSet.Update
local DiskFindFiles = DiskFindFiles
local tableInsert = table.insert
local ipairs = ipairs
local scenarioutilitiesUp = import('/lua/sim/ScenarioUtilities.lua')
local tablePrint = table.print
local CreateEmitterAtBone = CreateEmitterAtBone
local GetGameTimeSeconds = GetGameTimeSeconds
local categoryutilsUp = import('/lua/sim/Categoryutils.lua')
local SetAlliance = SetAlliance
local InitializeArmyAI = InitializeArmyAI
local GetFocusArmy = GetFocusArmy
local IsGameOver = IsGameOver
local effecttemplatesUp = import ('/lua/EffectTemplates.lua')
local AddBuildRestriction = AddBuildRestriction
local ArmyInitializePrebuiltUnits = ArmyInitializePrebuiltUnits
local ForkThread = ForkThread
local OrientFromDir = OrientFromDir
local next = next
local tableEmpty = table.empty
local mathMax = math.max
local Warp = Warp
local tableGetn = table.getn
local mathFloor = math.floor
local stringFormat = string.format
local LOG = LOG
local CreatePrefetchSet = CreatePrefetchSet
local lobbyoptionsUp = import('/lua/ui/lobby/lobbyOptions.lua')
local SPEW = SPEW

WaitTicks = coroutine.yield

function WaitSeconds(n)
    local ticks = mathMax(1, n * 10)
    if ticks > 1 then
        ticks = ticks + 1
    end
    WaitTicks(ticks)
end

-- Set up the sync table and some globals for use by scenario functions
doscript '/lua/SimSync.lua'

local syncStartPositions = false -- This is held here because the Sync table is cleared between SetupSession() and BeginSession()

function ShuffleStartPositions(syncNewPositions)
    local markers = ScenarioInfo.Env.Scenario.MasterChain._MASTERCHAIN_.Markers
    local positionGroups = ScenarioInfo.Options.RandomPositionGroups
    local positions = {}
    if not positionGroups then
        return
    end

    for _, group in positionGroups do
        for _, num in group do
            local name = 'ARMY_' .. num
            local marker = markers[name]
            if marker and marker.position then
                positions[num] = {pos = marker.position, name = name}
            end
        end

        local shuffledGroup = tableShuffle(group)
        for i = 1, tableGetn(group) do
            local pos = positions[shuffledGroup[i]].pos
            local name = positions[group[i]].name
            if pos and markers[name] then
                markers[name].position = pos

                if syncNewPositions then
                    syncStartPositions[name] = pos
                end
            end
        end
    end
end

--SetupSession will be called by the engine after ScenarioInfo is set
--but before any armies are created.
function SetupSession()

    -- assume there are no AIs
    ScenarioInfo.GameHasAIs = false

    -- if the AI replacement is on then there may be AIs
    if ScenarioInfo.Options.AIReplacement == 'On' then 
        ScenarioInfo.GameHasAIs = true 
        SPEW("Detected ai replacement option being enabled: enabling AI functionality")
    end

    -- if we're doing a campaign / special map then there may be AIs
    if ScenarioInfo.type ~= 'skirmish' then 
        ScenarioInfo.GameHasAIs = true 
        SPEW("Detected a non-skirmish type map: enabling AI functionality")
    end

    -- if the map maker explicitly tells us
    if ScenarioInfo.requiresAiFunctionality then 
        ScenarioInfo.GameHasAIs = true 
        SPEW("Detected the 'requiresAiFunctionality' field set by the map: enabling AI functionality")
    end

    -- LOG('SetupSession: ', repr(ScenarioInfo))

    ArmyBrains = {}
    
    -- ScenarioInfo is a table filled in by the engine with fields from the _scenario.lua
    -- file we're using for this game. We use it to store additional global information
    -- needed by our scenario.
    ScenarioInfo.PlatoonHandles = {}
    ScenarioInfo.UnitGroups = {}
    ScenarioInfo.UnitNames = {}

    ScenarioInfo.VarTable = {}
    ScenarioInfo.OSPlatoonCounter = {}
    ScenarioInfo.BuilderTable = { Air = {}, Land = {}, Sea = {}, Gate = {} }
    ScenarioInfo.BuilderTable.AddedPlans = {}
    ScenarioInfo.MapData = { PathingTable = { Amphibious = {}, Water = {}, Land = {}, }, IslandData = {} }

    -- ScenarioInfo.Env is the environment that the save file and scenario script file
    -- are loaded into. We set it up here with some default functions that can be accessed
    -- from the scenario script.
    ScenarioInfo.Env = import('/lua/scenarioEnvironment.lua')

    --Check if ShareOption is valid, and if not then set it to ShareUntilDeath
    local shareOption = ScenarioInfo.Options.Share
    local globalOptions = lobbyoptionsUp.globalOpts
    local shareOptions = {}
    for _,globalOption in globalOptions do
        if globalOption.key == 'Share' then
            for _,value in globalOption.values do
                shareOptions[value.key] = true
            end
            break
        end
    end
    if not shareOptions[shareOption] then
        ScenarioInfo.Options.Share = 'ShareUntilDeath'
    end

    -- if build/enhancement restrictions chosen, set them up
    local buildRestrictions, enhRestrictions = nil, {}

    local restrictions = ScenarioInfo.Options.RestrictedCategories
    if restrictions then
        tablePrint(restrictions, 'RestrictedCategories')
        local presets = unitsrestrictionsUp.GetPresetsData()
        for index, restriction in restrictions do

            local preset = presets[restriction]
            if not preset then -- custom restriction
                LOG('restriction.custom: "'.. restriction ..'"')

                -- using hash table because it is faster to check for restrictions later in game
                enhRestrictions[restriction] = true

                if buildRestrictions then
                    buildRestrictions = buildRestrictions .. " + (" .. restriction .. ")"
                else
                    buildRestrictions = "(" .. restriction .. ")"
                end
            else -- preset restriction
                if preset.categories then
                    LOG('restriction.preset "'.. preset.categories .. '"')
                    if buildRestrictions then
                        buildRestrictions = buildRestrictions .. " + (" .. preset.categories .. ")"
                    else
                        buildRestrictions = "(" .. preset.categories .. ")"
                    end
                end
                if preset.enhancements then
                    LOG('restriction.enhancement "'.. restriction .. '"')
                    tablePrint(preset.enhancements, 'restriction.enhancements ')
                    for _, enhancement in preset.enhancements do
                        enhRestrictions[enhancement] = true
                    end
                end
            end
        end
    end

    if buildRestrictions then
        LOG('restriction.build '.. buildRestrictions)
        buildRestrictions = categoryutilsUp.ParseEntityCategoryProperly(buildRestrictions)
        -- add global build restrictions for all armies
        import('/lua/game.lua').AddRestriction(buildRestrictions)
        ScenarioInfo.BuildRestrictions = buildRestrictions
    end

    if not tableEmpty(enhRestrictions) then
        --table.print(enhRestrictions, 'enhRestrictions ')
        import('/lua/enhancementcommon.lua').RestrictList(enhRestrictions)
    end

    -- Loads the scenario saves and script files
    -- The save file creates a table named "Scenario" in ScenarioInfo.Env,
    -- containing most of the save data. We'll copy it up to a top-level global.
    LOG('Loading save file: ',ScenarioInfo.save)
    doscript('/lua/dataInit.lua')
    doscript(ScenarioInfo.save, ScenarioInfo.Env)

    Scenario = ScenarioInfo.Env.Scenario

    local spawn = ScenarioInfo.Options.TeamSpawn
    if spawn and tableFind({'random_reveal', 'balanced_reveal', 'balanced_flex_reveal'}, spawn) then
        -- Shuffles positions like normal but syncs the new positions to the UI
        syncStartPositions = {}
        ShuffleStartPositions(true)
    elseif spawn and tableFind({'random', 'balanced', 'balanced_flex'}, spawn) then
        -- Prevents players from knowing start positions at start
        ShuffleStartPositions(false)
    end

    LOG('Loading script file: ', ScenarioInfo.script)
    doscript(ScenarioInfo.script, ScenarioInfo.Env)

    -- Preloads AI templates from AI mods
    AIModTemplatesPreloader()

    ResetSyncTable()
end

-- OnCreateArmyBrain() is called by then engine as the brains are created, and we
-- use it to store off various useful bits of info.
-- The global variable "ArmyBrains" contains an array of AI brains, one for each army.
function OnCreateArmyBrain(index, brain, name, nickname)
    --LOG(string.format("OnCreateArmyBrain %d %s %s",index,name,nickname))
    ArmyBrains[index] = brain
    ArmyBrains[index].Name = name
    ArmyBrains[index].Nickname = nickname
    ScenarioInfo.PlatoonHandles[index] = {}
    ScenarioInfo.UnitGroups[index] = {}
    ScenarioInfo.UnitNames[index] = {}

    InitializeArmyAI(name)

    -- Add build restrictions to the army, if any are configured.
    if ScenarioInfo.BuildRestrictions then
        AddBuildRestriction(index, ScenarioInfo.BuildRestrictions)
    end

    -- check if this brain is an active AI by checking its type and whether 
    -- skirmish systems are setup (prevents detecting NEUTRAL_CIVILIAN or ARMY_17)
    local brainType = brain.BrainType 
    local brainSkirmishSystems = brain.SkirmishSystems 
    if brainType == 'AI' and brainSkirmishSystems then 
        ScenarioInfo.GameHasAIs = true
        SPEW("Detected an AI with skirmish systems: " .. brain.Name .. ", enabling AI functionality") 
    end
end

function InitializePrebuiltUnits(name)
    ArmyInitializePrebuiltUnits(name)
end

-- BeginSession will be called by the engine after the armies are created (but without
-- any units yet) and we're ready to start the game. It's responsible for setting up
-- the initial units and any other gameplay state we need.
function BeginSession()
    SPEW('Active mods in sim: ', repr(__active_mods))

    GameOverListeners = {}
    ForkThread(function()
        while not IsGameOver() do
            WaitTicks(1)
        end
        for _, v in GameOverListeners do
            v()
        end
    end)

    ForkThread(GameTimeLogger)
    local focusarmy = GetFocusArmy()
    if focusarmy>=0 and ArmyBrains[focusarmy] then
        LocGlobals.PlayerName = ArmyBrains[focusarmy].Nickname
    end

    -- Pass ScenarioInfo into OnPopulate() and OnStart() for backwards compatibility
    ScenarioInfo.Env.OnPopulate(ScenarioInfo)
    ScenarioInfo.Env.OnStart(ScenarioInfo)

    -- Look for teams
    local teams = {}
    for name,army in ScenarioInfo.ArmySetup do
        if army.Team > 1 then
            if not teams[army.Team] then
                teams[army.Team] = {}
            end
            tableInsert(teams[army.Team],army.ArmyIndex)
        end
    end

    if ScenarioInfo.Options.TeamLock == 'locked' then
        -- Specify that the teams are locked.  Parts of the diplomacy dialog will
        -- be disabled.
        ScenarioInfo.TeamGame = true
        Sync.LockTeams = true
    end

    -- Set up the teams we found
    for team,armyIndices in teams do
        for k,index in armyIndices do
            for k2,index2 in armyIndices do
                SetAlliance(index,index2,"Ally")
            end
            ArmyBrains[index].RequestingAlliedVictory = true
        end
    end

    -- Create any effect markers on map
    local markers = scenarioutilitiesUp.GetMarkers()
    local Entity = entityUp.Entity
    local EffectTemplate = effecttemplatesUp
    if markers then
        for k, v in markers do
            if v.type == 'Effect' then
                local EffectMarkerEntity = Entity()
                Warp(EffectMarkerEntity, v.position)
                EffectMarkerEntity:SetOrientation(OrientFromDir(v.orientation), true)
                for k, v in EffectTemplate [v.EffectTemplate] do
                    CreateEmitterAtBone(EffectMarkerEntity,-2,-1,v):ScaleEmitter(v.scale or 1):OffsetEmitter(v.offset.x or 0, v.offset.y or 0, v.offset.z or 0)
                end
            end
        end
    end

    Sync.EnhanceRestrict = import('/lua/enhancementcommon.lua').GetRestricted()

    Sync.Restrictions = import('/lua/game.lua').GetRestrictions()

    --for off-map prevention
    OnStartOffMapPreventionThread()

    if syncStartPositions then
        Sync.StartPositions = syncStartPositions
    end
end

function GameTimeLogger()
    local time
    while true do
        GTS = GetGameTimeSeconds()
        hours   = mathFloor(GTS / 3600);
        minutes = mathFloor((GTS - (hours * 3600)) / 60);
        seconds = GTS - (hours * 3600) - (minutes * 60);
        SPEW(stringFormat('Current gametime: %02d:%02d:%02d', hours, minutes, seconds))
        WaitSeconds(30)
    end
end

-- forks a thread that performs off-map prevention
function OnStartOffMapPreventionThread()
    OffMappingPreventThread = ForkThread(import('/lua/ScenarioFramework.lua').AntiOffMapMainThread)
    ScenarioInfo.OffMapPreventionThreadAllowed = true
    --WARN('success')
end

-- OnPostLoad called after loading a saved game
function OnPostLoad()
end

-- Set up list of files to prefetch
Prefetcher = CreatePrefetchSet()

function DefaultPrefetchSet()
    local set = { models = {}, anims = {}, d3d_textures = {} }
--    for k,file in DiskFindFiles('/units/', '*.scm') do
--        table.insert(set.models,file)
--    end

--    for k,file in DiskFindFiles('/units/', '*.sca') do
--        table.insert(set.anims,file)
--    end

--    for k,file in DiskFindFiles('/units/', '*.dds') do
--        table.insert(set.d3d_textures,file)
--    end

    return set
end

CPrefetchSetUpdate(Prefetcher, DefaultPrefetchSet())

function AIModTemplatesPreloader()
    local simMods = __active_mods or {}
    for Index, ModData in simMods do
        ModAIFiles = DiskFindFiles(ModData.location..'/lua/AI/CustomAIs_v2', '*.lua')
        if ModAIFiles[1] then
            for k,file in DiskFindFiles(ModData.location..'/lua/AI/PlatoonTemplates', '*.lua') do
                import(file)
            end
            for k,file in DiskFindFiles(ModData.location..'/lua/AI/AIBuilders', '*.lua') do
                import(file)
            end
            for k,file in DiskFindFiles(ModData.location..'/lua/AI/AIBaseTemplates', '*.lua') do
                import(file)
            end
        end
    end
end
