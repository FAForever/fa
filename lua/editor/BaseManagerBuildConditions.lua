-----------------------------------------------------------------
-- File     :  /cdimage/lua/editor/EconomyBuildConditions.lua
-- Author(s): Dru Staltman, John Comes
-- Summary  : Generic AI Platoon Build Conditions
--           Build conditions always return true or false
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local AIUtils = import("/lua/ai/aiutilities.lua")
local Utilities = import("/lua/utilities.lua")

local pairs = pairs
local tableEmpty = table.empty
local tableGetn = table.getn
local EntityCategoryContains, ParseEntityCategory = EntityCategoryContains, ParseEntityCategory

--Cached categories
local t2factories = categories.FACTORY * categories.TECH2
local t3factories = categories.FACTORY * categories.TECH3

---Checks the base template of the base manager to see if any structure is not built.
---@param aiBrain CampaignAIBrain
---@param baseName string
---@return boolean
function NeedAnyStructure(aiBrain, baseName)
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then return false end

    for _, data in pairs(bManager.LevelNames) do
        if data.Priority <= 0 then continue end

        local levelName = baseName .. data.Name
        local buildTemplate = aiBrain.BaseTemplates[levelName].Template
        local buildList = aiBrain.BaseTemplates[levelName].List
        local buildCounter = aiBrain.BaseTemplates[levelName].BuildCounter

        if not buildTemplate or not buildList then continue end

        for _, entry in pairs(buildTemplate) do
            local structureType = entry[1][1]
            if not bManager:CheckStructureBuildable(structureType) then continue end

            ---@type BlueprintId|nil
            local category
            for catName, catData in pairs(buildList) do
                if catData.StructureType == structureType then
                    category = catData.StructureCategory
                    break
                end
            end
            if not category then continue end

            -- Iterate through build locations
            for i = 2, tableGetn(entry) do
                ---@type Vector
                local pos = entry[i]
                if aiBrain:CanBuildStructureAt(category, {pos[1], 0, pos[2]}) and bManager:CheckUnitBuildCounter(pos, buildCounter) then
                    return true
                end
            end
        end
    end
    return false
end

---Compares number of `category` units belonging to `aiBrain` that are in within the base radius to `varName`
---@param aiBrain CampaignAIBrain
---@param baseName string
---@param category EntityCategory
---@param varName? string|integer If `nil` compares to `BaseManager.EngineerQuantity`, `string` to variable in `ScenarioInfo.VarTable`, `integer` to found unit count.
---@return boolean
function NumUnitsLessNearBase(aiBrain, baseName, category, varName)
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then return false end

    local unitList = aiBrain:GetUnitsAroundPoint(category, bManager.Position, bManager.Radius, 'Ally')
    local count = 0
    for _, unit in pairs(unitList) do
        if unit:GetAIBrain() == aiBrain then
            count = count + 1
        end
    end
    if not varName then
        if count < bManager.EngineerQuantity then
            return true
        end
    elseif type(varName) == 'string' then
        if count < ScenarioInfo.VarTable[varName] then
            return true
        end
    else
        if count < varName then
            return true
        end
    end
    return false
end

---Returns `true` when number of active engineers in the base is less than set maximum.
---@param aiBrain CampaignAIBrain
---@param baseName string
---@return boolean
function BaseManagerNeedsEngineers(aiBrain, baseName)
	local bManager = aiBrain.BaseManagers[baseName]
	return bManager and bManager.EngineerQuantity > bManager.CurrentEngineerCount
end

---Returns `true` when any of the expansions has less engineers than set in the expansion data.
---@param aiBrain CampaignAIBrain
---@param baseName string
---@return boolean
function ExpansionBasesNeedEngineers(aiBrain, baseName)
    local bManager = aiBrain.BaseManagers[baseName]
    if not (bManager and bManager.ExpansionBaseData) then return false end

    for _, eData in pairs(bManager.ExpansionBaseData) do
        local ebManager = aiBrain.BaseManagers[eData.BaseName]
        if not ebManager then continue end

        local count = ebManager.CurrentEngineerCount
        count = count + eData.IncomingEngineers
        if count < eData.Engineers then
            return true
        end
    end
    return false
end

