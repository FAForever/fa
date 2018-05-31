#****************************************************************************
#**
#**  File     :  /lua/AI/aibuildstructures.lua
#**  Author(s): John Comes
#**
#**  Summary  : Foundation script for all structure building in the AI.
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local BaseTmplFile = import('/lua/basetemplates.lua')
local BaseTemplates = import('/lua/basetemplates.lua').BaseTemplates
local BuildingTemplates = import('/lua/BuildingTemplates.lua').BuildingTemplates
local Utils = import('/lua/utilities.lua')
local AIUtils = import('/lua/ai/aiutilities.lua')
local StructureUpgradeTemplates = import('/lua/upgradeTemplates.lua').StructureUpgradeTemplates
local UnitUpgradeTemplates = import('/lua/upgradeTemplates.lua').UnitUpgradeTemplates
local RebuildStructuresTemplate = import('/lua/BuildingTemplates.lua').RebuildStructuresTemplate
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local AIAttackUtils = import('/lua/ai/aiattackutilities.lua')
local aiEconomy
local allowedEnergyStorageRatio = 0.7
local allowedMassStorageRatio = 0.6

local TriggerFile = import('/lua/scenariotriggers.lua')

function AISetEconomyNumbers(aiBrain)
    #LOG('*AI DEBUG: SETTING ECONOMY NUMBERS FROM AIBRAIN ', repr(aiBrain))
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    aiEconomy = econ
end

function AIModEconomyNumbers(aiBrain, unitBP)
    #LOG('*AI DEBUG: MODDING ECON NUMBERS, BRAIN = ', repr(aiBrain), ' UNITBP = ', repr(unitBP))
    #LOG('*AI DEBUG: MODDING ECON NUMBERS, ENERGYTREND BEFORE = ', repr(aiEconomy.EnergyTrend))
    #LOG('*AI DEBUG: MODDING ECON NUMBERS, ENERGY USE OF UNIT = ', repr(aiBrain:GetUnitBlueprint(unitBP).Economy.ActiveConsumptionPerSecondEnergy * 0.1))
    aiEconomy.MassTrend = aiEconomy.MassTrend - (aiBrain:GetUnitBlueprint(unitBP).Economy.ActiveConsumptionPerSecondMass or 0) * 0.1
    aiEconomy.MassIncome = aiEconomy.MassIncome - (aiBrain:GetUnitBlueprint(unitBP).Economy.ActiveConsumptionPerSecondMass or 0) * 0.1
    aiEconomy.EnergyTrend = aiEconomy.EnergyTrend - (aiBrain:GetUnitBlueprint(unitBP).Economy.ActiveConsumptionPerSecondEnergy or 0) * 0.1
    aiEconomy.EnergyIncome = aiEconomy.EnergyIncome - (aiBrain:GetUnitBlueprint(unitBP).Economy.ActiveConsumptionPerSecondEnergy or 0) * 0.1
    #LOG('*AI DEBUG: MODDING ECON NUMBERS, ENERGYTREND AFTER = ', repr(aiEconomy.EnergyTrend * 0.1))
end

function AIGetBuilder(aiBrain, techLevel)
    local builderTechLevel = categories.TECH1 * categories.ENGINEER
    if techLevel == 2 then
        builderTechLevel = categories.TECH2 * categories.ENGINEER
    elseif techLevel == 3 then
        builderTechLevel = categories.TECH3 * categories.ENGINEER
    elseif techLevel == 0 then
        builderTechLevel = categories.COMMAND
    end
    #LOG('*AI DEBUG: AIGETBUILDER FINDING TECH LEVEL ', repr(techLevel))
    local builder = aiBrain:FindUnit(builderTechLevel, true)
    #LOG('*AI DEBUG: AIGETBUILDER RETURNING ', repr(builder))
    return builder
end

function AIGetAnyBuilder(aiBrain, techLevel, inclCDR)
    local builder = AIGetBuilder(aiBrain, techLevel)
    if not builder then
       builder = AIGetBuilder(aiBrain, 3)
    end
    if not builder then
       builder = AIGetBuilder(aiBrain, 2)
    end
    if not builder then
       builder = AIGetBuilder(aiBrain, 1)
    end
    if not builder and inclCDR then
        builder = AIGetBuilder(aiBrain, 0)
    end
    return builder
