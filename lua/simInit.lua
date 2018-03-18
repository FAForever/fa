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

WaitTicks = coroutine.yield

function WaitSeconds(n)
    local ticks = math.max(1, n * 10)
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
    ValidateMapAndMarkers()

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
    SPEW('Active mods in sim: ', repr(__active_mods))

    ForkThread(GameTimeLogger)
    if ScenarioInfo.Options.AIPathingDebug ~= 'off' then
        ForkThread(GraphRender)
    end

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

function GameTimeLogger()
    local time
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


-- Map validation and AI pathing debug --

local KnownMarkerTypes = {
    ['Air Path Node']=true,
    ['Amphibious Path Node']=true,
    ['Blank Marker']=true,
    ['Camera Info']=true,
    ['Combat Zone']=true,
    ['Defensive Point']=true,
    ['Effect']=true,
    ['Expansion Area']=true,
    ['Hydrocarbon']=true,
    ['Island']=true,
    ['Land Path Node']=true,
    ['Large Expansion Area']=true,
    ['Mass']=true,
    ['Naval Area']=true,
    ['Naval Defensive Point']=true,
    ['Naval Exclude']=true,
    ['Naval Link']=true,
    ['Naval Rally Point']=true,
    ['Protected Experimental Construction']=true,
    ['Rally Point']=true,
    ['Transport Marker']=true,
    ['Water Path Node']=true,
    ['Weather Definition']=true,
    ['Weather Generator']=true,
 }
local BaseLocations = {
    ['Blank Marker']         = { ['priority'] = 4 },
    ['Naval Area']           = { ['priority'] = 3 },
    ['Large Expansion Area'] = { ['priority'] = 2 },
    ['Expansion Area']       = { ['priority'] = 1 },
}
local Offsets = {
    ['DefaultLand']       = { [1] =  0.0, [2] =  0.0, [3] =  0.0, ['color'] = 'ffF4A460', },
    ['DefaultWater']      = { [1] = -0.5, [2] =  0.0, [3] = -0.5, ['color'] = 'ff000080', },
    ['DefaultAmphibious'] = { [1] = -1.0, [2] =  0.0, [3] = -1.0, ['color'] = 'ff00BFFF', },
    ['DefaultAir']        = { [1] = -1.5, [2] =  0.0, [3] = -1.5, ['color'] = 'ffEFEFFF', },
}

local MarkerDefaults = {
    ['Land Path Node']          = { ['graph'] ='DefaultLand',       ['color'] = 'ff808080', },
    ['Water Path Node']         = { ['graph'] ='DefaultWater',      ['color'] = 'ff0000ff', },
    ['Amphibious Path Node']    = { ['graph'] ='DefaultAmphibious', ['color'] = 'ff404060', },
    ['Air Path Node']           = { ['graph'] ='DefaultAir',        ['color'] = 'ffffffff', },
}
local colors = {
    ['counter'] = 0,
    ['countermax'] = 0,
    ['lastcolorindex'] = 1,
    [1] = 'ff000000',
    [2] = 'ff202000',
    [3] = 'ff404000',
    [4] = 'ff606000',
    [5] = 'ff808000',
    [6] = 'ffA0A000',
    [7] = 'ffC0C000',
    [8] = 'ffE0E000',

    [9] = 'ffFFFF00',
    [10] = 'ffFFFF00',
    [11] = 'ffFFFF00',

    [12] = 'ffE0E000',
    [13] = 'ffC0C000',
    [14] = 'ffA0A000',
    [15] = 'ff808000',
    [16] = 'ff606000',
    [17] = 'ff404000',
    [18] = 'ff202000',
    [19] = 'ff000000',
}