---Check if specific expansion base needs engineers
---@param aiBrain CampaignAIBrain
---@param baseName string
---@param eBaseName string
---@return boolean
function NumEngiesInExpansionBase(aiBrain, baseName, eBaseName)
    local bManager = aiBrain.BaseManagers[baseName]
    local ebManager = aiBrain.BaseManagers[eBaseName]
    if not (bManager and ebManager and bManager.ExpansionBaseData) then return false end

    for _, eData in pairs(bManager.ExpansionBaseData) do
        if eData.BaseName ~= eBaseName then continue end

        local count = ebManager.CurrentEngineerCount
        count = count + eData.IncomingEngineers
        if count < eData.Engineers then
            return true
        end
    end
    return false
end

---Currently unsed, as ACU is treated as engineer in the base manager.
---@param aiBrain CampaignAIBrain
---@param baseName string
---@return boolean
function CDRInPoolNeedAnyStructure(aiBrain, baseName)
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then return false end

    local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
    ---@type ACUUnit|nil
    local cdrUnit
    for _, v in pool:GetPlatoonUnits() do
        if not v.Dead and EntityCategoryContains(categories.COMMAND, v) then
            cdrUnit = v
        end
    end

    if not cdrUnit then return false end

    for _, data in pairs(bManager.LevelNames) do
        if data.Priority <= 0 then continue end

        local levelName = baseName .. data.Name
        local buildTemplate = aiBrain.BaseTemplates[levelName].Template
        local buildList = aiBrain.BaseTemplates[levelName].List
        if not buildTemplate or not buildList then return false end

        for _, entry in pairs(buildTemplate) do
            -- Get the building to build
            local category
            for catName, catData in buildList do
                if catData.StructureType == entry[1][1] then
                    category = catData.StructureCategory
                    break
                end
            end
            if not category or not cdrUnit:CanBuild(category) then continue end

            -- Iterate through build locations
            for i = 2, tableGetn(entry) do
                ---@type Vector
                local pos = entry[i]
                if aiBrain:CanBuildStructureAt(category, {pos[1], 0, pos[2]}) then
                    return true
                end
            end
        end
    end
    return false
end

---Currently unsed, as sACU is treated as engineer in the base manager.
---@param aiBrain CampaignAIBrain
---@param baseName string
---@return boolean
function SubCDRInPoolNeedAnyStructure(aiBrain, baseName)
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then return false end

    local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
    ---@type ACUUnit|nil
    local cdrUnit
    for _, v in pool:GetPlatoonUnits() do
        if not v.Dead and EntityCategoryContains(categories.SUBCOMMANDER, v) then
            cdrUnit = v
        end
    end

    if not cdrUnit then return false end

    for _, data in pairs(bManager.LevelNames) do
        if data.Priority <= 0 then continue end

        local levelName = baseName .. data.Name
        local buildTemplate = aiBrain.BaseTemplates[levelName].Template
        local buildList = aiBrain.BaseTemplates[levelName].List
        if not buildTemplate or not buildList then return false end

        for _, entry in pairs(buildTemplate) do
            -- Get the building to build
            local category
            for catName, catData in buildList do
                if catData.StructureType == entry[1][1] then
                    category = catData.StructureCategory
                    break
                end
            end
            if not category or not cdrUnit:CanBuild(category) then continue end

            -- Iterate through build locations
            for i = 2, tableGetn(entry) do
                ---@type Vector
                local pos = entry[i]
                if aiBrain:CanBuildStructureAt(category, {pos[1], 0, pos[2]}) then
                    return true
                end
            end
        end
    end
    return false
end

---Returns `true` if the base construction units are building any of the passed `catTable` units.
---@param aiBrain CampaignAIBrain
---@param baseName string
---@param catTable string[] List of category strings to test, e.g. `{'MOBILE LAND', 'ALLUNITS' }`
---@return boolean
function CategoriesBeingBuilt(aiBrain, baseName, catTable)
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then return false end

    local basePos = bManager.Position
    local baseRad = bManager.Radius
    -- Faster to compare squared distances
    local baseRadSquared = baseRad * baseRad

    local unitsBuilding = aiBrain:GetListOfUnits(categories.CONSTRUCTION, false)
    for _, unit in pairs(unitsBuilding) do
        if unit.Dead or not unit:IsUnitState('Building') then continue end

        local buildingUnit = unit.UnitBeingBuilt
        if not buildingUnit or buildingUnit.Dead then continue end

        for _, buildeeCat in pairs(catTable) do
            local buildCat = ParseEntityCategory(buildeeCat)
            if not EntityCategoryContains(buildCat, buildingUnit) then continue end

            local unitPos = unit:GetPosition()
            if unitPos and Utilities.XZDistanceTwoVectorsSquared(unitPos, basePos) < baseRadSquared then
                return true
            end
        end
    end
    return false