end


function AddToBuildQueue(aiBrain, builder, whatToBuild, buildLocation, relative)
    if not builder.EngineerBuildQueue then
        builder.EngineerBuildQueue = {}
    end
    # put in build queue.. but will be removed afterwards... just so that it can iteratively find new spots to build
    if aiBrain.Sorian then
        AIUtils.EngineerTryReclaimCaptureAreaSorian(aiBrain, builder, BuildToNormalLocation(buildLocation))
    else
        AIUtils.EngineerTryReclaimCaptureArea(aiBrain, builder, BuildToNormalLocation(buildLocation)) 
    end
    
    aiBrain:BuildStructure(builder, whatToBuild, buildLocation, false)

    local newEntry = {whatToBuild, buildLocation, relative}

    table.insert(builder.EngineerBuildQueue, newEntry)
end

# Build locations (from FindPlaceToBuild) come in as {x,z,dist},
# so we need to convert those to an actual 2D location format
function BuildToNormalLocation(location)
    return {location[1], 0, location[2]}
end
function NormalToBuildLocation(location)
    return {location[1], location[3], 0}
end

function IsResource(buildingType)
    return buildingType == 'Resource' or buildingType == 'T1HydroCarbon' or
            buildingType == 'T1Resource' or buildingType == 'T2Resource' or buildingType == 'T3Resource'
end


function AIExecuteBuildStructure(aiBrain, builder, buildingType, closeToBuilder, relative, buildingTemplate, baseTemplate, reference, NearMarkerType)
    local factionIndex = aiBrain:GetFactionIndex()
    local whatToBuild = aiBrain:DecideWhatToBuild(builder, buildingType, buildingTemplate)
    # if we can't decide, we build NOTHING
    if not whatToBuild then
        return
    end

    #find a place to build it (ignore enemy locations if it's a resource)
    # build near the base the engineer is part of, rather than the engineer location
    local relativeTo
    if closeToBuilder then
        relativeTo = closeToBuilder:GetPosition()
    elseif builder.BuilderManagerData and builder.BuilderManagerData.EngineerManager then
        relativeTo = builder.BuilderManagerData.EngineerManager:GetLocationCoords()
    else
        local startPosX, startPosZ = aiBrain:GetArmyStartPos()
        relativeTo = {startPosX, 0, startPosZ}
    end
    local location = false
    if IsResource(buildingType) then
        location = aiBrain:FindPlaceToBuild(buildingType, whatToBuild, baseTemplate, relative, closeToBuilder, 'Enemy', relativeTo[1], relativeTo[3], 5)
    else
        location = aiBrain:FindPlaceToBuild(buildingType, whatToBuild, baseTemplate, relative, closeToBuilder, nil, relativeTo[1], relativeTo[3])
    end
    # if it's a reference, look around with offsets
    if not location and reference then
        for num,offsetCheck in RandomIter({1,2,3,4,5,6,7,8}) do
            location = aiBrain:FindPlaceToBuild(buildingType, whatToBuild, BaseTmplFile['MovedTemplates'..offsetCheck][factionIndex], relative, closeToBuilder, nil, relativeTo[1], relativeTo[3])
            if location then
                break
            end
        end
    end

    # if we have a location, build!
    if location then
        local relativeLoc = BuildToNormalLocation(location)
        if relative then
            relativeLoc = {relativeLoc[1] + relativeTo[1], relativeLoc[2] + relativeTo[2], relativeLoc[3] + relativeTo[3]}
        end
        # put in build queue.. but will be removed afterwards... just so that it can iteratively find new spots to build
        AddToBuildQueue(aiBrain, builder, whatToBuild, NormalToBuildLocation(relativeLoc), false)
        return
    end

    #otherwise, we're SOL, so move on to the next thing
end


