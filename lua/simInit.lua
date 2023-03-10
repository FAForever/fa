---@declare-global
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

GameOverListeners = {}
WaitTicks = coroutine.yield

---@param n number
function WaitSeconds(n)
    if n <= 0.1 then
        WaitTicks(1)
        return
    end
    WaitTicks(n * 10 + 1)
end

-- Hook some globals
doscript '/lua/SimHooks.lua'

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

    ScenarioInfo.TriggerManager = import("/lua/triggermanager.lua").Manager
    TriggerManager = ScenarioInfo.TriggerManager

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
    ---@type AIBrain[]
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
    ScenarioInfo.Env = import("/lua/scenarioenvironment.lua")

    --Check if ShareOption is valid, and if not then set it to ShareUntilDeath
    local shareOption = ScenarioInfo.Options.Share
    local globalOptions = import("/lua/ui/lobby/lobbyoptions.lua").globalOpts
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
        local presets = import("/lua/ui/lobby/unitsrestrictions.lua").GetPresetsData()
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
        buildRestrictions = import("/lua/sim/categoryutils.lua").ParseEntityCategoryProperly(buildRestrictions)
        -- add global build restrictions for all armies
        import("/lua/game.lua").AddRestriction(buildRestrictions)
        ScenarioInfo.BuildRestrictions = buildRestrictions
    end

    if not table.empty(enhRestrictions) then
        --table.print(enhRestrictions, 'enhRestrictions ')
        import("/lua/enhancementcommon.lua").RestrictList(enhRestrictions)
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

    import("/lua/sim/scenarioutilities.lua").InitializeStartLocation(name)
    import("/lua/sim/scenarioutilities.lua").SetPlans(name)

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

    -- imported for side effects
    import("/lua/sim/matchstate.lua").Setup()
    import("/lua/sim/markerutilities.lua").Setup()

    BeginSessionAI()
    BeginSessionMapSetup()
    BeginSessionEffects()
    BeginSessionTeams()

    import("/lua/sim/scenarioutilities.lua").CreateProps()
    import("/lua/sim/scenarioutilities.lua").CreateResources()

    BeginSessionGenerateMarkers()
    BeginSessionGenerateNavMesh()

    import("/lua/sim/score.lua").init()
    import("/lua/sim/recall.lua").init()

    -- other logic at the start of the game --

    Sync.EnhanceRestrict = import("/lua/enhancementcommon.lua").GetRestricted()
    Sync.Restrictions = import("/lua/game.lua").GetRestrictions()

    if syncStartPositions then
        Sync.StartPositions = syncStartPositions
    end

    -- keep track of user name for LOCs
    local focusarmy = GetFocusArmy()
    if focusarmy>=0 and ArmyBrains[focusarmy] then
        LocGlobals.PlayerName = ArmyBrains[focusarmy].Nickname
    end

    -- add on game over callbacks
    ForkThread(function()
        while not IsGameOver() do
            WaitTicks(1)
        end
        for _, v in GameOverListeners do
            v()
        end
    end)

    -- log game time
    ForkThread(GameTimeLogger)

    -- keep track of units off map
    OnStartOffMapPreventionThread()
end

function BeginSessionGenerateNavMesh()
    Sync.GameHasAIs = ScenarioInfo.GameHasAIs
    if ScenarioInfo.GameHasAIs then
        for k, brain in ArmyBrains do
            if ScenarioInfo.ArmySetup[brain.Name].RequiresNavMesh then
                import('/lua/sim/navutils.lua').Generate()
                break
            end
        end
    end
end

--- Setup for AI related logic and data
function BeginSessionAI()
    Sync.GameHasAIs = ScenarioInfo.GameHasAIs
    if ScenarioInfo.GameHasAIs then



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

        for k,file in DiskFindFiles('/lua/AI/PlatoonTemplates', '*.lua') do
            import(file)
        end

        for k,file in DiskFindFiles('/lua/AI/AIBuilders', '*.lua') do
            import(file)
        end

        for k,file in DiskFindFiles('/lua/AI/AIBaseTemplates', '*.lua') do
            import(file)
        end
    end
end

function BeginSessionGenerateMarkers()
    Sync.GameHasAIs = ScenarioInfo.GameHasAIs
    if ScenarioInfo.GameHasAIs then
        for k, brain in ArmyBrains do
            if ScenarioInfo.ArmySetup[brain.Name].RequiresNavMesh then
                import('/lua/sim/navgenerator.lua').GenerateMarkers()
                break
            end
        end
    end
end

--- Setup for map scripts
function BeginSessionMapSetup()
    local ok, msg = pcall(ScenarioInfo.Env.OnPopulate, ScenarioInfo)
    if not ok then
        WARN(msg)
    end

    local ok, msg = pcall(ScenarioInfo.Env.OnStart, ScenarioInfo)
    if not ok then
        WARN(msg)
    end
end

--- Setup for team manangement
function BeginSessionTeams()
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
        ScenarioInfo.TeamGame = true
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

    -- setup special team options
    if ScenarioInfo.Options.CommonArmy == 'Union' then
        BeginSessionUnionArmy()
    elseif ScenarioInfo.Options.CommonArmy == 'Common' then
        BeginSessionCommonArmy()
    end