function ValidateMapAndMarkers()
    -- Check norushradius
    if ScenarioInfo.norushradius and ScenarioInfo.norushradius > 0 then
        if ScenarioInfo.norushradius < 10 then
            WARN('* ValidateMapAndMarkers: norushradius is too smal ('..ScenarioInfo.norushradius..')! Set radius to minimum (15).')
            ScenarioInfo.norushradius = 15
        else
            LOG('* ValidateMapAndMarkers: norushradius is OK. ('..ScenarioInfo.norushradius..')')
        end
    else
        WARN('* ValidateMapAndMarkers: norushradius is missing! Set radius to default (20).')
        ScenarioInfo.norushradius = 20
    end

    -- Check map markers
    local TEMP = {}
    local UNKNOWNMARKER
    local dist
    for k, v in Scenario.MasterChain._MASTERCHAIN_.Markers do
        -- Check if the marker is known. If not, send a debug message
        if not KnownMarkerTypes[v.type] then
            if not UNKNOWNMARKER[v.type] then
                LOG('* ValidateMapAndMarkers: Unknown MarkerType: [\''..v.type..'\']=true,')
                UNKNOWNMARKER[v.type] = true
            end
        end
        -- Check Waypoint Maker
        if MarkerDefaults[v.type] then
            if v.adjacentTo then
                local adjancents = STR_GetTokens(v.adjacentTo, ' ')
                if adjancents[0] then
                    for i, node in adjancents do
                        --local otherMarker = Scenario.MasterChain._MASTERCHAIN_.Markers[node]
                        if not Scenario.MasterChain._MASTERCHAIN_.Markers[node] then
                            WARN('* ValidateMapAndMarkers: adjacentTo is wrong in marker ['..k..'] - MarkerType: [\''..v.type..'\']. - Adjacent marker ['..node..'] is missing.')
                        end
                    end
                else
                    WARN('* ValidateMapAndMarkers: adjacentTo is empty in marker ['..k..'] - MarkerType: [\''..v.type..'\']. - Pathmarker must have an adjacent marker for pathing.')
                end
            else
                WARN('* ValidateMapAndMarkers: adjacentTo is missing in marker ['..k..'] - MarkerType: [\''..v.type..'\']. - Pathmarker must have an adjacent marker for pathing.')
            end
            -- Checking marker type/graph 
            if MarkerDefaults[v.type]['graph'] ~= v.graph then
                WARN('* ValidateMapAndMarkers: graph missmatch in marker ['..k..'] - MarkerType: [\''..v.type..'\']. - marker.type is ('..repr(v.graph)..'), but should be ('..MarkerDefaults[v.type]['graph']..').')
                -- save the correct graph type 
                v.graph = MarkerDefaults[v.type]['graph']
            end
            -- Checking colors (for debug)
            if MarkerDefaults[v.type]['color'] ~= v.color then
                -- we actual don't print a debugmessage here. This message is for debuging a debug function :)
                --LOG('* ValidateMapAndMarkers: color missmatch in marker ['..k..'] - MarkerType: [\''..v.type..'\']. marker.color is ('..repr(v.color)..'), but should be ('..MarkerDefaults[v.type]['color']..').')
                v.color = MarkerDefaults[v.type]['color']
            end
        -- Check BaseLocations distances to other locations
        elseif BaseLocations[v.type] then
            for k2, v2 in Scenario.MasterChain._MASTERCHAIN_.Markers do
                if BaseLocations[v2.type] and v ~= v2 then
                    local dist = VDist2( v.position[1], v.position[3], v2.position[1], v2.position[3] )
                    -- Are we checking a Start location, and another marker is nearer then 80 units ?
                    if v.type == 'Blank Marker' and v2.type ~= 'Blank Marker' and dist < 80 then
                        WARN('* ValidateMapAndMarkers: Marker [\''..k2..'\'] is to close to Start Location [\''..k..'\']. Distance= '..math.floor(dist)..' (under 80).')
                        --Scenario.MasterChain._MASTERCHAIN_.Markers[k2] = nil
                    -- Check if we have other locations that have a low distance (under 60)
                    elseif v.type ~= 'Blank Marker' and v2.type ~= 'Blank Marker' and dist < 60 then
                        -- Check priority from small locations up to main base.
                        if BaseLocations[v.type].priority >= BaseLocations[v2.type].priority then
                            WARN('* ValidateMapAndMarkers: Marker [\''..k2..'\'] is to close to Marker [\''..k..'\']. Distance= '..math.floor(dist)..' (under 60).')
                            -- Not used at the moment, but we can delete the location with the lower priority here.
                            -- This is used for debuging the locationmanager, so we can be sure that locations are not overlapping.
                            --Scenario.MasterChain._MASTERCHAIN_.Markers[k2] = nil
                        end
                    end
                end
            end
        end
    end