function AIBuildBaseTemplate(aiBrain, builder, buildingType , closeToBuilder, relative, buildingTemplate, baseTemplate, reference, NearMarkerType)
    local whatToBuild = aiBrain:DecideWhatToBuild(builder, buildingType, buildingTemplate)
    if whatToBuild then
        for _,bType in baseTemplate do
            for n,bString in bType[1] do
                AIExecuteBuildStructure(aiBrain, builder, buildingType , closeToBuilder, relative, buildingTemplate, baseTemplate, reference)

                return DoHackyLogic(buildingType, builder)
            end
        end
    end
end

#Per-unit AI logic for buildings defined in constructiondata
function DoHackyLogic(buildingType, builder)
    if buildingType == 'T2StrategicMissile' then
        local unitInstance = false

        builder:ForkThread(function()
            while true do
                if not unitInstance then
                    unitInstance = builder.UnitBeingBuilt
                end
                aiBrain = builder:GetAIBrain()
                if unitInstance then
                    TriggerFile.CreateUnitStopBeingBuiltTrigger(function(unitBeingBuilt)
                        local newPlatoon = aiBrain:MakePlatoon('', '')
                        aiBrain:AssignUnitsToPlatoon(newPlatoon, {unitBeingBuilt}, 'Attack', 'None')
                        newPlatoon:StopAI()
                        newPlatoon:ForkAIThread(newPlatoon.TacticalAI)
                    end, unitInstance)
                    break
                end
                WaitSeconds(1)
            end
        end)
    end
end


function AIBuildBaseTemplateOrdered(aiBrain, builder, buildingType , closeToBuilder, relative, buildingTemplate, baseTemplate, reference, NearMarkerType)
    local factionIndex = aiBrain:GetFactionIndex()
    local whatToBuild = aiBrain:DecideWhatToBuild(builder, buildingType, buildingTemplate)
    if whatToBuild then
        if IsResource(buildingType) then
            return AIExecuteBuildStructure(aiBrain, builder, buildingType , closeToBuilder, relative, buildingTemplate, baseTemplate, reference)
        else
            for l,bType in baseTemplate do
                for m,bString in bType[1] do
                    if bString == buildingType then
                        for n,position in bType do
                            if n > 1 and aiBrain:CanBuildStructureAt(whatToBuild, BuildToNormalLocation(position)) then
                                 AddToBuildQueue(aiBrain, builder, whatToBuild, position, false)
                                 return DoHackyLogic(buildingType, builder)
                            end # if n > 1 and can build structure at
                        end # for loop
                        break
                    end # if bString == builderType
                end # for loop
            end # for loop
        end # end else
    end # if what to build
    return # unsuccessful build
end

function AIBuildBaseTemplateFromLocation(baseTemplate, location)
    local baseT = {}
    if location and baseTemplate then
        for templateNum, template in baseTemplate do
            baseT[templateNum] = {}
            for rowNum,rowData in template do # rowNum, rowData in template do
                if type(rowData[1]) == 'number' then
                    baseT[templateNum][rowNum] = {}
                    baseT[templateNum][rowNum][1] = math.floor(rowData[1] + location[1]) + 0.5
                    baseT[templateNum][rowNum][2] = math.floor(rowData[2] + location[3]) + 0.5
                    baseT[templateNum][rowNum][3] = 0
                else
                    baseT[templateNum][rowNum] = template[rowNum]
                end
            end
        end
    end
    return baseT
end

