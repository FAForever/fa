--- Class CAiBrain
-- @classmod Sim.CAiBrain

---
--  CAiBrain:AssignThreatAtPosition(position, threat, [decay], [threattype])
function CAiBrain:AssignThreatAtPosition(position,  threat,  [decay],  [threattype])
end

---
--  CAiBrain:AssignUnitsToPlatoon()
function CAiBrain:AssignUnitsToPlatoon()
end

---
--  brain:BuildPlatoon()
function CAiBrain:BuildPlatoon()
end

---
--  brain:BuildStructure(builder, structureName, locationInfo)
function CAiBrain:BuildStructure(builder,  structureName,  locationInfo)
end

---
--  brain:BuildUnit()
function CAiBrain:BuildUnit()
end

---
--  brain:CanBuildPlatoon()
function CAiBrain:CanBuildPlatoon()
end

---
--  brain:CanBuildStructureAt(blueprint, location)
function CAiBrain:CanBuildStructureAt(blueprint,  location)
end

---
--  CAiBrain:CheckBlockingTerrain( startPos, endPos, arcType )
function CAiBrain:CheckBlockingTerrain(startPos,  endPos,  arcType)
end

---
--  brain:CreateResourceBuildingNearest(structureName, posX, posY)
function CAiBrain:CreateResourceBuildingNearest(structureName,  posX,  posY)
end

---
--  brain:CreateUnitNearSpot(unitName, posX, posY)
function CAiBrain:CreateUnitNearSpot(unitName,  posX,  posY)
end

---
--  brain:DecideWhatToBuild(builder, type, buildingTypes)
function CAiBrain:DecideWhatToBuild(builder,  type,  buildingTypes)
end

---
--  CAiBrain:DisbandPlatoon()
function CAiBrain:DisbandPlatoon()
end

---
--  CAiBrain:DisbandPlatoonUniquelyNamed()
function CAiBrain:DisbandPlatoonUniquelyNamed()
end

---
--  CAiBrain:FindClosestArmyWithBase()
function CAiBrain:FindClosestArmyWithBase()
end

---
--  brain:FindPlaceToBuild(type, structureName, buildingTypes, relative, builder, optIgnoreAlliance, optOverridePosX, optOverridePosZ, optIgnoreThreatOver)
function CAiBrain:FindPlaceToBuild(type,  structureName,  buildingTypes,  relative,  builder,  optIgnoreAlliance,  optOverridePosX,  optOverridePosZ,  optIgnoreThreatOver)
end

---
--  brain:FindUnit(unitCategory, needToBeIdle) -- Return an unit that matches the unit name (can specify idle or not)
function CAiBrain:FindUnit(unitCategory,  needToBeIdle)
end

---
--  brain:FindUnitToUpgrade(upgradeList) -- Return a unit and it's upgrade blueprint
function CAiBrain:FindUnitToUpgrade(upgradeList)
end

---
--  brain:FindUpgradeBP(unitName, upgradeList) -- Return an upgrade blueprint for the unit passed in
function CAiBrain:FindUpgradeBP(unitName,  upgradeList)
end

---
--  Returns the ArmyIndex of the army represented by this brain
function CAiBrain:GetArmyIndex()
end

---
--  brain:GetArmyStartPos()
function CAiBrain:GetArmyStartPos()
end

---
--  brain:GetArmyStat(StatName,defaultValue)
function CAiBrain:GetArmyStat(StatName, defaultValue)
end

---
--  CAiBrain:GetAttackVectors()
function CAiBrain:GetAttackVectors()
end

---
--  brain:GetAvailableFactories()
function CAiBrain:GetAvailableFactories()
end

---
--  Return a blueprint stat filtered by category
function CAiBrain:GetBlueprintStat()
end

---
--  Return this brain's current enemy
function CAiBrain:GetCurrentEnemy()
end

---
--  Return how many units of the given categories exist
function CAiBrain:GetCurrentUnits()
end

---
--  CAiBrain:GetEconomyIncome()
function CAiBrain:GetEconomyIncome()
end

---
--  CAiBrain:GetEconomyRequested()
function CAiBrain:GetEconomyRequested()
end

---
--  CAiBrain:GetEconomyStored()
function CAiBrain:GetEconomyStored()
end

---
--  CAiBrain:GetEconomyStoredRatio()
function CAiBrain:GetEconomyStoredRatio()
end

---
--  CAiBrain:GetEconomyTrend()
function CAiBrain:GetEconomyTrend()
end

---
--  CAiBrain:GetEconomyUsage()
function CAiBrain:GetEconomyUsage()
end

