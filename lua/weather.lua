local WeatherDefinition = import("/lua/weatherdefinitions.lua")
local MapStyleList = WeatherDefinition.MapStyleList
local MapWeatherList = WeatherDefinition.MapWeatherList
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local util = import("/lua/utilities.lua")
local Entity = import("/lua/sim/entity.lua").Entity

local TableGetN = table.getn

function GetWeatherMarkerData(mapScale)
    -- find all the weather definition and weather generator markers
    local markers = ScenarioUtils.GetMarkers()
    local generatorMarkers = { }
    local definitionMarkers = { }

    if markers then
        for _, marker in markers do
            if marker.type == 'Weather Generator' then
                table.insert(generatorMarkers, marker)
            elseif marker.type == 'Weather Definition' then
                table.insert(definitionMarkers, marker)
            end
        end
    end

    -- transform the definition markers into a more useful, abstract format
    local definitions = {}
    for _, marker in definitionMarkers do
        table.insert(definitions,
            {
                MapStyle = marker.MapStyle or "None",
                WeatherTypes = {
                    {
                        Type = marker.WeatherType01 or "None",
                        Chance = marker.WeatherType01Chance or 0.25,
                    },
                    {
                        Type = marker.WeatherType02 or "None",
                        Chance = marker.WeatherType02Chance or 0.25,
                    },
                    {
                        Type = marker.WeatherType03 or "None",
                        Chance = marker.WeatherType03Chance or 0.25,
                    },
                    {
                        Type = marker.WeatherType04 or "None",
                        Chance = marker.WeatherType04Chance or 0.25,
                    },
                },
            }
        )
    end

    -- transform the generator markers into a more useful, abstract format
    local clusters = {}
    local defaultcloudclusterSpread = math.floor(((mapScale[1] + mapScale[2]) * 0.5) * 0.15)
    for _, marker in generatorMarkers do
        local cluster = {
            clusterSpread = marker.cloudSpread or defaultcloudclusterSpread,
            cloudCount = marker.cloudCount or 10,
            cloudCountRange = marker.cloudCountRange or 0,
            cloudHeight = marker.cloudHeight or 180,
            cloudHeightRange = marker.cloudHeightRange or 10,
            position = marker.position,
            emitterScale = marker.cloudEmitterScale or 1,
            emitterScaleRange = marker.cloudEmitterScaleRange or 0,
            forceType = marker.ForceType or "None",
            spawnChance = marker.spawnChance or 1,
        }

        -- make it default to true if it is not defined
        cluster.visibleThroughFog = marker.visibleThroughFog
        if cluster.visibleThroughFog == nil then
            cluster.visibleThroughFog = true
        end

        table.insert( clusters, cluster)
    end

    -- return it all
    return definitions, clusters
end

function GetRandomWeatherEffectType( definition )
    -- compute the total range
    local range = 0
    for _, v in definition.WeatherTypes do
        range = range + v.Chance
    end

    -- choose a random number in that range
    local pick = util.GetRandomFloat( 0, range )

    -- determine which marker has the number in its range
    local sum = 0
    for _, v in definition.WeatherTypes do
        if sum <= pick and pick <= sum + v.Chance then
            return v.Type
        else
            sum = sum + v.Chance
        end
    end
end

function SetClusterEffectData(weather, style, globalType, clusters)
    -- determine the weather type for each cluster
    for _, cluster in clusters do
        if cluster.forceType == "None" then
            local emitters = weather[style][globalType]
            cluster.effects = emitters[util.GetRandomInt(1,TableGetN(emitters))]
        else
            local emitters = weather[style][cluster.forceType]
            cluster.effects = emitters[util.GetRandomInt(1,TableGetN(emitters))]
        end
    end
end

