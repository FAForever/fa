local WeatherDefinition = import('/lua/weatherdefinitions.lua')
local MapStyleList = WeatherDefinition.MapStyleList
local MapWeatherList = WeatherDefinition.MapWeatherList
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local util = import('/lua/utilities.lua')
local Entity = import('/lua/sim/Entity.lua').Entity

-- CreateWeather, this is the entry point for map script, OnPopulate to 
-- generate weather. We spawn a thread here so we can do dynamic movement
function CreateWeather()
	ForkThread( CreateWeatherThread )
end

function CreateWeatherThread()
	local MapScale = ScenarioInfo.size -- x,z map scaling
	local WeatherDefinition, ClusterData = GetWeatherMarkerData(MapScale)
	local MapStyle = WeatherDefinition.MapStyle
	local WeatherEffectsType = GetRandomWeatherEffectType( WeatherDefinition )
	--WeatherEffectsType = 'StormClouds'
	if WeatherEffectsType == 'None' then
		return
	end	
	
	local numClusters = table.getn( ClusterData )
	LOG( 'Weather Definition ' .. repr(WeatherDefinition))
	--LOG( 'Cluster Data ' .. repr(ClusterData))
	LOG( 'Weather Effect Type: ', WeatherEffectsType )
	
	if not WeatherDefinition.WeatherTypes and numClusters then
		LOG(' WARNING: Weather, no [Weather Definition] marker placed, with [Weather Generator] markers placed in map, aborting weather generation')
		return 
	end
		
	-- If we have any clusters, then generate cluster list
	if numClusters != 0 then
		local notfoundMapStyle = true
		for k, v in MapStyleList do
			if MapStyle == v then
				SpawnWeatherAtClusterList( ClusterData, MapStyle, WeatherEffectsType )
				notfoundMapStyle = false
			end
		end
		
		if notfoundMapStyle and (MapStyle != 'None') then
			LOG(' WARNING: Weather Map style [' .. MapStyle .. '] not defined. Define this as one of the Map Style Definitions. ' .. repr(MapStyleList))
		end
	end
end

function GetWeatherMarkerData(MapScale)
    local markers = ScenarioUtils.GetMarkers()
    local WeatherDefinition = {}
    local ClusterDataList = {}
    local defaultcloudclusterSpread = math.floor(((MapScale[1] + MapScale[2]) * 0.5) * 0.15)

    --Make a list of all the markers in the scenario that are of the markerType
    if markers then
        for k, v in markers do
			-- Read in weather cluster positions and data
            if v.type == 'Weather Generator' then
                table.insert( ClusterDataList, { 
					clusterSpread = v.cloudSpread or defaultcloudclusterSpread, 
					cloudCount = v.cloudCount or 10, 
					cloudCountRange = v.cloudCountRange or 0,
					cloudHeight = v.cloudHeight or 180,
					cloudHeightRange = v.cloudHeightRange or 10,
					position = v.position,
					emitterScale = v.cloudEmitterScale or 1,
					emitterScaleRange = v.cloudEmitterScaleRange or 0,
					forceType = v.ForceType or "None",
					spawnChance = v.spawnChance or 1,
				} )
			-- Read in weather definition
            elseif v.type == 'Weather Definition' then
				if table.getn( WeatherDefinition ) > 0 then
					LOG('WARNING: Weather, multiple weather definitions found. Last read Weather definition will override any previous ones.')
				end					                
				WeatherDefinition = {
					MapStyle = v.MapStyle or "None",
					WeatherTypes = {
						{
							Type = v.WeatherType01 or "None",
							Chance = v.WeatherType01Chance or 0.25,
						},
						{
							Type = v.WeatherType02 or "None",
							Chance = v.WeatherType02Chance or 0.25,
						},
						{
							Type = v.WeatherType03 or "None",
							Chance = v.WeatherType03Chance or 0.25,
						},
						{
							Type = v.WeatherType04 or "None",
							Chance = v.WeatherType04Chance or 0.25,
						},															
					},
					Direction = v.WeatherDriftDirection or {0,0,0},
				}
            end
        end
    end
    return WeatherDefinition,ClusterDataList
end

