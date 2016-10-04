--#****************************************************************************
--#**
--#**  File     :  /cdimage/lua/editor/EconomyBuildConditions.lua
--#**  Author(s): Dru Staltman, John Comes
--#**
--#**  Summary  : Generic AI Platoon Build Conditions
--#**             Build conditions always return true or false
--#**
--#**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--#****************************************************************************
local AIUtils = import('/lua/ai/aiutilities.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')

--##############################################################################################################
--# function: NeedAnyStructure = BuildCondition	doc = "Please work function docs."
--#
--# parameter 0: string	aiBrain		= "default_brain"
--# parameter 1: string	baseName = "base_name"
--#
--##############################################################################################################
function NeedAnyStructure(aiBrain, baseName)
    if not aiBrain.BaseManagers[baseName] then
        return false
    end
    
    local bManager = aiBrain.BaseManagers[baseName]
    
    
    for dNum,data in bManager.LevelNames do
        if data.Priority > 0 then
            local buildTemplate = aiBrain.BaseTemplates[baseName .. data.Name].Template
            local buildList = aiBrain.BaseTemplates[baseName .. data.Name].List
            local buildCounter = aiBrain.BaseTemplates[baseName .. data.Name].BuildCounter
            
            if not buildTemplate or not buildList then
                return false
            end
            for k,v in buildTemplate do
                if bManager:CheckStructureBuildable(v[1][1]) then
                    -- get the building to build
                    local category
                    for catName,catData in buildList do
                        if catData.StructureType == v[1][1] then
                            category = catData.StructureCategory
                            break
                        end
                    end
                    -- iterate through build locations
                    for num, location in v do
                        if category and num > 1 then
                            -- Check if it can be built and then build
                            if aiBrain:CanBuildStructureAt( category, {location[1], 0, location[2]} ) 
                            and bManager:CheckUnitBuildCounter(location, buildCounter) then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

--##############################################################################################################
--# function: NumUnitsLessNearBase = BuildCondition	doc = "Please work function docs."
--#
--# parameter 0: string	aiBrain         = "default_brain"
--# parameter 1: string	baseName        = "MAIN"			doc = "docs for param1"
--# parameter 2: expr   category        = categories.ALLUNITS
--# parameter 3: string   varName             = "VariableName"
--#
--##############################################################################################################
function NumUnitsLessNearBase( aiBrain, baseName, category, varName )
    if aiBrain.BaseManagers[baseName] == nil then
        return false
    else
        local base = aiBrain.BaseManagers[baseName]
        local unitList = aiBrain:GetUnitsAroundPoint(category, base:GetPosition(), base:GetRadius(), 'Ally' )
        local count = 0
        for i,unit in unitList do
            if unit:GetAIBrain() == aiBrain then
                count = count + 1
            end
        end
        if not varName then
            if count < base.EngineerQuantity then
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
end

function BaseManagerNeedsEngineers(aiBrain, baseName)
    if not aiBrain.BaseManagers[baseName] then
        return false
    end
    local bManager = aiBrain.BaseManagers[baseName]
    if bManager:GetMaximumEngineers() > bManager:GetCurrentEngineerCount() then
        return true
    end
    return false
end

function ExpansionBasesNeedEngineers(aiBrain, baseName)
    if not aiBrain.BaseManagers[baseName] then
        return false
    end
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager.ExpansionBaseData then
        return false
    end
    for num,eData in bManager.ExpansionBaseData do
        local eBaseName = eData.BaseName
        local base = aiBrain.BaseManagers[eBaseName]
        if base and base:GetPosition() and base:GetRadius() then
            local count = base:GetCurrentEngineerCount()
            count = count + eData.IncomingEngineers
            if count < eData.Engineers then
                return true
            end
        end
    end
    return false
end

-- Check if specific expansion base needs engineers
function NumEngiesInExpansionBase(aiBrain, baseName, eBaseName)
    if not aiBrain.BaseManagers[baseName] or not aiBrain.BaseManagers[eBaseName] then
        return false
    end
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager.ExpansionBaseData then
        return false
    end
    for num,eData in bManager.ExpansionBaseData do
        if eData.BaseName == eBaseName then
            local base = aiBrain.BaseManagers[eBaseName]
            if base and base:GetPosition() and base:GetRadius() then
                local count = base:GetCurrentEngineerCount()
                count = count + eData.IncomingEngineers
                if count < eData.Engineers then
                    return true
                end
            end
        end
    end
    return false
end