function AIBuildAdjacency(aiBrain, builder, buildingType , closeToBuilder, relative, buildingTemplate, baseTemplate, reference, NearMarkerType)
    local factionIndex = aiBrain:GetFactionIndex()
    local whatToBuild = aiBrain:DecideWhatToBuild(builder, buildingType, buildingTemplate)
    if whatToBuild then
        local upperString = ParseEntityCategory(string.upper(whatToBuild))
        local unitSize = aiBrain:GetUnitBlueprint(whatToBuild).Physics
        local template = {}
        table.insert(template, {})
        table.insert(template[1], { buildingType })
        for k,v in reference do
            if not v.Dead then
                local targetSize = v:GetBlueprint().Physics
                local targetPos = v:GetPosition()
                targetPos[1] = targetPos[1] - (targetSize.SkirtSizeX/2)
                targetPos[3] = targetPos[3] - (targetSize.SkirtSizeZ/2)
                # Top/bottom of unit
                for i=0,((targetSize.SkirtSizeX/2)-1) do
                    local testPos = { targetPos[1] + 1 + (i * 2), targetPos[3]-(unitSize.SkirtSizeZ/2), 0 }
                    local testPos2 = { targetPos[1] + 1 + (i * 2), targetPos[3]+targetSize.SkirtSizeZ+(unitSize.SkirtSizeZ/2), 0 }
                    table.insert(template[1], testPos)
                    table.insert(template[1], testPos2)
                end
                # Sides of unit
                for i=0,((targetSize.SkirtSizeZ/2)-1) do
                    local testPos = { targetPos[1]+targetSize.SkirtSizeX + (unitSize.SkirtSizeX/2), targetPos[3] + 1 + (i * 2), 0 }
                    local testPos2 = { targetPos[1]-(unitSize.SkirtSizeX/2), targetPos[3] + 1 + (i*2), 0 }
                    table.insert(template[1], testPos)
                    table.insert(template[1], testPos2)
                end
            end
        end
        # build near the base the engineer is part of, rather than the engineer location
        local baseLocation = {nil, nil, nil}
        if builder.BuildManagerData and builder.BuildManagerData.EngineerManager then
            baseLocation = builder.BuildManagerdata.EngineerManager.Location
        end
        local location = aiBrain:FindPlaceToBuild(buildingType, whatToBuild, template, false, builder, baseLocation[1], baseLocation[3])
        if location then
             AddToBuildQueue(aiBrain, builder, whatToBuild, location, false)
            return
        end
        ## Build in a regular spot if adjacency not found
        return AIExecuteBuildStructure(aiBrain, builder, buildingType, builder, true,  buildingTemplate, baseTemplate)
    end
    return false, false
end

function AINewExpansionBase(aiBrain, baseName, position, builder, constructionData)
    local radius = constructionData.ExpansionRadius or 100
    # PBM Style expansion bases here
    if aiBrain:PBMHasPlatoonList() then
    # Figure out what type of builders to import
        local expansionTypes = constructionData.ExpansionTypes
    if not expansionTypes then
        expansionTypes = { 'Air', 'Land', 'Sea', 'Gate' }
    end

    # Check if it already exists
        for k,v in aiBrain.PBM.Locations do
            if v.LocationType == baseName then
                return
            end
        end
        aiBrain:PBMAddBuildLocation(position, radius, baseName, true)

        for num, typeString in expansionTypes do
            for bNum, builder in aiBrain.PBM.Platoons[typeString] do
                if builder.LocationType == 'MAIN' and CheckExpansionType(typeString, ScenarioInfo.BuilderTable[typeString][builder.BuilderName].ExpansionExclude)  then
                    local pltnTable = {}
                    for dField, data in builder do
                        if dField == 'LocationType' then
                            pltnTable[dField] = baseName
                        elseif dField == 'PlatoonHandle' then
                            pltnTable[dField] = false
                        elseif dField == 'PlatoonTimeOutThread' then
                            pltnTable[dField] = nil
                        else
                            pltnTable[dField] = data
                        end
                    end
                    table.insert(aiBrain.PBM.Platoons[typeString], pltnTable)
                    aiBrain.PBM.NeedSort[typeString] = true
                end
            end
        end

    else
        if not aiBrain.BuilderManagers or aiBrain.BuilderManagers[baseName] or not builder.BuilderManagerData then
            #LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': New Engineer for expansion base - ' .. baseName)
            builder.BuilderManagerData.EngineerManager:RemoveUnit(builder)
            aiBrain.BuilderManagers[baseName].EngineerManager:AddUnit(builder, true)
            return
        end

        aiBrain:AddBuilderManagers(position, radius, baseName, true)

        # Move the engineer to the new base managers
        builder.BuilderManagerData.EngineerManager:RemoveUnit(builder)
        aiBrain.BuilderManagers[baseName].EngineerManager:AddUnit(builder, true)

        # Iterate through bases finding the value of each expansion
        local baseValues = {}
        local highPri = false
        for templateName, baseData in BaseBuilderTemplates do
            local baseValue = baseData.ExpansionFunction(aiBrain, position, constructionData.NearMarkerType)
            table.insert(baseValues, { Base = templateName, Value = baseValue })
            if not highPri or baseValue > highPri then
                highPri = baseValue
            end
        end

        # Random to get any picks of same value
        local validNames = {}
        for k,v in baseValues do
            if v.Value == highPri then
                table.insert(validNames, v.Base)
            end
        end
        local pick = validNames[ Random(1, table.getn(validNames)) ]

        # Error if no pick
        if not pick then
            LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': Layer Preference - ' .. per .. ' - yielded no base types at - ' .. locationType)
        end

        # Setup base
        #LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': Expanding using - ' .. pick .. ' at location ' .. baseName)
        import('/lua/ai/AIAddBuilderTable.lua').AddGlobalBaseTemplate(aiBrain, baseName, pick)

        # If air base switch to building an air factory rather than land
        if (string.find(pick, 'Air') or string.find(pick, 'Water')) then
            #if constructionData.BuildStructures[1] == 'T1LandFactory' then
            #    constructionData.BuildStructures[1] = 'T1AirFactory'
            #end
            local numToChange = BaseBuilderTemplates[pick].BaseSettings.FactoryCount.Land
            for k,v in constructionData.BuildStructures do
                if constructionData.BuildStructures[k] == 'T1LandFactory' and numToChange <= 0 then
                    constructionData.BuildStructures[k] = 'T1AirFactory'
                elseif constructionData.BuildStructures[k] == 'T1LandFactory' and numToChange > 0 then
                    numToChange = numToChange - 1
                end
            end
        end
    end