end

function GraphRender()
    -- wait 10 seconds at gamestart before we start debuging
    WaitTicks(100)
    while true do
        -- draw all paths with location radius and AI Pathfinding
        if ScenarioInfo.Options.AIPathingDebug == 'all' then
            -- display first all land nodes (true will let them blink)
            if GetGameTimeSeconds() < 15 then
                DrawPathGraph('DefaultLand', true)
            -- display amphibious nodes
            elseif GetGameTimeSeconds() < 20 then
                DrawPathGraph('DefaultAmphibious', true)
            -- water nodes
            elseif GetGameTimeSeconds() < 25 then
                DrawPathGraph('DefaultWater', true)
            -- air nodes
            elseif GetGameTimeSeconds() < 30 then
                DrawPathGraph('DefaultAir', true)
            end
            -- Draw the radius of each base(manager)
            DrawBaseRanger()
            DrawAIPatchCache()
        -- Display land path permanent
        elseif ScenarioInfo.Options.AIPathingDebug == 'land' then
            DrawPathGraph('DefaultLand', false)
            DrawAIPatchCache('DefaultLand')
        -- Display water path permanent
        elseif ScenarioInfo.Options.AIPathingDebug == 'water' then
            DrawPathGraph('DefaultWater', false)
            DrawAIPatchCache('DefaultWater')
        -- Display amph path permanent
        elseif ScenarioInfo.Options.AIPathingDebug == 'amph' then
            DrawPathGraph('DefaultAmphibious', false)
            DrawAIPatchCache('DefaultAmphibious')
        -- Display air path permanent
        elseif ScenarioInfo.Options.AIPathingDebug == 'air' then
            DrawPathGraph('DefaultAir', false)
            DrawAIPatchCache('DefaultAir')
        end
        WaitTicks(2)
    end
end

function DrawBaseRanger()
    -- Render the radius of any base and expansion location
    if Scenario.MasterChain._MASTERCHAIN_.BaseRanger then
        for Index, ArmyRanger in Scenario.MasterChain._MASTERCHAIN_.BaseRanger do
            for nodename, markerInfo in ArmyRanger do
                DrawCircle(markerInfo.Pos, markerInfo.Rad-0.5, 'ff000000')
                DrawCircle(markerInfo.Pos, markerInfo.Rad, 'ffFFE0E0')
            end
        end
    end
end

function DrawPathGraph(DrawOnly,Blink)
    local color
    if Blink then
        colors['counter'] = colors['counter'] + 1
        if colors['counter'] > colors['countermax'] then
            colors['counter'] = 0
            --LOG('lastcolorindex:'..colors['lastcolorindex']..' - table.getn(colors)'..table.getn(colors))
            if colors['lastcolorindex'] >= (table.getn(colors)) then
                colors['lastcolorindex'] = 1
            else
                colors['lastcolorindex'] = colors['lastcolorindex'] + 1
            end
        end
        color = colors[colors['lastcolorindex']]
    else
        color = Offsets[DrawOnly]['color']
    end
    local AIAttackUtils = import('/lua/ai/aiattackutilities.lua')
    local MarkerPosition = {0,0,0}
    local Marker2Position = {0,0,0}
    -- Render the connection between the path nodes for the specific graph
    for Layer, LayerMarkers in AIAttackUtils.GetPathGraphs() do
        for graph, GraphMarkers in LayerMarkers do
            for nodename, markerInfo in GraphMarkers do
                if DrawOnly and DrawOnly ~= markerInfo.graphName then
                    continue
                end
                MarkerPosition[1] = markerInfo.position[1] + (Offsets[markerInfo.graphName][1])
                MarkerPosition[2] = markerInfo.position[2] + (Offsets[markerInfo.graphName][2])
                MarkerPosition[3] = markerInfo.position[3] + (Offsets[markerInfo.graphName][3])
                -- Draw the marker path node
                DrawCircle(MarkerPosition, 5, Offsets[markerInfo.graphName]['color'] or colors[colors['lastcolorindex']] )
                -- Draw the connecting lines to its adjacent nodes
                for i, node in markerInfo.adjacent do
                    local otherMarker = Scenario.MasterChain._MASTERCHAIN_.Markers[node]
                    if otherMarker then
                        Marker2Position[1] = otherMarker.position[1] + Offsets[otherMarker.graph][1]
                        Marker2Position[2] = otherMarker.position[2] + Offsets[otherMarker.graph][2]
                        Marker2Position[3] = otherMarker.position[3] + Offsets[otherMarker.graph][3]
                        --DrawLinePop(MarkerPosition, Marker2Position, GraphOffsets[otherMarker.graph]['color'])
                        DrawLinePop(MarkerPosition, Marker2Position, color )
                    end
                end
            end
        end
    end