end

---Checks if the base has any T3 / T2 factories based on `level`.
---
---Always returns true for when `level` is `1`
---@param aiBrain CampaignAIBrain
---@param level number Factory tech level
---@param baseName string
---@return boolean
function HighestFactoryLevel(aiBrain, level, baseName)
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then return false end

    local position = bManager.Position
    local radius = bManager.Radius
    local t3fac = AIUtils.GetOwnUnitsAroundPoint(aiBrain, t3factories, position, radius)
    local t2fac = AIUtils.GetOwnUnitsAroundPoint(aiBrain, t2factories, position, radius)
    if table.getn(t3fac) > 0 then
        return level == 3
    elseif table.getn(t2fac) > 0 then
        return level == 2
    end

    return true
end

--- Returns true when the highest tier factory matches `level` 
--- Example: level = 2, type = "Land". Platoon wont be built if the base has T3 land factory.
---@param aiBrain CampaignAIBrain
---@param level number
---@param baseName string
---@param type "Air"|"Land"|"Sea"
---@return boolean
function HighestFactoryLevelType(aiBrain, level, baseName, type)
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then return false end

    local position = bManager.Position
    local radius = bManager.Radius
    local catCheck
    if type == 'Air' then
        catCheck = categories.AIR
    elseif type == 'Land' then
        catCheck = categories.LAND
    elseif type == 'Sea' then
        catCheck = categories.NAVAL
    end

    local t3fac = AIUtils.GetOwnUnitsAroundPoint(aiBrain, t3factories * catCheck, position, radius)
    local t2fac = AIUtils.GetOwnUnitsAroundPoint(aiBrain, t2factories * catCheck, position, radius)
    if table.getn(t3fac) > 0 then
        return level == 3
    elseif table.getn(t2fac) > 0 then
        return level == 2
    end

    return true
end

---@param aiBrain CampaignAIBrain
---@param techLevel number
---@param engQuantity number
---@param pType string
---@param baseName string
---@return boolean
function FactoryCountAndNeed(aiBrain, techLevel, engQuantity, pType, baseName)
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then return false end

    local facCat = ParseEntityCategory('FACTORY * TECH'..techLevel)
    local facList = AIUtils.GetOwnUnitsAroundPoint(aiBrain, facCat, bManager.Position, bManager.Radius)
    local typeCount = {Air = 0, Land = 0, Sea = 0, }
    for k, v in facList do
        if EntityCategoryContains(categories.AIR, v) then
            typeCount['Air'] = typeCount['Air'] + 1
        elseif EntityCategoryContains(categories.LAND, v) then
            typeCount['Land'] = typeCount['Land'] + 1
        elseif EntityCategoryContains(categories.NAVAL, v) then
            typeCount['Sea'] = typeCount['Sea'] + 1
        end
    end

    if typeCount[pType] >= typeCount['Air'] and typeCount[pType] >= typeCount['Land'] and typeCount[pType] >= typeCount['Sea'] then
        if typeCount[pType] == engQuantity and bManager.EngineerQuantity >= (bManager.CurrentEngineerCount + bManager:GetEngineersBuilding() + engQuantity) then
            return true
        elseif bManager.EngineerQuantity - (bManager.CurrentEngineerCount + bManager:GetEngineersBuilding() + engQuantity) == 0 and typeCount[pType] >= engQuantity then
            return true
        elseif bManager.EngineerQuantity - (bManager.CurrentEngineerCount + bManager:GetEngineersBuilding() + engQuantity) > 0 and engQuantity == 5 and typeCount[pType] >= 5 then
            return true
        end
    end

    return false
end