end

--- Setup for union army, where all teams can control the units of its allies
function BeginSessionUnionArmy()
    local humanIndex = 0
    for i, brain in ArmyBrains do
        if brain.BrainType ~= 'Human' then continue end
        for i2, _ in ArmyBrains do
            if not IsAlly(i, i2) then continue end
            SetCommandSource(i2 - 1, humanIndex, true)
        end
        humanIndex = humanIndex + 1
    end
end


--- Setup for common army, where all teams are batched together into one army
function BeginSessionCommonArmy()
    local teams = {}
    for name,army in ScenarioInfo.ArmySetup do
        if army.Team > 1 then
            if not teams[army.Team] then
                teams[army.Team] = {}
            end
            table.insert(teams[army.Team],army.ArmyIndex)
        end
    end

    local humanIndex = 0
    local IsHuman = {}
    for _, brain in ArmyBrains do
        if brain.BrainType == 'Human' then
            table.insert(IsHuman, humanIndex)
            humanIndex = humanIndex + 1
        else
            table.insert(IsHuman, false)
        end
    end

    local teamIndex = 1
    for _, armyIndices in teams do
        for _, i in armyIndices do
            if ArmyBrains[i].BrainType ~= 'Human' then continue end
            ArmyBrains[i].Nickname = 'Team ' .. tostring(teamIndex)
            teamIndex = teamIndex + 1
            for _, i2 in armyIndices do
                if (i2 == i) or (not IsHuman[i2]) then continue end
                ArmyBrains[i2].Nickname = 'Merged'
                ArmyBrains[i2].Status = 'Defeat'
                SetArmyOutOfGame(i2)
                local Units = ArmyBrains[i2]:GetListOfUnits(categories.COMMAND, false, true)
                ForkThread(function(i, i2, comm)
                    while true do
                        if comm then
                            WaitTicks(1)
                            if comm:IsUnitState('Busy') then continue end
                            if comm:IsUnitState('UnSelectable') then continue end
                            if comm:IsUnitState('BlockCommandQueue') then continue end
                        end
                        SetCommandSource(i2 - 1, IsHuman[i2], false)
                        SetCommandSource(i - 1, IsHuman[i2], true)
                        SetArmyUnitCap(i, GetArmyUnitCap(i) + GetArmyUnitCap(i2))
                        Units = ArmyBrains[i2]:GetListOfUnits(categories.ALLUNITS, false, true)
                        for _, unit in Units do
                            ChangeUnitArmy(unit, i, true)
                        end
                        local v1 = ArmyBrains[i]:GetEconomyStored('MASS') + ArmyBrains[i2]:GetEconomyStored('MASS')
                        local v2 = ArmyBrains[i]:GetEconomyStored('ENERGY') + ArmyBrains[i2]:GetEconomyStored('ENERGY')
                        SetArmyEconomy(i, v1, v2)
                        SetFocusArmy(i - 1)
                        break
                    end
                end, i, i2, Units[1])
            end
            break
        end
    end
end

--- Setup for map effects
function BeginSessionEffects()
    local markers = import("/lua/sim/scenarioutilities.lua").GetMarkers()
    local Entity = import("/lua/sim/entity.lua").Entity
    local EffectTemplate = import("/lua/effecttemplates.lua")
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
end

function GameTimeLogger()
    while true do
        GTS = GetGameTimeSeconds()
        hours   = math.floor(GTS / 3600);
        minutes = math.floor((GTS - (hours * 3600)) / 60);
        seconds = GTS - (hours * 3600) - (minutes * 60);
        SPEW(string.format('Current gametime: %02d:%02d:%02d', hours, minutes, seconds))
        WaitSeconds(30)
    end
end

-- forks a thread that performs off-map prevention
function OnStartOffMapPreventionThread()
    OffMappingPreventThread = ForkThread(import("/lua/scenarioframework.lua").AntiOffMapMainThread)
    ScenarioInfo.OffMapPreventionThreadAllowed = true
    --WARN('success')
end

-- OnPostLoad called after loading a saved game
function OnPostLoad()
    import("/lua/scenarioframework.lua").OnPostLoad()
    import("/lua/simobjectives.lua").OnPostLoad()
    import("/lua/sim/simuistate.lua").OnPostLoad()
    import("/lua/simping.lua").OnArmyChange()
    import("/lua/simpinggroup.lua").OnPostLoad()
    import("/lua/simdialogue.lua").OnPostLoad()
    import("/lua/simsync.lua").OnPostLoad()
    if GetFocusArmy() ~= -1 then
        Sync.SetAlliedVictory = ArmyBrains[GetFocusArmy()].RequestingAlliedVictory or false
    end
end

-- these imports break cycle dependencies of import sequences of mods

import('/lua/scenarioframework.lua')
import('/lua/sim/scenarioutilities.lua')
import("/lua/ai/aiutilities.lua")
import("/lua/ai/sorianutilities.lua")
import("/lua/ai/aiattackutilities.lua")