end

function CheckExpansionType(typeString, typeTable)
    if not typeTable then
        return true
    elseif type(typeTable) == 'table' then
        for k,v in typeTable do
            if v == typeString then
                return false
            end
        end
    end
    return true
end

function FindNearestIntegers(pos)
    local x = math.floor(pos[1])
    local z = math.floor(pos[3])
    return { x, z }
end


function WallBuilder(aiBrain, builder, buildingType , closeToBuilder, relative, buildingTemplate, baseTemplate, reference, NearMarkerType)
    if not reference then
        return
    end
    local points = BuildWallsAtLocation(aiBrain, reference)
    if not points then
        return
    end
    local i = 2
    while i <= table.getn(points) do
        local point1 = FindNearestIntegers(points[i-1])
        local point2 = FindNearestIntegers(points[i])
        #### Horizontal line
        local buildTable = {}
        if point1[2] == point2[2] then
            local xDir = -1
            if point1[1] < point2[1] then
                xDir = 1
            end
            for j = 1, math.abs(point1[1] - point2[1]) do
                table.insert(buildTable, { point1[1] + (j * xDir) + .5, point1[2] + .5, 0 })
            end
        #### Vertical line
        elseif point1[1] == point2[1] then
            local yDir = -1
            if point1[2] < point2[2] then
                yDir = 1
            end
            for j = 1, math.abs(point1[2] - point2[2]) do
                table.insert(buildTable, { point1[1] + .5, point1[2] + (j * yDir) + .5, 0 })
            end
        #### Angled line
        else
            local angle = (point1[1] - point2[1]) / (point1[2] - point2[2])
            if angle == 0 then
                angle = 1
            end

            local xDir = -1
            if point1[1] < point2[1] then
                xDir = 1
            end
            for j=1,math.abs(point1[1] - point2[1]) do
                table.insert(buildTable, { point1[1] + (j * xDir) - .5, (point1[2] + math.floor((angle * xDir) * (j-1)) + .5), 0 })
            end
        end
        local faction = aiBrain:GetFactionIndex()
        local whatToBuild = aiBrain:DecideWhatToBuild(builder, buildingType, buildingTemplate)
        for k,v in buildTable do
            if aiBrain:CanBuildStructureAt(whatToBuild, BuildToNormalLocation(v)) then
                #aiBrain:BuildStructure(builder, whatToBuild, v, false)
                AddToBuildQueue(aiBrain, builder, whatToBuild, v, false)
            end
        end
        i = i + 1
    end
    return