---
--  Returns the faction of the army represented by this brain
function CAiBrain:GetFactionIndex()
end

---
--  CAiBrain:GetHighestThreatPosition( ring, restriction, [threatType], [armyIndex] )threatposition, threatvalue = GetHighestThreatPosition( rings, restriction, [threatType], [armyIndex] )Always reports a threatvalue of zero for Allies or self
function CAiBrain:GetHighestThreatPosition(ring,  restriction,  [threatType],  [armyIndex])
end

---
--  brain:GetListOfUnits(entityCategory, needToBeIdle, requireBuilt)     requireBuilt flag defaults to false which excludes units that are NOT finished
function CAiBrain:GetListOfUnits(entityCategory,  needToBeIdle,  requireBuilt)
end

---
--  CAiBrain:GetMapWaterRatio()
function CAiBrain:GetMapWaterRatio()
end

---
--  CAiBrain:GetNoRushTicks()
function CAiBrain:GetNoRushTicks()
end

---
--  GetNumPlatoonsTemplateNamed
function CAiBrain:GetNumPlatoonsTemplateNamed()
end

---
--  GetNumPlatoonsWithAI
function CAiBrain:GetNumPlatoonsWithAI()
end

---
--  CAiBrain:GetNumUnitsAroundPoint()
function CAiBrain:GetNumUnitsAroundPoint()
end

---
--  Return the personality for this brain to use
function CAiBrain:GetPersonality()
end

---
--  CAiBrain:GetPlatoonUniquelyNamed()
function CAiBrain:GetPlatoonUniquelyNamed()
end

---
--  CAiBrain:GetPlatoonsList()
function CAiBrain:GetPlatoonsList()
end

---
--  CAiBrain:GetThreatAtPosition(position, ring, restriction, [threatType], [armyIndex] )
function CAiBrain:GetThreatAtPosition(position,  ring,  restriction,  [threatType],  [armyIndex])
end

---
--  CAiBrain:GetThreatBetweenPositions( position, position, restriction, [threatType], [armyIndex] )
function CAiBrain:GetThreatBetweenPositions(position,  position,  restriction,  [threatType],  [armyIndex])
end

---
--  CAiBrain:GetThreatsAroundPosition( position, ring, restriction, [threatType], [armyIndex] )
function CAiBrain:GetThreatsAroundPosition(position,  ring,  restriction,  [threatType],  [armyIndex])
end

---
--  blueprint = brain:GetUnitBlueprint(bpName)
function CAiBrain:GetUnitBlueprint(bpName)
end

---
--  CAiBrain:GetUnitsAroundPoint()
function CAiBrain:GetUnitsAroundPoint()
end

---
--  GiveResource(type,amount)
function CAiBrain:GiveResource(type, amount)
end

---
--  GiveStorage(type,amount)
function CAiBrain:GiveStorage(type, amount)
end

---
--  brain:IsAnyEngineerBuilding(category)
function CAiBrain:IsAnyEngineerBuilding(category)
end

---
--  Returns true if opponent AI should be running
function CAiBrain:IsOpponentAIRunning()
end

---
--  CAiBrain:MakePlatoon()
function CAiBrain:MakePlatoon()
end

---
--  brain:NumCurrentlyBuilding( entityCategoryOfBuildee, entityCategoryOfBuilder )
function CAiBrain:NumCurrentlyBuilding(entityCategoryOfBuildee,  entityCategoryOfBuilder)
end

---
--  CAiBrain:PickBestAttackVector()
function CAiBrain:PickBestAttackVector()
end

---
--  CAiBrain:PlatoonExists()
function CAiBrain:PlatoonExists()
end

---
--  Remove an army stats trigger
function CAiBrain:RemoveArmyStatsTrigger()
end

---
--  SetArmyStat(statname,val)
function CAiBrain:SetArmyStat(statname, val)
end

---
--  Sets an army stat trigger
function CAiBrain:SetArmyStatsTrigger()
end

---
--  Set the current enemy for this brain to attack
function CAiBrain:SetCurrentEnemy()
end

---
--  Set the current plan for this brain to run
function CAiBrain:SetCurrentPlan()
end

---
--  SetGreaterOf(statname,val)
function CAiBrain:SetGreaterOf(statname, val)
end

---
--  SetResourceSharing(bool)
function CAiBrain:SetResourceSharing(bool)
end

---
--  CAiBrain:SetUpAttackVectorsToArmy()
function CAiBrain:SetUpAttackVectorsToArmy()
end

---
--  taken = TakeResource(type,amount)
function CAiBrain:TakeResource(type, amount)
end

---
-- 
function CAiBrain:moho.aibrain_methods()
end

