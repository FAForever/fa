#this spawns reinforcements, both periodic and one-time.  See the format below.  1 entry = 1 unit to spawm.  Add multiple entires for more of the same unit.

#gwReinforcements = { 
#	periodicUnit = {
#		{ 
#			playerName = 'FunkOff',
#			period = 60,
#			delay = 20,
#			unitNames = {'URL0103','URL0104'},
#		},
#	},
#	initialUnit = {
#		{ 
#			playerName = 'FunkOff',
#			delay = 10,
#			unitNames = {'URL0101','URL0101','URL0106','URL0106'},
#		},
#	},
#	initialStructure = {
#		{ 
#			playerName = 'FunkOff',
#			delay = 10,
#			unitNames = {'URB2104','URB110'},
#		},
#	},
#}

local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')

gwReinforcementsMainThread = function()

	local gwReinforcementList =  import('/lua/gwReinforcementList.lua').gwReinforcements
	
	WaitTicks(10)
	
	local ArmiesList = ScenarioInfo.ArmySetup
	#WARN('armieslist is ' .. repr (ArmiesList))
	
	ScenarioInfo.gwReinforcementSpawnThreads = {}

	SpawnInitialStructures(gwReinforcementList.initialStructure,ArmiesList)
	SpawnInitialReinforcements(gwReinforcementList.initialUnit,ArmiesList)
	SpawnPeriodicReinforcements(gwReinforcementList.periodicUnit,ArmiesList)
end

SpawnInitialStructures = function (gwSpawnList, Armies)
	local counter = 1
	for index, List in gwSpawnList do
		LOG(repr(gwSpawnList))
		for ArmyName, Army in Armies do
			if Army.PlayerName == List.playerName then
				ScenarioInfo.gwReinforcementSpawnThreads[counter] = ForkThread(InitialStructuresSpawnThread,List, Army)
				counter = counter + 1 
			end
		end
	
	end

end

SpawnPeriodicReinforcements = function(gwSpawnList, Armies)
	local counter = 1
	for index, List in gwSpawnList do
		for ArmyName, Army in Armies do
			if Army.PlayerName == List.playerName then
				ScenarioInfo.gwReinforcementSpawnThreads[counter] = ForkThread(PeriodicReinforcementsSpawnThread,List, Army)
				counter = counter + 1 
			end
		end
	
	end

end

SpawnInitialReinforcements =function (gwSpawnList, Armies)
	local counter = 1
	for index, List in gwSpawnList do
		for ArmyName, Army in Armies do
			if Army.PlayerName == List.playerName then
				ScenarioInfo.gwReinforcementSpawnThreads[counter] = ForkThread(InitialReinforcementsSpawnThread,List, Army)
				counter = counter + 1 
			end
		end
	
	end

end

InitialStructuresSpawnThread = function(List, Army)
	#local position = ScenarioUtils.MarkerToPosition(Army.ArmyName)
	
	local delay = List.delay

	#local period = List.period
	local UnitsToSpawn = List.unitNames
	
	local aiBrain = GetArmyBrain(Army.ArmyIndex)
	local posX, posY = aiBrain:GetArmyStartPos()
	
	WARN('aibrain is ' .. repr( aiBrain))
	WARN('list is ' .. repr(List))
	
	WaitSeconds(1)
	
	for index, v in UnitsToSpawn do
		WARN('unit and pos is ' .. repr(v) .. ' and ' .. repr(posX) .. ' and ' .. repr(posY))
        local unit = aiBrain:CreateUnitNearSpot(v, posX, posY)
        if delay > 0 then
        	unit:InitiateActivation(delay)
    	end
        if unit != nil and unit:GetBlueprint().Physics.FlattenSkirt then
            unit:CreateTarmac(true, true, true, false, false)
        end
	end

	
end

PeriodicReinforcementsSpawnThread = function(List, Army)
	local position = ScenarioUtils.MarkerToPosition(Army.ArmyName)
	local delay = List.delay
	local period = List.period
	local UnitsToSpawn = List.unitNames
	 
	
	WaitSeconds(delay)
	
	while not ArmyIsOutOfGame(Army.ArmyIndex) do
		for index, unitName in UnitsToSpawn do
			local NewUnit = CreateUnitHPR(unitName, Army.ArmyIndex, position[1], position[2], (position[3]), 0, 0, 0)
			NewUnit:PlayTeleportInEffects()
			NewUnit:CreateProjectile( '/effects/entities/UnitTeleport01/UnitTeleport01_proj.bp', 0, 1.35, 0, nil, nil, nil):SetCollision(false)
		end
		WaitSeconds(period)
	end
	
	
end

InitialReinforcementsSpawnThread = function(List, Army)
	local position = ScenarioUtils.MarkerToPosition(Army.ArmyName)
	local delay = List.delay
	#local period = List.period
	local UnitsToSpawn = List.unitNames
	 
	
	WaitSeconds(delay)
	
	#while not ArmyIsOutOfGame(Army.ArmyIndex) do
		for index, unitName in UnitsToSpawn do
			local NewUnit = CreateUnitHPR(unitName, Army.ArmyIndex, position[1], position[2], (position[3]), 0, 0, 0)
			NewUnit:PlayTeleportInEffects()
			NewUnit:CreateProjectile( '/effects/entities/UnitTeleport01/UnitTeleport01_proj.bp', 0, 1.35, 0, nil, nil, nil):SetCollision(false)
		end
	#	WaitSeconds(period)
	#end
	
	
end