function GetRandomWeatherEffectType( WeatherDefinition )
	local chance = 0
	for k, v in WeatherDefinition.WeatherTypes do
		chance = chance + v.Chance
	end
	
	local pick = util.GetRandomFloat( 0, chance )
	--LOG( pick )
	chance = 0
	
	for k, v in WeatherDefinition.WeatherTypes do
		--LOG( 'Chance ' .. chance .. 'chance + v.Chance ' .. chance + v.Chance )
		if (chance <= pick) and (pick <= (chance + v.Chance)) then 
			--LOG( 'Pick: ' .. v.Type )
			return v.Type
		else
			chance = chance + v.Chance
		end
	end
	
	return nil
end

function SpawnWeatherAtClusterList( ClusterData, MapStyle, EffectType )
	local numClusters = table.getn( ClusterData )
	local WeatherEffects = MapWeatherList[MapStyle][EffectType]
	
	-- Exit out early, if for some reason, we have no effects defined for this
	if (WeatherEffects == nil) or (WeatherEffects != nil and (table.getn(WeatherEffects) == 0)) then
		return	
	end
	
	-- Parse through cluster position and datal
	for i = 1, numClusters do
		-- Determine whether current cluster should spawn or not
		if ClusterData[i].spawnChance < 1 then
			local pick
			if util.GetRandomFloat( 0, 1 ) > ClusterData[i].spawnChance then
				LOG( 'Cluster ' .. i .. ' No clouds generated ' )
				continue
			end
		end
	
		local clusterSpreadHalfSize = ClusterData[i].clusterSpread * 0.5
		local numCloudsPerCluster = nil
		if ClusterData[i].cloudCountRange != 0 then
			numCloudsPerCluster = util.GetRandomInt(ClusterData[i].cloudCount - ClusterData[i].cloudCountRange / 2,ClusterData[i].cloudCount + ClusterData[i].cloudCountRange / 2)
		else
			numCloudsPerCluster = ClusterData[i].cloudCount
		end
		local clusterEffectMaxScale = ClusterData[i].emitterScale + ClusterData[i].emitterScaleRange
		local clusterEffectMinScale = ClusterData[i].emitterScale - ClusterData[i].emitterScaleRange
	
		LOG( 'Cluster ' .. i .. ', Clouds generated ', numCloudsPerCluster )
		
		-- Calculate weather cluster entity positional range
		local LeftX = ClusterData[i].position[1] - clusterSpreadHalfSize
		local TopZ = ClusterData[i].position[3] - clusterSpreadHalfSize
		local RightX = ClusterData[i].position[1] + clusterSpreadHalfSize
		local BottomZ = ClusterData[i].position[3] + clusterSpreadHalfSize		
		
		-- Get base height and height range
		local BaseHeight = ClusterData[i].position[2] + ClusterData[i].cloudHeight
		local HeightOffset = ClusterData[i].cloudHeightRange	
		
		-- Choose weather cluster effects
		local clusterWeatherEffects = WeatherEffects
		local numEffects = table.getn(WeatherEffects) 
		if ClusterData[i].forceType != "None" then
			clusterWeatherEffects = MapWeatherList[MapStyle][ClusterData[i].forceType] 
			LOG( 'Force Effect Type: ', ClusterData[i].forceType )			
			numEffects = table.getn(clusterWeatherEffects) 
		end
		
		-- Generate Clouds for our cluster
		for j = 0, numCloudsPerCluster do
			local cloud = Entity()
			local x = util.GetRandomInt( LeftX, RightX )
			local y = BaseHeight + util.GetRandomInt(-HeightOffset,HeightOffset)
			local z = util.GetRandomInt( TopZ, BottomZ )
			Warp( cloud, Vector(x,y,z) )
			--LOG( 'Generating cloud at: ', x .. ' ' .. y .. ' ' .. z )	
			
			local EmitterGroupSeed = util.GetRandomInt(1,numEffects)
			local numEmitters = table.getn(clusterWeatherEffects[EmitterGroupSeed])
			local effects = clusterWeatherEffects[EmitterGroupSeed]
			
			for k, v in clusterWeatherEffects[EmitterGroupSeed] do
				CreateEmitterAtBone(cloud,-2,-1,v):ScaleEmitter(util.GetRandomFloat( clusterEffectMaxScale, clusterEffectMinScale ))					
			end
		end
	end
end

-- GenerateWeatherGroups
-- - Generates spread of clusters
--
-- Returns a cluster list table { {xpos, zpos}, ... }, which is just
-- full of unique paired coordinates for the map
function GenerateWeatherGroups( mapScaleX, mapScaleZ, numClusters )
	return GenerateClusterCoords(0,0,mapScaleX, mapScaleZ, numClusters )
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