end

function DrawAIPatchCache(DrawOnly)
    -- loop over all players in the game
    for ArmyIndex, aiBrain in ArmyBrains do
        -- is the player an AI-Uveso ?
        if aiBrain.Uveso and aiBrain.PathCache then
            local LineCountOffset = 0
            local Pos1 = {}
            local Pos2 = {}
            -- Loop over all paths that starts from "StartNode"
            for StartNode, EndNodeCache in aiBrain.PathCache do
                LineCountOffset = 0
                -- Loop over all paths starting from StartNode and ending in EndNode
                for EndNode, Path in EndNodeCache do
                    -- Loop over all threatWeighted paths
                    for threatWeight, PathNodes in Path do
                        -- Display only valid paths
                        if PathNodes.path ~= 'bad' then
                            local LastNode = false
                            -- loop over all path waypoints and draw lines.
                            for NodeIndex, PathNode in PathNodes.path.path do
                                -- continue if we don't want to draw this graph node
                                if DrawOnly and DrawOnly ~= PathNode.graphName then
                                    continue
                                end
                                if LastNode then
                                    -- If we draw a horizontal line, then draw the next line "under" the last line
                                    if math.abs(LastNode.position[1] - PathNode.position[1]) > math.abs(LastNode.position[3] - PathNode.position[3]) then
                                        DirectionOffsetX = 0
                                        DirectionOffsetY = 0.5
                                    -- else we are drawing vertical, then draw the next line "Right" near the last line
                                    else
                                        DirectionOffsetX = 0.5
                                        DirectionOffsetY = 0
                                    end
                                    DrawLinePop({LastNode.position[1] + LineCountOffset,                        LastNode.position[2], LastNode.position[3] + LineCountOffset},                        {PathNode.position[1] + LineCountOffset,                        PathNode.position[2],PathNode.position[3] + LineCountOffset},                        'ff000000')                   
                                    DrawLinePop({LastNode.position[1] + LineCountOffset + DirectionOffsetX,     LastNode.position[2], LastNode.position[3] + LineCountOffset + DirectionOffsetY},     {PathNode.position[1] + LineCountOffset + DirectionOffsetX,     PathNode.position[2],PathNode.position[3] + LineCountOffset + DirectionOffsetY},     'ff000000')                   
                                    DrawLinePop({LastNode.position[1] + LineCountOffset + DirectionOffsetX * 2, LastNode.position[2], LastNode.position[3] + LineCountOffset + DirectionOffsetY * 2}, {PathNode.position[1] + LineCountOffset + DirectionOffsetX * 2, PathNode.position[2],PathNode.position[3] + LineCountOffset + DirectionOffsetY * 2}, Offsets[PathNode.graphName]['color'])                             
                                end
                                LastNode = PathNode
                            end
                            LineCountOffset = LineCountOffset + 2.5
                        end
                    end
                end
            end
        end
    end
end