end

function GetBuildingDirection(main, loc)
    local distance = Utils.XZDistanceTwoVectors(main, loc)
    local cutoff = distance / 2
    local direction = {}
    if math.abs(loc[1] - main[1]) > cutoff then
        if loc[1] > main[1] then
            direction[1] = 1
        else
            direction[1] = -1
        end
    else
        direction[1] = 0
    end
    if math.abs(loc[3] - main[3]) > cutoff then
        if loc[3] > main[3] then
            direction[2] = 1
        else
            direction[2] = -1
        end
    else
        direction[2] = 0
    end
    local points = {}
    if direction[1] ~= 0 and direction[2] ~= 0 then
        table.insert(points, { loc[1], loc[2], loc[3] + (direction[2] * 16) })
        table.insert(points, { loc[1] + (direction[1] * 16), loc[2], loc[3] + (direction[2] * 16) })
        table.insert(points, { loc[1] + (direction[1] * 16), loc[2], loc[3] })
    elseif direction[1] ~= 0 then
        table.insert(points, { loc[1], loc[2], loc[3] + 16 })
        table.insert(points, { loc[1] + (direction[1] * 16), loc[2], loc[3] })
        table.insert(points, { loc[1], loc[2], loc[3] - 16 })
    else
        table.insert(points, { loc[1] + 16, loc[2], loc[3] })
        table.insert(points, { loc[1], loc[2], loc[3] + (direction[1] * 16) })
        table.insert(points, { loc[1] - 16, loc[2], loc[3] })
    end
    return points
end

function BuildWallsAtLocation(aiBrain, location)
    local mainPos = aiBrain:PBMGetLocationCoords('MAIN')
    return GetBuildingDirection(mainPos, location)
end





### OPERATION STUFF BELOW ###

### Takes a group of <name> from <army> in the save file.
### Populates a base template from this save file.
### Stores the template naming it <name> in the brain.
function CreateBuildingTemplate(brain, army, name)
    local list = {}
    local template = {}
    local tblUnit = ScenarioUtils.AssembleArmyGroup(army, name)
    local factionIndex = brain:GetFactionIndex()
    if not tblUnit then
        LOG('*ERROR AIBUILDSTRUCTURES - Group: ', repr(name), ' not found for Army: ', repr(army))
    else
        for i,unit in tblUnit do
            for k, unitId in RebuildStructuresTemplate[factionIndex] do
                if unit.type == unitId[1] then
                    unit.buildtype = unitId[2]
                    break
                end
            end
            if not unit.buildtype then
                unit.buildtype = unit.type
            end
        end
        for i, unit in tblUnit do
            for j,buildList in BuildingTemplates[factionIndex] do
                local unitPos = { unit.Position[1], unit.Position[3], 0 }
                if unit.buildtype == buildList[2] and buildList[1] ~= 'T3Sonar' then
                    local inserted = false
                    for k,section in template do
                        if section[1][1] == buildList[1] then
                            table.insert(section, unitPos)
                            list[unit.buildtype].AmountWanted = list[unit.buildtype].AmountWanted + 1
                            inserted = true
                            break
                        end
                    end
                    if not inserted then
                        table.insert(template, { {buildList[1]}, unitPos })
                        list[unit.buildtype] =  { StructureType = buildList[1], StructureCategory = unit.buildtype, AmountNeeded = 0, AmountWanted = 1, CloseToBuilder = nil }
                    end
                    break
                end
            end
        end
        brain.BaseTemplates[name] = { Template=template, List=list }
    end
end

