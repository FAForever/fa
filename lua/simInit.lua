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

-- Do global initialization and set up common global functions
doscript '/lua/globalInit.lua'

LOG('Active mods in sim: ', repr(__active_mods))

WaitTicks = coroutine.yield

function WaitSeconds(n)
    local ticks = math.max(1, n * 10)
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

        local shuffledGroup = table.shuffle(group)
        for i = 1, table.getn(group) do
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
    local globalOptions = import('/lua/ui/lobby/lobbyOptions.lua').globalOpts
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
        table.print(restrictions, 'RestrictedCategories')
        local presets = import('/lua/ui/lobby/UnitsRestrictions.lua').GetPresetsData()
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
                    table.print(preset.enhancements, 'restriction.enhancements ')
                    for _, enhancement in preset.enhancements do
                        enhRestrictions[enhancement] = true
                    end
                end
            end
        end
    end

    if buildRestrictions then
        LOG('restriction.build '.. buildRestrictions)
        buildRestrictions = import('/lua/sim/Categoryutils.lua').ParseEntityCategoryProperly(buildRestrictions)
        -- add global build restrictions for all armies
        import('/lua/game.lua').AddRestriction(buildRestrictions)
        ScenarioInfo.BuildRestrictions = buildRestrictions
    end

    if table.getsize(enhRestrictions) > 0 then
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
    if spawn and table.find({'random_reveal', 'balanced_reveal', 'balanced_flex_reveal'}, spawn) then
        -- Shuffles positions like normal but syncs the new positions to the UI
        syncStartPositions = {}
        ShuffleStartPositions(true)
    elseif spawn and table.find({'random', 'balanced', 'balanced_flex'}, spawn) then
        -- Prevents players from knowing start positions at start
        ShuffleStartPositions(false)
    end

    LOG('Loading script file: ', ScenarioInfo.script)
    doscript(ScenarioInfo.script, ScenarioInfo.Env)

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

    --brain:InitializePlatoonBuildManager()
    --ScenarioUtils.LoadArmyPBMBuilders(name)
    --LOG('*SCENARIO DEBUG: ON POP, ARMY BRAINS = ', repr(ArmyBrains))
end

function InitializePrebuiltUnits(name)
    ArmyInitializePrebuiltUnits(name)
end

-- BeginSession will be called by the engine after the armies are created (but without
-- any units yet) and we're ready to start the game. It's responsible for setting up
-- the initial units and any other gameplay state we need.
function BeginSession()
    LOG('BeginSession...')
    ForkThread(GametimeLogger)
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
            table.insert(teams[army.Team],army.ArmyIndex)
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
    local markers = import('/lua/sim/ScenarioUtilities.lua').GetMarkers()
    local Entity = import('/lua/sim/Entity.lua').Entity
    local EffectTemplate = import ('/lua/EffectTemplates.lua')
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

function GametimeLogger()
    local gametime = 0
    local sec = 0
    while true do
        gametime = GetGameTimeSeconds()
        sec = math.floor(math.mod(gametime,60))
        if sec < 10 then
            LOG('current gametime:  ' .. math.floor(gametime/60) .. ':0' ..  sec)
        else
            LOG('current gametime:  ' .. math.floor(gametime/60) .. ':' ..  sec)
        end
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

--    for k,file in DiskFindFiles('/units/*.scm') do
--        table.insert(set.models,file)
--    end

--    for k,file in DiskFindFiles('/units/*.sca') do
--        table.insert(set.anims,file)
--    end

--    for k,file in DiskFindFiles('/units/*.dds') do
--        table.insert(set.d3d_textures,file)
--    end

    return set
end

Prefetcher:Update(DefaultPrefetchSet())