function ClustersToEmitters( clusters )

    local nc = TableGetN(clusters)

    -- for each cluster...
    for _, cluster in clusters do

        -- there is a chance it doesn't spawn at all
        local spawn = util.GetRandomFloat( 0, 1 )
        if spawn < cluster.spawnChance then

            -- determine the height of the emitters
            local BaseHeight = cluster.position[2] + cluster.cloudHeight
            local HeightOffset = cluster.cloudHeightRange

            -- determine rectangle to spawn the emitters in
            local clusterSpreadHalfSize = cluster.clusterSpread * 0.5
            local LeftX = cluster.position[1] - clusterSpreadHalfSize
            local TopZ = cluster.position[3] - clusterSpreadHalfSize
            local RightX = cluster.position[1] + clusterSpreadHalfSize
            local BottomZ = cluster.position[3] + clusterSpreadHalfSize

            -- determine number of emitters
            local numCloudsPerCluster = cluster.cloudCount
            numCloudsPerCluster = numCloudsPerCluster + util.GetRandomInt(
                cluster.cloudCountRange * -0.5,
                cluster.cloudCountRange * 0.5
            )

            -- determine individual particle scale
            local clusterEffectMaxScale = cluster.emitterScale + cluster.emitterScaleRange
            local clusterEffectMinScale = cluster.emitterScale - cluster.emitterScaleRange

            -- spawn the individual emitters
            for j = 0, numCloudsPerCluster do
                -- construct a dummy entity
                local cloud = Entity()

                -- move the entity
                local x = util.GetRandomInt( LeftX, RightX )
                local y = BaseHeight + util.GetRandomInt(-HeightOffset,HeightOffset)
                local z = util.GetRandomInt( TopZ, BottomZ )
                Warp( cloud, Vector(x,y,z) )

                -- spawn the weather effects
                for _, effect in cluster.effects do

                    -- create the emitter
                    local entity = cloud
                    local bone = -2
                    local army = -1
                    local emitter = CreateEmitterAtBone(entity, bone, army, effect)

                    -- scale it accordingly
                    emitter:ScaleEmitter(util.GetRandomFloat( clusterEffectMaxScale, clusterEffectMinScale))

                    -- determine if it spawns without visibility
                    if cluster.visibleThroughFog then
                        emitter:SetEmitterParam("EMITIFVISIBLE", 0)
                    end
                end
            end
        end
    end
end

function CreateWeatherThread()
    -- read out the markers with regard to the weather
    local definitions, clusters = GetWeatherMarkerData(ScenarioInfo.size)

    local nd = TableGetN(definitions)
    local nc = TableGetN(clusters)

    -- early opt: no definitions, no clusters
    if nd == 0 and nc == 0 then
        WARN('Intention to generate weather but the corresponding [Weather Definition] and [Weather Generator] markers are not placed in map, aborting weather generation.')
        return
    end

    -- early opt out: no clusters
    if nd > 0 and nc == 0 then
        WARN('Intention to generate weather but there are no [Weather Generator] markers placed in map, aborting weather generation.')
        return
    end

    -- early opt out: no definitions
    if nd == 0 and nc > 0 then
        WARN('Intention to generate weather but there are no [Weather Definition] markers placed in map, aborting weather generation.')
        return
    end

    -- a heads up that multiple definitions make no sense
    local definition = definitions[1]
    if nd > 1 then
        WARN('Multiple [Weather Definition] markers in map - only the first one in the _save.lua file is used.')
    end

    -- early opt out: map style is unknown
    local style = definition.MapStyle
    if not table.find(MapStyleList, style) then
        WARN(
            'Intention to generate weather but the chosen map style ' .. style .. ' is not known, aborting weather generation.',
            'A full list of available styles is: \r\n' .. repr(MapStyleList)
        )
        return
    end

    -- early opt out: definition tries to use a type that is not part of the style
    if not (definition.WeatherTypes[1].Type == "None") and not MapWeatherList[style][definition.WeatherTypes[1].Type] then
        WARN('Intention to generate weather but type 1 \'' .. definition.WeatherTypes[1].Type .. '\' is not part of the map style \'' .. style .. '\' , aborting weather generation.')
        return
    end

    if not (definition.WeatherTypes[2].Type == "None") and not MapWeatherList[style][definition.WeatherTypes[2].Type] then
        WARN('Intention to generate weather but type 2 \'' .. definition.WeatherTypes[2].Type .. '\' is not part of the map style \'' .. style .. '\' , aborting weather generation.')
        return
    end

    if not (definition.WeatherTypes[3].Type == "None") and not MapWeatherList[style][definition.WeatherTypes[3].Type] then
        WARN('Intention to generate weather but type 3 \'' .. definition.WeatherTypes[3].Type .. '\' is not part of the map style \'' .. style .. '\' , aborting weather generation.')
        return
    end

    if not (definition.WeatherTypes[4].Type == "None") and not MapWeatherList[style][definition.WeatherTypes[4].Type] then
        WARN('Intention to generate weather but type 4 \'' .. definition.WeatherTypes[4].Type .. '\' is not part of the map style \'' .. style .. '\' , aborting weather generation.')
        return
    end

    -- early opt out: a generator tries to force a type that is not part of the style
    for k, cluster in clusters do
        if not (cluster.forceType == "None") then
            if not MapWeatherList[style][cluster.forceType] then
                WARN(
                    'Intention to generate weather but a forced type \'' .. cluster.forceType .. '\'  of \'' .. k .. '\' cluster is not part of the map style \'' .. style .. '\' , aborting weather generation.',
                    'A full list of available weather types of \'' .. style .. '\' is: \r\n' .. repr(MapWeatherList[style])
                )
            end
        end
    end

    -- determine the global weather type and do an early opt out
    local globalType = GetRandomWeatherEffectType(definition)
    if globalType == "None" then
        LOG("Intention to generate weather but the \'None\' weather type was randomly chosen from the definition, aborting weather generation.")
        return
    end

    -- determine the weather effects per marker, clusters are send by reference and therefore changed in place.
    SetClusterEffectData(MapWeatherList, style, globalType, clusters)

    -- spawn 'dem rainy weather!
    ClustersToEmitters( clusters, style, type )