function CDRInPoolNeedAnyStructure(aiBrain, baseName)
    if not aiBrain.BaseManagers[baseName] then
        return false
    end
    local pool = aiBrain:GetPlatoonUniquelyNamed( 'ArmyPool' )
    local cdrUnit = false
    for k,v in pool:GetPlatoonUnits() do
        if not v:IsDead() and EntityCategoryContains( categories.COMMAND, v ) then
            cdrUnit = v
        end
    end
    if not cdrUnit then
        return false
    end
    for dNum,data in aiBrain.BaseManagers[baseName].LevelNames do
        if data.Priority > 0 then
            local buildTemplate = aiBrain.BaseTemplates[baseName .. data.Name].Template
            local buildList = aiBrain.BaseTemplates[baseName .. data.Name].List
            if not buildTemplate or not buildList then
                return false
            end
            for k,v in buildTemplate do
                -- get the building to build
                local category
                for catName,catData in buildList do
                    if catData.StructureType == v[1][1] then
                        category = catData.StructureCategory
                        break
                    end
                end
                if category and cdrUnit:CanBuild(category) then
                    -- iterate through build locations
                    for num, location in v do
                        -- Check if it can be built and then build
                        if num > 1 and aiBrain:CanBuildStructureAt( category, {location[1], 0, location[2]} ) then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

function SubCDRInPoolNeedAnyStructure(aiBrain, baseName)
    if not aiBrain.BaseManagers[baseName] then
        return false
    end
    local pool = aiBrain:GetPlatoonUniquelyNamed( 'ArmyPool' )
    local cdrUnit = false
    for k,v in pool:GetPlatoonUnits() do
        if not v:IsDead() and EntityCategoryContains( categories.SUBCOMMANDER, v ) then
            cdrUnit = v
        end
    end
    if not cdrUnit then
        return false
    end
    for dNum,data in aiBrain.BaseManagers[baseName].LevelNames do
        if data.Priority > 0 then
            local buildTemplate = aiBrain.BaseTemplates[baseName .. data.Name].Template
            local buildList = aiBrain.BaseTemplates[baseName .. data.Name].List
            if not buildTemplate or not buildList then
                return false
            end
            for k,v in buildTemplate do
                -- get the building to build
                local category
                for catName,catData in buildList do
                    if catData.StructureType == v[1][1] then
                        category = catData.StructureCategory
                        break
                    end
                end
                if category and cdrUnit:CanBuild(category) then
                    -- iterate through build locations
                    for num, location in v do
                        -- Check if it can be built and then build
                        if num > 1 and aiBrain:CanBuildStructureAt( category, {location[1], 0, location[2]} ) then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

function CategoriesBeingBuilt(aiBrain, baseName, catTable)
    if not aiBrain.BaseManagers[baseName] then
        return false
    end

    local basePos = aiBrain.BaseManagers[baseName]:GetPosition()
    local baseRad = aiBrain.BaseManagers[baseName]:GetRadius()
    if not basePos or not baseRad then
        return false
    end

    local unitsBuilding = aiBrain:GetListOfUnits( categories.CONSTRUCTION, false )
    for unitNum, unit in unitsBuilding do
        if not unit:IsDead() and unit:IsUnitState('Building') then
            local buildingUnit = unit.UnitBeingBuilt
            if buildingUnit and not buildingUnit:IsDead() then
                for catNum, buildeeCat in catTable do
                    local buildCat = ParseEntityCategory(buildeeCat)
                    if EntityCategoryContains( buildCat, buildingUnit ) then
                        local unitPos = unit:GetPosition()
                        if unitPos and VDist2(basePos[1], basePos[3], unitPos[1], unitPos[3]) < baseRad then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end


function HighestFactoryLevel( aiBrain, level, baseName )
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then
        return false
    end
    local t3FacList = AIUtils.GetOwnUnitsAroundPoint( aiBrain, categories.FACTORY * categories.TECH3, bManager:GetPosition(), bManager:GetRadius())
    local t2FacList = AIUtils.GetOwnUnitsAroundPoint( aiBrain, categories.FACTORY * categories.TECH2, bManager:GetPosition(), bManager:GetRadius())
    if t3FacList and table.getn(t3FacList) > 0 then
        if level == 3 then
            return true
        else
            return false
        end
    elseif t2FacList and table.getn(t2FacList) > 0 then
        if level == 2 then
            return true
        else
            return false
        end
    end
    return true
end

