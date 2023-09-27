-- File     :  /lua/AI/aibuildstructures.lua
-- Author(s): John Comes
-- Summary  : Foundation script for all structure building in the AI.
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------

local BaseTmplFile = lazyimport("/lua/basetemplates.lua")
local StructureTemplates = import("/lua/buildingtemplates.lua")
local Utils = import("/lua/utilities.lua")
local AIUtils = import("/lua/ai/aiutilities.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local aiEconomy
local allowedEnergyStorageRatio = 0.7
local allowedMassStorageRatio = 0.6

local TriggerFile = import("/lua/scenariotriggers.lua")

---@param aiBrain AIBrain
function AISetEconomyNumbers(aiBrain)
    --LOG('*AI DEBUG: SETTING ECONOMY NUMBERS FROM AIBRAIN ', repr(aiBrain))
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    aiEconomy = econ
end

---@param aiBrain AIBrain
---@param unitBP UnitBlueprint
function AIModEconomyNumbers(aiBrain, unitBP)
    --LOG('*AI DEBUG: MODDING ECON NUMBERS, BRAIN = ', repr(aiBrain), ' UNITBP = ', repr(unitBP))
    --LOG('*AI DEBUG: MODDING ECON NUMBERS, ENERGYTREND BEFORE = ', repr(aiEconomy.EnergyTrend))
    --LOG('*AI DEBUG: MODDING ECON NUMBERS, ENERGY USE OF UNIT = ', repr(aiBrain:GetUnitBlueprint(unitBP).Economy.ActiveConsumptionPerSecondEnergy * 0.1))
    aiEconomy.MassTrend = aiEconomy.MassTrend - (aiBrain:GetUnitBlueprint(unitBP).Economy.ActiveConsumptionPerSecondMass or 0) * 0.1
    aiEconomy.MassIncome = aiEconomy.MassIncome - (aiBrain:GetUnitBlueprint(unitBP).Economy.ActiveConsumptionPerSecondMass or 0) * 0.1
    aiEconomy.EnergyTrend = aiEconomy.EnergyTrend - (aiBrain:GetUnitBlueprint(unitBP).Economy.ActiveConsumptionPerSecondEnergy or 0) * 0.1
    aiEconomy.EnergyIncome = aiEconomy.EnergyIncome - (aiBrain:GetUnitBlueprint(unitBP).Economy.ActiveConsumptionPerSecondEnergy or 0) * 0.1
    --LOG('*AI DEBUG: MODDING ECON NUMBERS, ENERGYTREND AFTER = ', repr(aiEconomy.EnergyTrend * 0.1))
end

---@param aiBrain AIBrain
---@param techLevel number
---@return unknown
function AIGetBuilder(aiBrain, techLevel)
    local builderTechLevel = categories.TECH1 * categories.ENGINEER
    if techLevel == 2 then
        builderTechLevel = categories.TECH2 * categories.ENGINEER
    elseif techLevel == 3 then
        builderTechLevel = categories.TECH3 * categories.ENGINEER
    elseif techLevel == 0 then
        builderTechLevel = categories.COMMAND
    end
    --LOG('*AI DEBUG: AIGETBUILDER FINDING TECH LEVEL ', repr(techLevel))
    local builder = aiBrain:FindUnit(builderTechLevel, true)
    --LOG('*AI DEBUG: AIGETBUILDER RETURNING ', repr(builder))
    return builder
end

---@param aiBrain AIBrain
---@param techLevel number
---@param inclCDR CommandUnit
---@return unknown
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

---@param aiBrain AIBrain
---@param builder Unit
---@param whatToBuild any
---@param buildLocation Vector
---@param relative any
function AddToBuildQueue(aiBrain, builder, whatToBuild, buildLocation, relative)
    if not builder.EngineerBuildQueue then
        builder.EngineerBuildQueue = {}
    end
    -- put in build queue.. but will be removed afterwards... just so that it can iteratively find new spots to build
    AIUtils.EngineerTryReclaimCaptureArea(aiBrain, builder, BuildToNormalLocation(buildLocation))
    aiBrain:BuildStructure(builder, whatToBuild, buildLocation, false)
    local newEntry = {whatToBuild, buildLocation, relative}
    table.insert(builder.EngineerBuildQueue, newEntry)
end

-- Build locations (from FindPlaceToBuild) come in as {x,z,dist},
-- so we need to convert those to an actual 2D location format
---@param location Vector
---@return table
function BuildToNormalLocation(location)
    return {location[1], 0, location[2]}
end

---@param location Vector
---@return table
function NormalToBuildLocation(location)
    return {location[1], location[3], 0}
end

---@param buildingType string
---@return boolean
function IsResource(buildingType)
    return buildingType == 'Resource' or buildingType == 'T1HydroCarbon' or
            buildingType == 'T1Resource' or buildingType == 'T2Resource' or buildingType == 'T3Resource'
end

local AntiSpamList = {}
---@param aiBrain AIBrain
---@param builder Unit
---@param buildingType string
---@param closeToBuilder boolean
---@param relative any
---@param buildingTemplate any
---@param baseTemplate any
---@param reference any
---@param NearMarkerType any
---@return boolean
function AIExecuteBuildStructure(aiBrain, builder, buildingType, closeToBuilder, relative, buildingTemplate, baseTemplate, reference, NearMarkerType)
    local factionIndex = aiBrain:GetFactionIndex()
    local whatToBuild = aiBrain:DecideWhatToBuild(builder, buildingType, buildingTemplate)
    -- If the c-engine can't decide what to build, then search the build template manually.
    if not whatToBuild then
        if AntiSpamList[buildingType] then
            return false
        end
        local FactionIndexToName = {[1] = 'UEF', [2] = 'AEON', [3] = 'CYBRAN', [4] = 'SERAPHIM', [5] = 'NOMADS' }
        local AIFactionName = FactionIndexToName[factionIndex]
        SPEW('*AIExecuteBuildStructure: We cant decide whatToBuild! AI-faction: '..AIFactionName..', Building Type: '..repr(buildingType)..', engineer-faction: '..repr(builder.Blueprint.FactionCategory))
        -- Get the UnitId for the actual buildingType
        local BuildUnitWithID
        for Key, Data in buildingTemplate do
            if Data[1] and Data[2] and Data[1] == buildingType then
                SPEW('*AIExecuteBuildStructure: Found template: '..repr(Data[1])..' - Using UnitID: '..repr(Data[2]))
                BuildUnitWithID = Data[2]
                break
            end
        end
        -- If we can't find a template, then return
        if not BuildUnitWithID then
            AntiSpamList[buildingType] = true
            WARN('*AIExecuteBuildStructure: No '..repr(builder.Blueprint.FactionCategory)..' unit found for template: '..repr(buildingType)..'! ')
            return false
        end
        -- get the needed tech level to build buildingType
        local BBC = __blueprints[BuildUnitWithID].CategoriesHash
        local NeedTech
        if BBC.BUILTBYCOMMANDER or BBC.BUILTBYTIER1COMMANDER or BBC.BUILTBYTIER1ENGINEER then
            NeedTech = 1
        elseif BBC.BUILTBYTIER2COMMANDER or BBC.BUILTBYTIER2ENGINEER then
            NeedTech = 2
        elseif BBC.BUILTBYTIER3COMMANDER or BBC.BUILTBYTIER3ENGINEER then
            NeedTech = 3
        end
        -- If we can't find a techlevel for the building we want to build, then return
        if not NeedTech then
            WARN('*AIExecuteBuildStructure: Can\'t find techlevel for BuildUnitWithID: '..repr(BuildUnitWithID))
            return false
        else
            SPEW('*AIExecuteBuildStructure: Need engineer with Techlevel ('..NeedTech..') for BuildUnitWithID: '..repr(BuildUnitWithID))
        end
        -- get the actual tech level from the builder
        local BC = builder:GetBlueprint().CategoriesHash
        if BC.TECH1 or BC.COMMAND then
            HasTech = 1
        elseif BC.TECH2 then
            HasTech = 2
        elseif BC.TECH3 then
            HasTech = 3
        end
        -- If we can't find a techlevel for the building we  want to build, return
        if not HasTech then
            WARN('*AIExecuteBuildStructure: Can\'t find techlevel for engineer: '..repr(builder:GetBlueprint().BlueprintId))
            return false
        else
            SPEW('*AIExecuteBuildStructure: Engineer ('..repr(builder:GetBlueprint().BlueprintId)..') has Techlevel ('..HasTech..')')
        end

        if HasTech < NeedTech then
            WARN('*AIExecuteBuildStructure: TECH'..HasTech..' Unit "'..BuildUnitWithID..'" is assigned to build TECH'..NeedTech..' buildplatoon! ('..repr(buildingType)..')')
            return false
        else
            SPEW('*AIExecuteBuildStructure: Engineer with Techlevel ('..HasTech..') can build TECH'..NeedTech..' BuildUnitWithID: '..repr(BuildUnitWithID))
        end

        HasFaction = builder.Blueprint.FactionCategory
        NeedFaction = string.upper(__blueprints[string.lower(BuildUnitWithID)].General.FactionName)
        if HasFaction ~= NeedFaction then
            WARN('*AIExecuteBuildStructure: AI-faction: '..AIFactionName..', ('..HasFaction..') engineers can\'t build ('..NeedFaction..') structures!')
            return false
        else
            SPEW('*AIExecuteBuildStructure: AI-faction: '..AIFactionName..', Engineer with faction ('..HasFaction..') can build faction ('..NeedFaction..') - BuildUnitWithID: '..repr(BuildUnitWithID))
        end

        local IsRestricted = import("/lua/game.lua").IsRestricted
        if IsRestricted(BuildUnitWithID, GetFocusArmy()) then
            WARN('*AIExecuteBuildStructure: Unit is Restricted!!! Building Type: '..repr(buildingType)..', faction: '..repr(builder.Blueprint.FactionCategory)..' - Unit:'..BuildUnitWithID)
            AntiSpamList[buildingType] = true
            return false
        end

        WARN('*AIExecuteBuildStructure: DecideWhatToBuild call failed for Building Type: '..repr(buildingType)..', faction: '..repr(builder.Blueprint.FactionCategory)..' - Unit:'..BuildUnitWithID)
        return false
    end
    -- find a place to build it (ignore enemy locations if it's a resource)
    -- build near the base the engineer is part of, rather than the engineer location
    local relativeTo
    if closeToBuilder then
        relativeTo = builder:GetPosition()
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
    -- if it's a reference, look around with offsets
    if not location and reference then
        for num,offsetCheck in RandomIter({1,2,3,4,5,6,7,8}) do
            location = aiBrain:FindPlaceToBuild(buildingType, whatToBuild, BaseTmplFile['MovedTemplates'..offsetCheck][factionIndex], relative, closeToBuilder, nil, relativeTo[1], relativeTo[3])
            if location then
                break
            end
        end
    end
    -- if we have no place to build, then maybe we have a modded/new buildingType. Lets try 'T1LandFactory' as dummy and search for a place to build near base
    if not location and not IsResource(buildingType) and builder.BuilderManagerData and builder.BuilderManagerData.EngineerManager then
        --LOG('*AIExecuteBuildStructure: Find no place to Build! - buildingType '..repr(buildingType)..' - ('..builder.Blueprint.FactionCategory..') Trying again with T1LandFactory and RandomIter. Searching near base...')
        relativeTo = builder.BuilderManagerData.EngineerManager:GetLocationCoords()
        for num,offsetCheck in RandomIter({1,2,3,4,5,6,7,8}) do
            location = aiBrain:FindPlaceToBuild('T1LandFactory', whatToBuild, BaseTmplFile['MovedTemplates'..offsetCheck][factionIndex], relative, closeToBuilder, nil, relativeTo[1], relativeTo[3])
            if location then
                --LOG('*AIExecuteBuildStructure: Yes! Found a place near base to Build! - buildingType '..repr(buildingType))
                break
            end
        end
    end
    -- if we still have no place to build, then maybe we have really no place near the base to build. Lets search near engineer position
    if not location and not IsResource(buildingType) then
        --LOG('*AIExecuteBuildStructure: Find still no place to Build! - buildingType '..repr(buildingType)..' - ('..builder.Blueprint.FactionCategory..') Trying again with T1LandFactory and RandomIter. Searching near Engineer...')
        relativeTo = builder:GetPosition()
        for num,offsetCheck in RandomIter({1,2,3,4,5,6,7,8}) do
            location = aiBrain:FindPlaceToBuild('T1LandFactory', whatToBuild, BaseTmplFile['MovedTemplates'..offsetCheck][factionIndex], relative, closeToBuilder, nil, relativeTo[1], relativeTo[3])
            if location then
                --LOG('*AIExecuteBuildStructure: Yes! Found a place near engineer to Build! - buildingType '..repr(buildingType))
                break
            end
        end
    end
    -- if we have a location, build!
    if location then
        local relativeLoc = BuildToNormalLocation(location)
        if relative then
            relativeLoc = {relativeLoc[1] + relativeTo[1], relativeLoc[2] + relativeTo[2], relativeLoc[3] + relativeTo[3]}
        end
        -- put in build queue.. but will be removed afterwards... just so that it can iteratively find new spots to build
        AddToBuildQueue(aiBrain, builder, whatToBuild, NormalToBuildLocation(relativeLoc), false)
        return true
    end
    -- At this point we're out of options, so move on to the next thing
    return false
end

---@param aiBrain AIBrain
---@param builder Unit
---@param buildingType any
---@param closeToBuilder any
---@param relative any
---@param buildingTemplate any
---@param baseTemplate any
---@param reference any
---@param NearMarkerType any
---@return unknown
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

--- Per-unit AI logic for buildings defined in constructiondata
---@param buildingType string
---@param builder Unit
function DoHackyLogic(buildingType, builder)
    if buildingType == 'T2StrategicMissile' then
        local unitInstance = false

        builder:ForkThread(function()
            while true do
                if not unitInstance then
                    unitInstance = builder.UnitBeingBuilt
                end
                local aiBrain = builder:GetAIBrain()
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

---@param aiBrain AIBrain
---@param builder Unit
---@param buildingType string
---@param closeToBuilder any
---@param relative any
---@param buildingTemplate any
---@param baseTemplate any
---@param reference any
---@param NearMarkerType any
---@return boolean
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
                            end -- if n > 1 and can build structure at
                        end -- for loop
                        break
                    end -- if bString == builderType
                end -- for loop
            end -- for loop
        end -- end else
    end -- if what to build
    return -- unsuccessful build
end

---@param baseTemplate any
---@param location Vector
---@return table
function AIBuildBaseTemplateFromLocation(baseTemplate, location)
    local baseT = {}
    if location and baseTemplate then
        for templateNum, template in baseTemplate do
            baseT[templateNum] = {}
            for rowNum,rowData in template do -- rowNum, rowData in template do
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

---@param aiBrain AIBrain
---@param builder Unit
---@param buildingType any
---@param closeToBuilder any
---@param relative any
---@param buildingTemplate any
---@param baseTemplate any
---@param reference any
---@param NearMarkerType any
---@return boolean
function AIBuildAdjacency(aiBrain, builder, buildingType , closeToBuilder, relative, buildingTemplate, baseTemplate, reference, NearMarkerType)
    local whatToBuild = aiBrain:DecideWhatToBuild(builder, buildingType, buildingTemplate)
    if whatToBuild then
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
                -- Top/bottom of unit
                for i=0,((targetSize.SkirtSizeX/2)-1) do
                    local testPos = { targetPos[1] + 1 + (i * 2), targetPos[3]-(unitSize.SkirtSizeZ/2), 0 }
                    local testPos2 = { targetPos[1] + 1 + (i * 2), targetPos[3]+targetSize.SkirtSizeZ+(unitSize.SkirtSizeZ/2), 0 }
                    -- check if the buildplace is to close to the border or inside buildable area
                    if testPos[1] > 8 and testPos[1] < ScenarioInfo.size[1] - 8 and testPos[2] > 8 and testPos[2] < ScenarioInfo.size[2] - 8 then
                        table.insert(template[1], testPos)
                    end
                    if testPos2[1] > 8 and testPos2[1] < ScenarioInfo.size[1] - 8 and testPos2[2] > 8 and testPos2[2] < ScenarioInfo.size[2] - 8 then
                        table.insert(template[1], testPos2)
                    end
                end
                -- Sides of unit
                for i=0,((targetSize.SkirtSizeZ/2)-1) do
                    local testPos = { targetPos[1]+targetSize.SkirtSizeX + (unitSize.SkirtSizeX/2), targetPos[3] + 1 + (i * 2), 0 }
                    local testPos2 = { targetPos[1]-(unitSize.SkirtSizeX/2), targetPos[3] + 1 + (i*2), 0 }
                    if testPos[1] > 8 and testPos[1] < ScenarioInfo.size[1] - 8 and testPos[2] > 8 and testPos[2] < ScenarioInfo.size[2] - 8 then
                        table.insert(template[1], testPos)
                    end
                    if testPos2[1] > 8 and testPos2[1] < ScenarioInfo.size[1] - 8 and testPos2[2] > 8 and testPos2[2] < ScenarioInfo.size[2] - 8 then
                        table.insert(template[1], testPos2)
                    end
                end
            end
        end
        -- build near the base the engineer is part of, rather than the engineer location
        local baseLocation = {nil, nil, nil}
        if builder.BuildManagerData and builder.BuildManagerData.EngineerManager then
            baseLocation = builder.BuildManagerdata.EngineerManager.Location
        end
        local location = aiBrain:FindPlaceToBuild(buildingType, whatToBuild, template, false, builder, baseLocation[1], baseLocation[3])
        if location then
            if location[1] > 8 and location[1] < ScenarioInfo.size[1] - 8 and location[2] > 8 and location[2] < ScenarioInfo.size[2] - 8 then
                --LOG('Build '..repr(buildingType)..' at adjacency: '..repr(location) )
                AddToBuildQueue(aiBrain, builder, whatToBuild, location, false)
                return true
            end
        end
        -- Build in a regular spot if adjacency not found
        return AIExecuteBuildStructure(aiBrain, builder, buildingType, builder, true,  buildingTemplate, baseTemplate)
    end
    return false
end

---@param aiBrain AIBrain
---@param baseName string
---@param position Vector
---@param builder Unit
---@param constructionData any
function AINewExpansionBase(aiBrain, baseName, position, builder, constructionData)
    local radius = constructionData.ExpansionRadius or 100
    -- PBM Style expansion bases here
    if aiBrain.HasPlatoonList then
    -- Figure out what type of builders to import
        local expansionTypes = constructionData.ExpansionTypes
    if not expansionTypes then
        expansionTypes = { 'Air', 'Land', 'Sea', 'Gate' }
    end

    -- Check if it already exists
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
            --LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': New Engineer for expansion base - ' .. baseName)
            builder.BuilderManagerData.EngineerManager:RemoveUnit(builder)
            aiBrain.BuilderManagers[baseName].EngineerManager:AddUnit(builder, true)
            return
        end
        
        aiBrain:AddBuilderManagers(position, radius, baseName, true)

        -- Move the engineer to the new base managers
        builder.BuilderManagerData.EngineerManager:RemoveUnit(builder)
        aiBrain.BuilderManagers[baseName].EngineerManager:AddUnit(builder, true)

        -- Iterate through bases finding the value of each expansion
        local baseValues = {}
        local highPri = false
        for templateName, baseData in BaseBuilderTemplates do
            local baseValue = baseData.ExpansionFunction(aiBrain, position, constructionData.NearMarkerType)
            table.insert(baseValues, { Base = templateName, Value = baseValue })
            --SPEW('*AI DEBUG: AINewExpansionBase(): Scann next Base. baseValue= ' .. repr(baseValue) .. ' ('..repr(templateName)..')')
            if not highPri or baseValue > highPri then
                --SPEW('*AI DEBUG: AINewExpansionBase(): Possible next Base. baseValue= ' .. repr(baseValue) .. ' ('..repr(templateName)..')')
                highPri = baseValue
            end
        end

        -- Random to get any picks of same value
        local validNames = {}
        for k,v in baseValues do
            if v.Value == highPri then
                table.insert(validNames, v.Base)
            end
        end
        --SPEW('*AI DEBUG: AINewExpansionBase(): validNames for Expansions ' .. repr(validNames))
        local pick = validNames[ Random(1, table.getn(validNames)) ]

        -- Error if no pick
        if not pick then
            LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': Layer Preference - ' .. per .. ' - yielded no base types at - ' .. locationType)
        end

        -- Setup base
        --SPEW('*AI DEBUG: AINewExpansionBase(): ARMY ' .. aiBrain:GetArmyIndex() .. ': Expanding using - ' .. pick .. ' at location ' .. baseName)
        import("/lua/ai/aiaddbuildertable.lua").AddGlobalBaseTemplate(aiBrain, baseName, pick)

        -- If air base switch to building an air factory rather than land
        if (string.find(pick, 'Air') or string.find(pick, 'Water')) then
            --if constructionData.BuildStructures[1] == 'T1LandFactory' then
            --    constructionData.BuildStructures[1] = 'T1AirFactory'
            --end
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

---@param typeString string
---@param typeTable table
---@return boolean
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

---@param pos Vector
---@return table
function FindNearestIntegers(pos)
    local x = math.floor(pos[1])
    local z = math.floor(pos[3])
    return { x, z }
end

---@param aiBrain AIBrain
---@param builder Unit
---@param buildingType string
---@param closeToBuilder any
---@param relative any
---@param buildingTemplate any
---@param baseTemplate any
---@param reference any
---@param NearMarkerType any
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
        -------- Horizontal line
        local buildTable = {}
        if point1[2] == point2[2] then
            local xDir = -1
            if point1[1] < point2[1] then
                xDir = 1
            end
            for j = 1, math.abs(point1[1] - point2[1]) do
                table.insert(buildTable, { point1[1] + (j * xDir) + .5, point1[2] + .5, 0 })
            end
        -------- Vertical line
        elseif point1[1] == point2[1] then
            local yDir = -1
            if point1[2] < point2[2] then
                yDir = 1
            end
            for j = 1, math.abs(point1[2] - point2[2]) do
                table.insert(buildTable, { point1[1] + .5, point1[2] + (j * yDir) + .5, 0 })
            end
        -------- Angled line
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
                --aiBrain:BuildStructure(builder, whatToBuild, v, false)
                AddToBuildQueue(aiBrain, builder, whatToBuild, v, false)
            end
        end
        i = i + 1
    end
    return
end

---@param main any
---@param loc Vector
---@return table
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

---@param aiBrain AIBrain
---@param location Vector
---@return table
function BuildWallsAtLocation(aiBrain, location)
    local mainPos = aiBrain:PBMGetLocationCoords('MAIN')
    return GetBuildingDirection(mainPos, location)
end

------ OPERATION STUFF BELOW ------

--- Takes a group of <name> from <army> in the save file.
--- Populates a base template from this save file.
------ Stores the template naming it <name> in the brain.
---@param brain AIBrain
---@param army Army
---@param name string
function CreateBuildingTemplate(brain, army, name)
    local list = {}
    local template = {}
    local tblUnit = ScenarioUtils.AssembleArmyGroup(army, name)
    local factionIndex = brain:GetFactionIndex()
    if not tblUnit then
        LOG('*ERROR AIBUILDSTRUCTURES - Group: ', repr(name), ' not found for Army: ', repr(army))
    else
        for i,unit in tblUnit do
            for k, unitId in StructureTemplates.RebuildStructuresTemplate[factionIndex] do
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
            for j,buildList in StructureTemplates.BuildingTemplates[factionIndex] do
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

--- Takes a group of <name> from <army> in the save file.
--- Populates a base template from this save file.
--- Appends the template named <templateName> in the brain with new data
---@param brain AIBrain
---@param army Army
---@param name string
---@param templateName string
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
        -- Convert building to the proper type to be built if needed (ex: T2 and T3 factories to T1)
        for i,unit in tblUnit do
            for k, unitId in StructureTemplates.RebuildStructuresTemplate[factionIndex] do
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
            for j,buildList in StructureTemplates.BuildingTemplates[factionIndex] do -- buildList[1] is type ("T1LandFactory"); buildList[2] is unitId (ueb0101)
                local unitPos = { unit.Position[1], unit.Position[3], 0 }
                if unit.buildtype == buildList[2] and buildList[1] ~= 'T3Sonar' then -- if unit to be built is the same id as the buildList unit it needs to be added
                    local inserted = false
                    for k,section in template do -- check each section of the template for the right type
                        if section[1][1] == buildList[1] then
                            table.insert(section, unitPos) -- add position of new unit if found
                            list[unit.buildtype].AmountWanted = list[unit.buildtype].AmountWanted + 1 -- increment num wanted if found
                            inserted = true
                            break
                        end
                    end
                    if not inserted then -- if section doesn't exist create new one
                        table.insert(template, { {buildList[1]}, unitPos }) -- add new build type to list with new unit
                        list[unit.buildtype] =  { StructureType = buildList[1], StructureCategory = unit.buildtype, AmountNeeded = 0, AmountWanted = 1, CloseToBuilder = nil } -- add new section of build list with new unit type information
                    end
                    break
                end
            end
        end
    end
end

---@param unitName string
---@return boolean
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

---@param aiBrain AIBrain
---@param builder Unit
---@param buildingTemplate any
---@param brainBaseTemplate any
---@return boolean
function AIMaintainBuildList(aiBrain, builder, buildingTemplate, brainBaseTemplate)
    if not buildingTemplate then
        buildingTemplate = StructureTemplates.BuildingTemplates[aiBrain:GetFactionIndex()]
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
                                    IssueToUnitClearCommands(builder)
                                    aiBrain:BuildStructure(builder, v.StructureCategory, location, false)
                                    return true
                                end
                            end
                        end
                    end
                end
            elseif aiBrain:FindPlaceToBuild(v.StructureType, v.StructureCategory,  brainBaseTemplate.Template, false, v.CloseToBuilder) then
                IssueStop({builder})
                IssueToUnitClearCommands(builder)
                if AIExecuteBuildStructure(aiBrain, builder, v.StructureType , v.CloseToBuilder, false, buildingTemplate, brainBaseTemplate.Template) then
                    return true
                end
            end
        end
    end
    return false
end

-- Kept for Mod Support
local AIAttackUtils = import("/lua/ai/aiattackutilities.lua")