end

-- CreateWeather, this is the entry point for map script, OnPopulate to
-- generate weather. We spawn a thread here so we can do dynamic movement
function CreateWeather()
    ForkThread( CreateWeatherThread )
end

-- Local constant definition, used to make sure we don't subdivide too small,
-- and skips any areas small than this
local MinimumSpatialPartionAreaSize = 100

-- GenerateClusterCoords
-- - Divides rect area defined by (xStart, zStart), (xEnd, zEnd) and randomly
-- adds cluster groups in each area. If an area has too many cluster pairs in
-- one region, that region is divided up again, by calling this function
-- recursively.
--
-- MinimumSpatialPartionAreaSize defined above defines the minumum area we will
-- sub-divide into, so it is possible that the numClusters will be less than
-- intended.
function GenerateClusterCoords( xStart, zStart, xEnd, zEnd, numClusters )
    local clusterList = {}

    local xHalf = (xEnd + xStart) * 0.5
    local zHalf = (zEnd + zStart) * 0.5
    -- Create 4 main area subdivisions
    local divisions = {
        {	xStart, zStart, xHalf, zHalf },
        {	xHalf, zStart, xHalf, zHalf },
        {	xStart, zHalf, xHalf, zEnd	},
        {	xHalf, zHalf, xEnd, zEnd	},
    }

    -- Decide how many cloud clusters will be in each
    local clusterDensityMap = {0,0,0,0}
    for i = 1, numClusters do
        local quadrant = util.GetRandomInt(1,4)
        clusterDensityMap[quadrant] = clusterDensityMap[quadrant] + 1
    end

    --LOG( repr( divisions ), repr( clusterDensityMap ) )

    -- Generate a coordinate for any divisions that have only one cluster
    for i = 1, 4 do
        if clusterDensityMap[i] == 1 then
            -- Insert random x/z coordinate into ClusterList\
            local newKey = { util.GetRandomInt( divisions[i][1], divisions[i][3] ) , 0, util.GetRandomInt( divisions[i][2], divisions[i][4] )}
            newKey[2] = GetSurfaceHeight(newKey[1],newKey[3])
            table.insert( clusterList, newKey )
            --LOG( 'Inserting Cluster Area[', i .. '] Coords ', repr( divisions[i] ) )
        elseif clusterDensityMap[i] > 1 then
            --LOG( 'SubDivide Region[', i .. '] Coords ', repr( divisions[i] )  )

            -- Only add a new subdivision if we are not below our minimum area
            if (((divisions[i][2] - divisions[i][1]) * (divisions[i][4] - divisions[i][4])) < MinimumSpatialPartionAreaSize ) then

                local addedclusterList = GenerateClusterCoords( divisions[i][1], divisions[i][2], divisions[i][3], divisions[i][4], clusterDensityMap[i] )
                -- Insert any new clusters into our original list
                for k, v in addedclusterList do
                    table.insert(clusterList,v)
                end
            end
        end
    end

    return clusterList
end

-- GenerateWeatherGroups
-- - Generates spread of clusters
--
-- Returns a cluster list table { {xpos, zpos}, ... }, which is just
-- full of unique paired coordinates for the map
function GenerateWeatherGroups( mapScaleX, mapScaleZ, numClusters )
    return GenerateClusterCoords(0,0,mapScaleX, mapScaleZ, numClusters )
end