function FactoryCountAndNeed( aiBrain, techLevel, engQuantity, pType, baseName )
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then
        return false
    end
    local facCat = ParseEntityCategory( 'FACTORY * TECH'..techLevel )
    local facList = AIUtils.GetOwnUnitsAroundPoint( aiBrain, facCat, bManager:GetPosition(), bManager:GetRadius())
    local typeCount = { Air = 0, Land = 0, Sea = 0, }
    for k,v in facList do
        if EntityCategoryContains( categories.AIR, v ) then
            typeCount['Air'] = typeCount['Air'] + 1
        elseif EntityCategoryContains( categories.LAND, v ) then
            typeCount['Land'] = typeCount['Land'] + 1
        elseif EntityCategoryContains( categories.NAVAL, v ) then
            typeCount['Sea'] = typeCount['Sea'] + 1
        end
    end

    if typeCount[pType] >= typeCount['Air'] and typeCount[pType] >= typeCount['Land'] and typeCount[pType] >= typeCount['Sea'] then
        if typeCount[pType] == engQuantity and bManager:GetMaximumEngineers() >= ( bManager:GetCurrentEngineerCount() + bManager:GetEngineersBuilding() + engQuantity ) then
            return true
        elseif bManager:GetMaximumEngineers() - ( bManager:GetCurrentEngineerCount() + bManager:GetEngineersBuilding() + engQuantity ) == 0 and typeCount[pType] >= engQuantity then
            return true
        elseif bManager:GetMaximumEngineers() - ( bManager:GetCurrentEngineerCount() + bManager:GetEngineersBuilding() + engQuantity ) > 0 and engQuantity == 5 and typeCount[pType] >= 5 then
            return true
        end
    end

    return false
end

function BaseManagerEngineersStarted( aiBrain, platoonData )
    aiBrain.BaseManagers[platoonData.BaseName]:SetEngineersBuilding(platoonData.NumBuilding)
end

function UnfinishedBuildingsCheck( aiBrain, baseName )
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then
        return false
    end
    -- Return out if the list is empty or all buildings are finished
    if table.getn(bManager.UnfinishedBuildings) == 0 then
        return false
    else
        local allFinished = true
        for k,v in bManager.UnfinishedBuildings do
            if v then
               allFinished = false
               break
            end
        end
        if allFinished then
            return false
        end
    end

    -- Check list
    local armyIndex = bManager.AIBrain:GetArmyIndex()
    local beingBuiltList = {}
    local buildingEngs = bManager.AIBrain:GetListOfUnits( categories.ENGINEER, false )
    for k,v in buildingEngs do
        local buildingUnit = v.UnitBeingBuilt
        if buildingUnit and buildingUnit.UnitName then
            beingBuiltList[buildingUnit.UnitName] = true
        end
    end
    for k,v in bManager.UnfinishedBuildings do
        if v and ScenarioInfo.UnitNames[armyIndex][k] and not ScenarioInfo.UnitNames[armyIndex][k]:IsDead() then
            if not beingBuiltList[k] then
                return true
            end
        end
    end
    return false
end

function HighestFactoryLevelType( aiBrain, level, baseName, type )
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then
        return false
    end
    local catCheck
    if type == 'Air' then
        catCheck = categories.AIR
    elseif type == 'Land' then
        catCheck = categories.LAND
    elseif type == 'Sea' then
        catCheck = categories.NAVAL
    end
    local t3FacList = AIUtils.GetOwnUnitsAroundPoint( aiBrain, categories.FACTORY * categories.TECH3 * catCheck, bManager:GetPosition(), bManager:GetRadius())
    local t2FacList = AIUtils.GetOwnUnitsAroundPoint( aiBrain, categories.FACTORY * categories.TECH2 * catCheck, bManager:GetPosition(), bManager:GetRadius())
    if t3FacList and table.getn(t3FacList) > 0 then
        if level == 3 then
            return true
        else
            return false
        end
    elseif t2FacList and table.getn(t2FacList) > 0 then
        if level == 2 then
            return true
        else
            return false
        end
    end
    return true
end

function BaseActive( aiBrain, baseName )
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then return false end
    return bManager.Active
end

function BaseReclaimEnabled( aiBrain, baseName )
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then return false end
    return bManager.FunctionalityStates.EngineerReclaiming
end

function BasePatrollingEnabled( aiBrain, baseName )
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then return false end
    return bManager.FunctionalityStates.Patrolling
end

function BaseBuildingEngineers( aiBrain, baseName )
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then return false end
    return bManager.FunctionalityStates.BuildEngineers
end

function BaseEngineersEnabled( aiBrain, baseName )
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then return false end
    return bManager.FunctionalityStates.Engineers
end

function LandScoutingEnabled( aiBrain, baseName )
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then return false end
    return bManager.FunctionalityStates.LandScouting
end

function AirScoutingEnabled( aiBrain, baseName )
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then return false end
    return bManager.FunctionalityStates.AirScouting
end

function ExpansionBasesEnabled( aiBrain, baseName )
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then return false end
    return bManager.FunctionalityStates.ExpansionBases
end