### Takes a group of <name> from <army> in the save file.
### Populates a base template from this save file.
### Appends the template named <templateName> in the brain with new data
function AppendBuildingTemplate(brain, army, name, templateName)
    local tblUnit = ScenarioUtils.AssembleArmyGroup(army, name)
    local factionIndex = brain:GetFactionIndex()
    if not brain.BaseTemplates[templateName] then
        error('*AI BUILD STRUCTURES: Invalid template name to append- ' .. templateName, 2)
    end
    local template = brain.BaseTemplates[templateName].Template
    local list = brain.BaseTemplates[templateName].List
    if not tblUnit then
        LOG('*ERROR AIBUILDSTRUCTURES - Group: ', repr(name), ' not found for Army: ', repr(army))
    else
        # Convert building to the proper type to be built if needed (ex: T2 and T3 factories to T1)
        for i,unit in tblUnit do
            for k, unitId in RebuildStructuresTemplate[factionIndex] do
                if unit.type == unitId[1] then
                    unit.buildtype = unitId[2]
                    break
                end
            end
            if not unit.buildtype then
                unit.buildtype = unit.type
            end
        end
        for i, unit in tblUnit do
            for j,buildList in BuildingTemplates[factionIndex] do # buildList[1] is type ("T1LandFactory"); buildList[2] is unitId (ueb0101)
                local unitPos = { unit.Position[1], unit.Position[3], 0 }
                if unit.buildtype == buildList[2] and buildList[1] ~= 'T3Sonar' then # if unit to be built is the same id as the buildList unit it needs to be added
                    local inserted = false
                    for k,section in template do # check each section of the template for the right type
                        if section[1][1] == buildList[1] then
                            table.insert(section, unitPos) # add position of new unit if found
                            list[unit.buildtype].AmountWanted = list[unit.buildtype].AmountWanted + 1 # increment num wanted if found
                            inserted = true
                            break
                        end
                    end
                    if not inserted then # if section doesn't exist create new one
                        table.insert(template, { {buildList[1]}, unitPos }) # add new build type to list with new unit
                        list[unit.buildtype] =  { StructureType = buildList[1], StructureCategory = unit.buildtype, AmountNeeded = 0, AmountWanted = 1, CloseToBuilder = nil } # add new section of build list with new unit type information
                    end
                    break
                end
            end
        end
    end
end

function StructureCheck(unitName)
    local bp = ArmyBrains[1]:GetUnitBlueprint(unitName)
    if bp.CategoriesHash.BUILTBYTIER1ENGINEER then
        return true
    elseif bp.CategoriesHash.BUILTBYTIER2ENGINEER then
        return true
    elseif bp.CategoriesHash.BUILTBYTIER3ENGINEER then
        return true
    end
    return false
end

function AIMaintainBuildList(aiBrain, builder, buildingTemplate, brainBaseTemplate)
    if not buildingTemplate then
        buildingTemplate = BuildingTemplates[aiBrain:GetFactionIndex()]
    end
    for k,v in brainBaseTemplate.List do
        if builder:CanBuild(v.StructureCategory) then
            if v.StructureType == 'Resource' or v.StructureType == 'T1HydroCarbon' or v.StructureType == 'T1Resource'
                or v.StructureType == 'T2Resource' or v.StructureType == 'T3Resource' then
                for l,type in brainBaseTemplate.Template do
                    if type[1][1] == v.StructureType then
                        for m,location in type do
                            if m > 1 then
                                if aiBrain:CanBuildStructureAt(v.StructureCategory, BuildToNormalLocation(location)) then
                                    IssueStop({builder})
                                    IssueClearCommands({builder})
                                    aiBrain:BuildStructure(builder, v.StructureCategory, location, false)
                                    return true
                                end
                            end
                        end
                    end
                end
            elseif aiBrain:FindPlaceToBuild(v.StructureType, v.StructureCategory,  brainBaseTemplate.Template, false, v.CloseToBuilder) then
                IssueStop({builder})
                IssueClearCommands({builder})
                if AIExecuteBuildStructure(aiBrain, builder, v.StructureType , v.CloseToBuilder, false, buildingTemplate, brainBaseTemplate.Template) then
                    return true
                end
            end
        end
    end
    return false
end