---@param aiBrain CampaignAIBrain
---@param platoonData PlatoonData
function BaseManagerEngineersStarted(aiBrain, platoonData)
    aiBrain.BaseManagers[platoonData.BaseName]:SetEngineersBuilding(platoonData.NumBuilding)
end

---@param aiBrain CampaignAIBrain
---@param baseName string
---@return boolean
function UnfinishedBuildingsCheck(aiBrain, baseName)
    local bManager = aiBrain.BaseManagers[baseName]

	-- Return if the BaseManager doesn't exist, or the list is empty, or all buildings are finished
    if not bManager or tableEmpty(bManager.UnfinishedBuildings) then
        return false
    end

    -- Check list
    local armyIndex = aiBrain:GetArmyIndex()
    local beingBuiltList = {}
    local buildingEngs = aiBrain:GetListOfUnits(categories.ENGINEER, false)
    for _, v in buildingEngs do
        local buildingUnit = v.UnitBeingBuilt
        if buildingUnit and buildingUnit.UnitName then
            beingBuiltList[buildingUnit.UnitName] = true
        end
    end

    for unitName, _ in bManager.UnfinishedBuildings do
        local unit = ScenarioInfo.UnitNames[armyIndex][unitName]
        if unit and not unit.Dead then
            if not beingBuiltList[unitName] then
                return true
            end
        end
    end
    return false
end

---@param aiBrain CampaignAIBrain
---@param baseName string
---@return boolean
function BaseActive(aiBrain, baseName)
	local bManager = aiBrain.BaseManagers[baseName]
	return bManager and bManager.Active
end

--- Deprecated, it was supposed to be a condition for an unfinished reclaim function/thread
---@param aiBrain CampaignAIBrain
---@param baseName string
---@return boolean
function BaseReclaimEnabled(aiBrain, baseName)
	local bManager = aiBrain.BaseManagers[baseName]
    return bManager and bManager.FunctionalityStates.EngineerReclaiming
end

---@param aiBrain CampaignAIBrain
---@param baseName string
---@return boolean
function BasePatrollingEnabled(aiBrain, baseName)
	local bManager = aiBrain.BaseManagers[baseName]
    return bManager and bManager.FunctionalityStates.Patrolling
end

---@param aiBrain CampaignAIBrain
---@param baseName string
---@return boolean
function BaseBuildingEngineers(aiBrain, baseName)
	local bManager = aiBrain.BaseManagers[baseName]
	return bManager and bManager.FunctionalityStates.BuildEngineers
end

---@param aiBrain CampaignAIBrain
---@param baseName string
---@return boolean
function BaseEngineersEnabled(aiBrain, baseName)
	local bManager = aiBrain.BaseManagers[baseName]
	return bManager and bManager.FunctionalityStates.Engineers
end

---@param aiBrain CampaignAIBrain
---@param baseName string
---@return boolean
function LandScoutingEnabled(aiBrain, baseName)
	local bManager = aiBrain.BaseManagers[baseName]
	return bManager and bManager.FunctionalityStates.LandScouting
end

---@param aiBrain CampaignAIBrain
---@param baseName string
---@return boolean
function AirScoutingEnabled(aiBrain, baseName)
	local bManager = aiBrain.BaseManagers[baseName]
	return bManager and bManager.FunctionalityStates.AirScouting
end

---@param aiBrain CampaignAIBrain
---@param baseName string
---@return boolean
function ExpansionBasesEnabled(aiBrain, baseName)
	local bManager = aiBrain.BaseManagers[baseName]
	return bManager and bManager.FunctionalityStates.ExpansionBases
end

---@param aiBrain CampaignAIBrain
---@param baseName string
---@return boolean
function TMLsEnabled(aiBrain, baseName)
	local bManager = aiBrain.BaseManagers[baseName]
    return bManager and bManager.FunctionalityStates.TMLs
end

---@param aiBrain CampaignAIBrain
---@param baseName string
---@return boolean
function NukesEnabled(aiBrain, baseName)
    local bManager = aiBrain.BaseManagers[baseName]
    return bManager and bManager.FunctionalityStates.Nukes
end

-- Moved Unused Imports for mod compatibility

local ScenarioFramework = import("/lua/scenarioframework.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
