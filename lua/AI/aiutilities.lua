----------------------------------------------------------------
-- File     :  /lua/AI/aiutilities.lua
-- Author(s): John Comes, Dru Staltman
-- Summary  :
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- --------------------------------------------------------------

local BuildingTemplates = import('/lua/BuildingTemplates.lua').BuildingTemplates
local UnitTemplates = import('/lua/unittemplates.lua').UnitTemplates
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local Utils = import('/lua/utilities.lua')
local AIAttackUtils = import('/lua/AI/aiattackutilities.lua')
local Buff = import('/lua/sim/Buff.lua')
local SUtils = import('/lua/AI/sorianutilities.lua')
local AIBehaviors = import('/lua/ai/AIBehaviors.lua')

function AIGetEconomyNumbers(aiBrain)
    local econ = {}
    econ.MassTrend = aiBrain:GetEconomyTrend('MASS')
    econ.EnergyTrend = aiBrain:GetEconomyTrend('ENERGY')
    econ.MassStorageRatio = aiBrain:GetEconomyStoredRatio('MASS')
    econ.EnergyStorageRatio = aiBrain:GetEconomyStoredRatio('ENERGY')
    econ.EnergyIncome = aiBrain:GetEconomyIncome('ENERGY')
    econ.MassIncome = aiBrain:GetEconomyIncome('MASS')
    econ.EnergyUsage = aiBrain:GetEconomyUsage('ENERGY')
    econ.MassUsage = aiBrain:GetEconomyUsage('MASS')
    econ.EnergyRequested = aiBrain:GetEconomyRequested('ENERGY')
    econ.MassRequested = aiBrain:GetEconomyRequested('MASS')
    econ.EnergyEfficiency = math.min(econ.EnergyIncome / econ.EnergyRequested, 2)
    econ.MassEfficiency = math.min(econ.MassIncome / econ.MassRequested, 2)
    econ.MassRequested = aiBrain:GetEconomyRequested('MASS')
    econ.EnergyStorage = aiBrain:GetEconomyStored('ENERGY')
    econ.MassStorage = aiBrain:GetEconomyStored('MASS')

    if aiBrain.EconomyMonitorThread then
        local econTime = aiBrain:GetEconomyOverTime()

        econ.EnergyRequestOverTime = econTime.EnergyRequested
        econ.MassRequestOverTime = econTime.MassRequested

        econ.EnergyIncomeOverTime = SUtils.Round(econTime.EnergyIncome, 2)
        econ.MassIncomeOverTime = SUtils.Round(econTime.MassIncome, 2)

        econ.EnergyEfficiencyOverTime = math.min(econTime.EnergyIncome / econTime.EnergyRequested, 2)
        econ.MassEfficiencyOverTime = math.min(econTime.MassIncome / econTime.MassRequested, 2)
    end

    if econ.MassStorageRatio ~= 0 then
        econ.MassMaxStored = econ.MassStorage / econ.MassStorageRatio
    else
        econ.MassMaxStored = econ.MassStorage
    end

    if econ.EnergyStorageRatio ~= 0 then
        econ.EnergyMaxStored = econ.EnergyStorage / econ.EnergyStorageRatio
    else
        econ.EnergyMaxStored = econ.EnergyStorage
    end

    return econ
end

function AIGetStructureUnitId(aiBrain, structureType)
    local unitId
    for _, v in BuildingTemplates[aiBrain:GetFactionIndex()] do
        if v[1] == structureType then
            unitId = v[2]
            break
        end
    end

    return unitId
end

function AIGetMobileUnitId(aiBrain, unitType)
    local unitId
    for _, v in UnitTemplates[aiBrain:GetFactionIndex()] do
        if v[1] == unitType then
            unitId = v[2]
            break
        end
    end

    return unitId
end

function AIGetStartLocations(aiBrain)
    local markerList = {}
    for i = 1, 16 do
        if Scenario.MasterChain._MASTERCHAIN_.Markers['ARMY_'..i] then
            table.insert(markerList, Scenario.MasterChain._MASTERCHAIN_.Markers['ARMY_'..i].position)
        end
    end

    return markerList
end

function AIGetSortedScoutingLocations(aiBrain, maxNum)
    local markerList = AIGetMarkerLocations(aiBrain, 'Combat Zone')
    for i = 1, table.getn(ArmyBrains) do
        local tmpLoc = ScenarioUtils.GetMarker('ARMY_' .. i)
        if tmpLoc then
            table.insert(markerList, {Position = tmpLoc.position, Name = 'ARMY_' .. i})
        end
    end

    local expansionMarkers = AIGetMarkerLocations(aiBrain, 'Expansion Area')
    markerList = table.destructiveCat(markerList, expansionMarkers)

    local navalMarkers = AIGetMarkerLocations(aiBrain, 'Naval Area')
    markerList = table.destructiveCat(markerList, navalMarkers)

    local markers = AISortMarkersFromStartPos(aiBrain, markerList, maxNum or 1000)
    local retMarkers = {}
    local numMarkers = table.getn(markers)
    for i = 1, numMarkers do
        rand = Random(1, numMarkers + 1 - i)
        table.insert(retMarkers, markers[rand])
        table.remove(markers, rand)
    end

    return retMarkers
end

function AIGetSortedDefensiveLocations(aiBrain, maxNum)
    local markerList = AIGetMarkerLocations(aiBrain, 'Defensive Point')
    return AISortMarkersFromStartPos(aiBrain, markerList, maxNum or 1000)
end

function AIGetSortedMassLocations(aiBrain, maxNum, tMin, tMax, tRings, tType, position)
    local markerList = AIGetMarkerLocations(aiBrain, 'Mass')
    local newList = {}
    for _, v in markerList do
        -- check distance to map border. (game engine can't build mass closer then 8 mapunits to the map border.) 
        if v.Position[1] < 8 or v.Position[1] > ScenarioInfo.size[1] - 8 or v.Position[3] < 8 or v.Position[3] > ScenarioInfo.size[2] - 8 then
            -- mass marker is too close to border, skip it.
            continue
        end
        if aiBrain:CanBuildStructureAt('ueb1103', v.Position) then
            table.insert(newList, v)
        end
    end

    return AISortMarkersFromLastPos(aiBrain, newList, maxNum, tMin, tMax, tRings, tType, position)
end

function AIGetSortedMassWithEnemy(aiBrain, maxNum, tMin, tMax, tRings, tType, position, category)
    local markerList = AIGetMarkerLocations(aiBrain, 'Mass')
    local newList = {}
    local num = 0
    for _, v in markerList do
        if aiBrain:GetNumUnitsAroundPoint(categories.MASSEXTRACTION, v.Position, 5, 'Enemy') > 0 then
            table.insert(newList, v)
            num = num + 1
            if num >= maxNum then
                break
            end
        end
    end

    return AISortMarkersFromLastPos(aiBrain, newList, maxNum, tMin, tMax, tRings, tType, position)
end

function AIGetSortedHydrocarbonLocation(aiBrain, maxNum, tMin, tMax, tRings, tType, position)
    local markerList = AIGetMarkerLocations(aiBrain, 'Hydrocarbon')
    return AISortMarkersFromLastPos(aiBrain, markerList, maxNum, tMin, tMax, tRings, tType, position)
end

function AIGetSortedNavalLocations(aiBrain, maxNum)
    local markerList = AIGetMarkerLocations(aiBrain, 'Naval Area')
    return AISortMarkersFromLastPos(aiBrain, markerList, maxNum or 1000)
end

-- Function sorts the points by which is closest to a defensive point
function SortLocationsClosestToDefensivePoints(aiBrain, points)
    local defPoints = AIGetMarkerLocations(aiBrain, 'Defensive Point')
    defPoints = AISortMarkersFromLastPos(aiBrain, defPoints, 5, nil, nil, nil, nil, points[1])

    local sortedList = {}
    for i = 1, table.getn(points) do
        local shortest = 320000
        local key, value
        for k, v in points do
            -- Get distance from all poitns here
            local closeDist = false
            for _, marker in defPoints do
                local dist = VDist3(v, marker)
                if not closeDist or dist < closeDist then
                    closeDist = dist
                end
            end

            if closeDist < shortest then
                closeDist = shortest
                value = v
                key = k
            end
        end
        sortedList[i] = value
        table.remove(points, key)
    end

    return sortedList
end

function AISortMarkersFromStartPos(aiBrain, markerList, maxNumber, tMin, tMax, tRings, tType, tType, position)
    local threatCheck = false
    if tMin and tMax and tRings then
        threatCheck = true
    end

    local startPosX, startPosZ = aiBrain:GetArmyStartPos()
    if position then
        startPosX = position[1]
        startPosZ = position[3]
    end

    -- Simple selection sort, this can be made faster later if we decide we need it.
    if table.getn(markerList) == 0 then return {} end

    local num = table.getsize(markerList)
    if maxNumber < num then
        num = maxNumber
    end

    local sortedMarkerList = {}
    for i = 1, num do
        local lowest = nil
        local czX, czZ, distance, key, pos
        for k, v in markerList do
            if v.Position then
                local x = v.Position[1]
                local z = v.Position[3]
                distance = VDist2(startPosX, startPosZ, x, z)
                local threat
                if threatCheck then
                    threat = aiBrain:GetThreatAtPosition(v.Position, tRings, true, tType or 'Overall')
                end
                if not lowest or distance < lowest and (not threatCheck or (threat >= tMin and threat <= tMax)) then
                    pos = v.Position
                    lowest = distance
                    key = k
                end
            else
                LOG('*DEBUG INVALID MARKER:')
            end
        end
        if pos then
            sortedMarkerList[i] = pos
            table.remove(markerList, key)
        end
    end

    return sortedMarkerList
end

function AISortMarkersFromLastPos(aiBrain, markerList, maxNumber, tMin, tMax, tRings, tType, position)
    local threatCheck = false
    if tMin and tMax and tRings then
        threatCheck = true
    end

    local startPosX, startPosZ = aiBrain:GetArmyStartPos()
    if position then
        startPosX = position[1]
        startPosZ = position[3]
    end

    -- Simple selection sort, this can be made faster later if we decide we need it.
    if table.getsize(markerList) == 0 then return {} end

    local num = table.getsize(markerList)
    if maxNumber < num then
        num = maxNumber
    end

    local sortedMarkerList = {}
    local lastX = startPosX
    local lastZ = startPosZ
    for i = 1, num do
        local threat
        local lowest
        local czX, czZ, pos, distance, key
        for k, v in markerList do
            local x = v.Position[1]
            local z = v.Position[3]
            distance = VDist2(lastX, lastZ, x, z)
            if threatCheck then
                threat = aiBrain:GetThreatAtPosition(v.Position, tRings, true, tType or 'Overall')
            end
            if (not lowest or distance < lowest) and (not threatCheck or (threat >= tMin and threat <= tMax)) then
                pos = v.Position
                lowest = distance
                key = k
            end
        end
        if pos then
            sortedMarkerList[i] = pos
            lastX = pos[1]
            lastZ = pos[3]
            table.remove(markerList, key)
        end
    end

    return sortedMarkerList
end


function AIGetMarkerLocations(aiBrain, markerType)
    local markerList = {}
    if markerType == 'Start Location' then
        local tempMarkers = AIGetMarkerLocations(aiBrain, 'Blank Marker')
        for k, v in tempMarkers do
            if string.sub(v.Name, 1, 5) == 'ARMY_' then
                table.insert(markerList, {Position = v.Position, Name = v.Name})
            end
        end
    else
        local markers = ScenarioUtils.GetMarkers()
        if markers then
            for k, v in markers do
                if v.type == markerType then
                    table.insert(markerList, {Position = v.position, Name = k})
                end
            end
        end
    end

    return markerList
end

function AIGetMarkerLocationsEx(aiBrain, markerType)
    local markerList = {}
    local markers = ScenarioUtils.GetMarkers()
    if markers then
        markerList = GenerateMarkerList(markerList,markers,markerType)
        LOG('AIGetMarkerLocationsEx '..table.getn(markerList)..' markers for '..markerType)
        -- If we have no Amphibious Path Nodes, generate them from Land and Water Nodes
        if markerType == 'Amphibious Path Node' and table.getn(markerList) <= 0 then
            markerList = GenerateAmphibiousMarkerList(markerList,markers,'Land Path Node')
            markerList = GenerateAmphibiousMarkerList(markerList,markers,'Water Path Node')
            LOG('AIGetMarkerLocationsEx '..table.getn(markerList)..' markers for '..markerType..' (generated from Land/Water markers).')
            -- Inject the new amphibious marker to the MasterChain
            for k, v in markerList do
                if v.type == 'Amphibious Path Node' then
                    Scenario.MasterChain._MASTERCHAIN_.Markers[v.name] = v
                end
            end
        end
    end
    -- Make a list of all the markers in the scenario that are of the markerType
    return markerList
end

function GenerateMarkerList(markerList,markers,markerType)
    for k, v in markers do
        if v.type == markerType then
            -- copy the marker to a local variable. We don't want to change values inside the original markers array
            local marker = table.copy(v)
            marker.name = k
            -- insert the (default)graph if missing.
            if not marker.graph then
                marker.graph = 'Default'..markerType
            end
            table.insert(markerList, marker)
        end
    end
    return markerList
end

function GenerateAmphibiousMarkerList(markerList,markers,markerType)
    for k, v in markers do
        local marker = table.copy(v)
        if marker.type == markerType then
            -- transform adjacentTo to Amphibious marker names
            local adjacentTo = ''
            for i, node in STR_GetTokens(marker.adjacentTo, ' ') do
                if adjacentTo == '' then
                    adjacentTo = 'Amph'..node
                else
                    adjacentTo = adjacentTo..' '..'Amph'..node
                end
            end
            marker.adjacentTo = adjacentTo
            -- Add 'Amph' to marker name
            marker.name = 'Amph'..k
            marker.graph = 'DefaultAmphibious'
            marker.type = 'Amphibious Path Node'
            marker.color = 'ff00FFFF'
            table.insert(markerList, marker)
        end
    end
    return markerList
end

function AIGetMarkerPositionsAroundLocation(aiBrain, markerType, pos, radius, threatMin, threatMax, threatRings, threatType)
    local markers = AIGetMarkersAroundLocation(aiBrain, markerType, pos, radius, threatMin, threatMax, threatRings, threatType)
    local retMarkers = {}
    for _, v in markers do
        table.insert(markers, v.Position)
    end

    return retMarkers
end

function AIGetMarkersAroundLocation(aiBrain, markerType, pos, radius, threatMin, threatMax, threatRings, threatType)
    local markers = AIGetMarkerLocations(aiBrain, markerType)
    local returnMarkers = {}
    for _, v in markers do
        local dist = VDist2(pos[1], pos[3], v.Position[1], v.Position[3])
        if dist < radius then
            if not threatMin then
                table.insert(returnMarkers, v)
            else
                local threat = aiBrain:GetThreatAtPosition(v.Position, threatRings, true, threatType or 'Overall')
                if threat >= threatMin and threat <= threatMax then
                    table.insert(returnMarkers, v)
                end
            end
        end
    end

    return returnMarkers
end

function AIGetMarkerLeastUnits(aiBrain, markerType, markerRadius, pos, posRad, unitCount, unitCat, tMin, tMax, tRings, tType)
    local markers = {}
    if markerType == 'Start Location' then
        local tempMarkers = AIGetMarkersAroundLocation(aiBrain, 'Blank Marker', pos, posRad, tMin, tMax, tRings, tType)
        local startX, startZ = aiBrain:GetArmyStartPos()
        for k, v in tempMarkers do
            if string.sub(v.Name, 1, 5) == 'ARMY_' and VDist2(startX, startZ, v.Position[1], v.Position[3]) > 20 then
                table.insert(markers, v)
            end
        end
    else
        markers = AIGetMarkersAroundLocation(aiBrain, markerType, pos, posRad, tMin, tMax, tRings, tType)
    end

    local lowest
    local retPos = false
    local retName = false
    for k, v in markers do
        local numUnits = table.getn(GetOwnUnitsAroundPoint(aiBrain, unitCat, v.Position, markerRadius, tMin, tMax, tRings, tType))
        if (not retPos and numUnits < unitCount) or (numUnits < lowest and numUnits < unitCount) then
            lowest = numUnits
            retPos = v.Position
            retName = v.Name
        end
    end

    return retPos, retName
end

-- Expansion functions - Finds bases needing expansion bases
function GetAlliesThreat(aiBrain, marker, threatRings, threatType)
    local armyIndex = aiBrain:GetArmyIndex()
    local threat = 0
    for _, v in ArmyBrains do
        if v ~= aiBrain and IsAlly(v:GetArmyIndex(), armyIndex) then
            threat = aiBrain:GetNumUnitsAroundPoint(categories.ALLUNITS - categories.MASSEXTRACTION - categories.MOBILE, marker.Position, 30, 'Ally')
        end
    end

    return threat
end

function AIFilterAlliedBases(aiBrain, positions)
    local retPositions = {}
    for _, v in positions do
        local threat = GetAlliesThreat(aiBrain, v, 2, 'StructuresNotMex')
        if threat == 0 then
            table.insert(retPositions, v)
        end
    end

    return retPositions
end

function AIFindMarkerNeedsEngineer(aiBrain, pos, radius, tMin, tMax, tRings, tType, positions)
    local closest = false
    local retPos, retName
    local positions = AIFilterAlliedBases(aiBrain, positions)
    for _, v in positions do
        if not aiBrain.BuilderManagers[v.Name] then
            if not closest or VDist3(pos, v.Position) < closest then
                closest = VDist3(pos, v.Position)
                retPos = v.Position
                retName = v.Name
            end
        else
            local managers = aiBrain.BuilderManagers[v.Name]
            if managers.EngineerManager:GetNumUnits('Engineers') == 0 and managers.FactoryManager:GetNumFactories() == 0 then
                if not closest or VDist3(pos, v.Position) < closest then
                    closest = VDist3(pos, v.Position)
                    retPos = v.Position
                    retName = v.Name
                end
            end
        end
    end

    return retPos, retName
end

-- We use both Blank Marker that are army names as well as the new Large Expansion Area to determine big expansion bases
function AIFindStartLocationNeedsEngineer(aiBrain, locationType, radius, tMin, tMax, tRings, tType, eng)
    local pos = aiBrain:PBMGetLocationCoords(locationType)
    if not pos then
        return false
    end

    local validPos = AIGetMarkersAroundLocation(aiBrain, 'Large Expansion Area', pos, radius, tMin, tMax, tRings, tType)

    local positions = AIGetMarkersAroundLocation(aiBrain, 'Blank Marker', pos, radius, tMin, tMax, tRings, tType)
    local startX, startZ = aiBrain:GetArmyStartPos()
    for _, v in positions do
        if string.sub(v.Name, 1, 5) == 'ARMY_' then
            if startX ~= v.Position[1] and startZ ~= v.Position[3] then
                table.insert(validPos, v)
            end
        end
    end

    local retPos, retName
    if eng then
        retPos, retName = AIFindMarkerNeedsEngineer(aiBrain, eng:GetPosition(), radius, tMin, tMax, tRings, tType, validPos)
    else
        retPos, retName = AIFindMarkerNeedsEngineer(aiBrain, pos, radius, tMin, tMax, tRings, tType, validPos)
    end

    return retPos, retName
end

function AIFindExpansionAreaNeedsEngineer(aiBrain, locationType, radius, tMin, tMax, tRings, tType, eng)
    local pos = aiBrain:PBMGetLocationCoords(locationType)
    if not pos then
        return false
    end
    local positions = AIGetMarkersAroundLocation(aiBrain, 'Expansion Area', pos, radius, tMin, tMax, tRings, tType)

    local retPos, retName
    if eng then
        retPos, retName = AIFindMarkerNeedsEngineer(aiBrain, eng:GetPosition(), radius, tMin, tMax, tRings, tType, positions)
    else
        retPos, retName = AIFindMarkerNeedsEngineer(aiBrain, pos, radius, tMin, tMax, tRings, tType, positions)
    end

    return retPos, retName
end

function AIFindNavalAreaNeedsEngineer(aiBrain, locationType, radius, tMin, tMax, tRings, tType, eng)
    local pos = aiBrain:PBMGetLocationCoords(locationType)
    if not pos then
        return false
    end
    local positions = AIGetMarkersAroundLocation(aiBrain, 'Naval Area', pos, radius, tMin, tMax, tRings, tType)

    local retPos, retName
    if eng then
        retPos, retName = AIFindMarkerNeedsEngineer(aiBrain, eng:GetPosition(), radius, tMin, tMax, tRings, tType, positions)
    else
        retPos, retName = AIFindMarkerNeedsEngineer(aiBrain, pos, radius, tMin, tMax, tRings, tType, positions)
    end

    return retPos, retName
end

function AIFindNavalDefensivePointNeedsStructure(aiBrain, locationType, radius, category, markerRadius, unitMax, tMin, tMax, tRings, tType)
    local pos = aiBrain:PBMGetLocationCoords(locationType)
    if not pos then
        return false
    end
    local positions = AIGetMarkersAroundLocation(aiBrain, 'Naval Defensive Point', pos, radius, tMin, tMax, tRings, tType)

    local retPos, retName, lowest
    for k, v in positions do
        local numUnits = table.getn(GetOwnUnitsAroundPoint(aiBrain, ParseEntityCategory(category), v.Position, markerRadius))
        if numUnits < unitMax then
            if not retPos or numUnits < lowest then
                lowest = numUnits
                retName = v.Name
                retPos = v.Position
            end
        end
    end

    return retPos, retName
end

function AIFindDefensivePointNeedsStructure(aiBrain, locationType, radius, category, markerRadius, unitMax, tMin, tMax, tRings, tType)
    local pos = aiBrain:PBMGetLocationCoords(locationType)
    if not pos then
        return false
    end
    local positions = AIGetMarkersAroundLocation(aiBrain, 'Defensive Point', pos, radius, tMin, tMax, tRings, tType)

    local retPos, retName, lowest
    for k, v in positions do
        local numUnits = table.getn(GetOwnUnitsAroundPoint(aiBrain, ParseEntityCategory(category), v.Position, markerRadius))
        if numUnits < unitMax then
            if not retPos or numUnits < lowest then
                lowest = numUnits
                retName = v.Name
                retPos = v.Position
            end
        end
    end

    return retPos, retName
end

function AIFindFirebaseLocation(aiBrain, locationType, radius, markerType, tMin, tMax, tRings, tType, maxUnits, unitCat, markerRadius)
    -- Get location of commander
    local estartX, estartZ = aiBrain:GetCurrentEnemy():GetArmyStartPos()
    local threatPos = {estartX, 0, estartZ}

    -- Get markers
    local markerList = AIGetMarkerLocations(aiBrain, markerType)

    -- For each marker, check against threatpos. Save markers that are within the FireBaseRange
    local inRangeList = {}
    for _, marker in markerList do
        local distSq = VDist2Sq(marker.Position[1], marker.Position[3], threatPos[1], threatPos[3])

        if distSq < radius * radius  then
            table.insert(inRangeList, marker)
        end
    end

    -- Pick the closest, least-threatening position in range
    local bestDistSq = 9999999999
    local bestThreat = 9999999999
    local bestMarker = false
    local maxThreat = tMax or 1
    local catCheck = ParseEntityCategory(unitCat) or categories.ALLUNITS
    local reference = false
    local refName = false
    for _, marker in inRangeList do
        local threat = aiBrain:GetThreatAtPosition(marker.Position, 1, true, 'AntiSurface')
        if threat < maxThreat then
            local numUnits = table.getn(GetOwnUnitsAroundPoint(aiBrain, catCheck, marker.Position, markerRadius or 20))
            if numUnits < maxUnits then
                if threat < bestThreat and threat < maxThreat then
                    bestDistSq = VDist2Sq(threatPos[1], threatPos[3], marker.Position[1], marker.Position[3])
                    bestThreat = threat
                    bestMarker = marker
                elseif threat == bestThreat then
                    local distSq = VDist2Sq(threatPos[1], threatPos[3], marker.Position[1], marker.Position[3])
                    if distSq > bestDistSq then
                        bestDistSq = distSq
                        bestMarker = marker
                    end
                end
            end
        end
    end
    if bestMarker then
        reference = bestMarker.Position
        refName = bestMarker.Name
    end

    return reference, refName
end

function AIGetMarkerMostUnits(aiBrain, markerType, markerRadius, pos, posRad, unitCount, unitCat, tMin, tMax, tRings, tType)
    local markers = AIGetMarkersAroundLocation(aiBrain, markerType, pos, posRad, tMin, tMax, tRings, tType)
    local lowest
    local retPos = false
    local retName = false
    for _, v in markers do
        local numUnits = table.getn(GetOwnUnitsAroundPoint(aiBrain, unitCat, v.Position, markerRadius, tMin, tMax, tRings, tType))
        if not retPos or numUnits > lowest then
            lowest = numUnits
            retPos = v.Position
            retName = v.Name
        end
    end

    return retPos, retName
end

function AIGetClosestMarkerLocation(aiBrain, markerType, startX, startZ, extraTypes)
    local markerList = AIGetMarkerLocations(aiBrain, markerType)
    if extraTypes then
        for num, pType in extraTypes do
            local moreMarkers = AIGetMarkerLocations(aiBrain, pType)
            if table.getn(moreMarkers) > 0 then
                for _, v in moreMarkers do
                    table.insert(markerList, {Position = v.Position, Name = v.Name})
                end
            end
        end
    end

    local loc, distance, lowest, name = nil
    for _, v in markerList do
        local x = v.Position[1]
        local y = v.Position[2]
        local z = v.Position[3]
        distance = VDist2(startX, startZ, x, z)
        if not lowest or distance < lowest then
            loc = v.Position
            name = v.Name
            lowest = distance
        end
    end

    return loc, name
end


function AIGetClosestThreatMarkerLoc(aiBrain, markerType, startX, startZ, threatMin, threatMax, rings, threatType)
    local markerList = AIGetMarkerLocations(aiBrain, markerType)
    local loc, name, distance, lowest = nil

    for k, v in markerList do
        local x = v.Position[1]
        local z = v.Position[3]
        distance = VDist2(startX, startZ, x, z)
        local threat = aiBrain:GetThreatAtPosition({x, 0, z}, rings, true, threatType or 'Overall')
        if (not lowest or distance < lowest) and threat >= threatMin and threat <= threatMax then
            loc = v.Position
            name = v.Name
            lowest = distance
        end
    end

    return loc, name
end

function AIFindDefensiveArea(aiBrain, unit, category, range)
    if not unit.Dead then
        -- Build a grid to find units near
        local gridSize = range / 5
        if gridSize > 150 then
            gridSize = 150
        end


        local highPoint = false
        local highNum = false
        local unitPos = unit:GetPosition()
        local distance
        local startPosX, startPosZ = aiBrain:GetArmyStartPos()
        for i = -5, 5 do
            for j = -5, 5 do
                local height = GetTerrainHeight(unitPos[1] - (gridSize * i), unitPos[3] - (gridSize * j))
                if GetSurfaceHeight(unitPos[1] - (gridSize * i), unitPos[3] - (gridSize * j)) > height then
                    height = GetSurfaceHeight(unitPos[1] - (gridSize * i), unitPos[3] - (gridSize * j))
                end

                local checkPos = {unitPos[1] - (gridSize * i), height, unitPos[3] - (gridSize * j)}
                local units = aiBrain:GetUnitsAroundPoint(category, checkPos, gridSize, 'Ally')
                local tempNum = 0
                for k, v in units do
                    if EntityCategoryContains(categories.TECH3, v) then
                        tempNum = tempNum + 10
                    elseif EntityCategoryContains(categories.TECH2, v) then
                        tempNum = tempNum + 5
                    else
                        tempNum = tempNum + 1
                    end
                end

                local units = aiBrain:GetUnitsAroundPoint(categories.MOBILE, checkPos, gridSize, 'Enemy')
                for k, v in units do
                    if EntityCategoryContains(categories.TECH3, v) then
                        tempNum = tempNum - 10
                    elseif EntityCategoryContains(categories.TECH2, v) then
                        tempNum = tempNum - 5
                    else
                        tempNum = tempNum - 1
                    end
                end

                if not highNum or tempNum > highNum then
                    highNum = tempNum
                    distance = VDist2(startPosX, startPosZ, checkPos[1], checkPos[3])
                    highPoint = checkPos
                elseif tempNum == highNum then
                    local tempDist = VDist2(startPosX, startPosZ, checkPos[1], checkPos[3])
                    if tempDist < distance then
                        highNum = tempNum
                        highPoint = checkPos
                    end
                end
            end
        end
        return highPoint
    else
        return {0, 0, 0}
    end
end

function GetLocationNeedingWalls(aiBrain, radius, count, unitCategory, tMin, tMax, tRings, tType)
    local positions = {}
    if aiBrain:PBMHasPlatoonList() then
        for k, v in aiBrain.PBM.Locations do
            if v.LocationType ~= 'MAIN' then
                table.insert(positions, v.Location)
            end
        end
    elseif aiBrain.BuilderManagers['MAIN'] then
        table.insert(positions, aiBrain.BuilderManagers['MAIN'].FactoryManager:GetLocationCoords())
    end

    local bestFit
    local mostUnits
    local mainPos = aiBrain:PBMGetLocationCoords('MAIN')
    local otherPos = AIGetMarkersAroundLocation(aiBrain, 'Defensive Point', mainPos, radius, tMin, tMax, tRings, tType)
    for _, v in otherPos do
        table.insert(positions, v.Position)
    end
    for _, v in positions do
        if Utils.XZDistanceTwoVectors(v, mainPos) < radius then
            local tempUnits = table.getn(GetOwnUnitsAroundPoint(aiBrain, ParseEntityCategory(unitCategory), v, 30))
            local numWalls = table.getn(GetOwnUnitsAroundPoint(aiBrain, categories.WALL, v, 40))
            if tempUnits > count and numWalls < 10 and (not bestFit or tempUnits > mostUnits) then
                bestFit = v
                mostUnits = tempUnits
            end
        end
    end

    if bestFit then
        return bestFit
    else
        return false
    end
end

function AIGetReclaimablesAroundLocation(aiBrain, locationType)
    local position, radius
    if aiBrain:PBMHasPlatoonList() then
        for _, v in aiBrain.PBM.Locations do
            if v.LocationType == locationType then
                position = v.Location
                radius = v.Radius
                break
            end
        end
    elseif aiBrain.BuilderManagers[locationType] then
        radius = aiBrain.BuilderManagers[locationType].FactoryManager:GetLocationRadius()
        position = aiBrain.BuilderManagers[locationType].FactoryManager:GetLocationCoords()
    end

    if not position then
        return false
    end

    local x1 = position[1] - radius
    local x2 = position[1] + radius
    local z1 = position[3] - radius
    local z2 = position[3] + radius
    local rect = Rect(x1, z1, x2, z2)

    return GetReclaimablesInRect(rect)
end

-- Assist Utility functions
function GetAssistees(aiBrain, locationType, assisteeType, buildingCategory, assisteeCategory)
    if assisteeType == 'Factory' then
        -- Sift through the factories in the location
        local manager = aiBrain.BuilderManagers[locationType].FactoryManager
        return manager:GetFactoriesWantingAssistance(buildingCategory, assisteeCategory)
    elseif assisteeType == 'Engineer' then
        local manager = aiBrain.BuilderManagers[locationType].EngineerManager
        return manager:GetEngineersWantingAssistance(buildingCategory, assisteeCategory)
    elseif assisteeType == 'Structure' then
        local manager = aiBrain.BuilderManagers[locationType].PlatoonFormManager
        return manager:GetUnitsBeingBuilt(buildingCategory, assisteeCategory)
    else
        error('*AI ERROR: Invalid assisteeType - ' .. assisteeType)
    end

    return false
end

-- Assist factories based on what factories have less units helping
function AIEngineersAssistFactories(aiBrain, engineers, factories)
    local factoryData = {}
    local lowNum, key, value, tempNum, tempActive, setVal

    local active = false
    for _, v in factories do
        if not v.Dead and (v:IsUnitState('Building') or v:GetNumBuildOrders(categories.ALLUNITS) > 0) then
            active = true
            break
        end
    end

    -- Sort Factories based on number of guards
    for i = 1, table.getn(factories) do
        lowNum = false
        key = -1
        value = false
        tempActive = false

        for j, v in factories do
            -- We only want factories that are actively doin stuff and aren\'t like dead
            local guards = v:GetGuards()
            local tempNum = 0
            for n, g in guards do
                if not EntityCategoryContains(categories.FACTORY, g) then
                    tempNum = tempNum + 1
                end
            end
            if not v.Dead then
                setVal = false
                tempActive = v:IsUnitState('Building') or (v:GetNumBuildOrders(categories.ALLUNITS) > 0)
                if not active and tempActive then
                    active = true
                    setVal = true
                elseif active and tempActive and (not lowNum or tempNum < lowNum) then
                    setVal = true
                elseif not active and not tempActive and (not lowNum or tempNum < lowNum) then
                    setVal = true
                end
                if setVal then
                    lowNum = table.getn(v:GetGuards())
                    value = v
                    key = j
                end
            end
        end
        if key > 0 then
            factoryData[i] = {Factory = value, NumGuards = lowNum}
            table.remove(factories, key)
        end
    end

    -- Find a factory for each engineer and update number of guards
    for unitNum, unit in engineers do
        lowNum = false
        key = 0
        for k, v in factoryData do
            if not lowNum or v.NumGuards < lowNum then
                lowNum = v.NumGuards
                key = k
            end
        end

        if lowNum then
            IssueGuard({unit}, factoryData[key].Factory)
            factoryData[key].NumGuards = factoryData[key].NumGuards + 1
        else
            aiBrain:AssignUnitsToPlatoon('ArmyPool', {unit}, 'Unassigned', 'NoFormation')
        end
    end

    return true
end

-- Find all units working together on a builder and return all factories
function AIReturnAssistingFactories(factory)
    local guards = factory:GetGuards()
    local guardFacs = {}
    table.insert(guardFacs, factory)
    for k, v in guards do
        if not v.Dead and EntityCategoryContains(categories.FACTORY, v) then
            table.insert(guardFacs, v)
        end
    end

    return guardFacs
end

function GetBasePatrolPoints(aiBrain, location, radius, layer)
    if type(location) == 'string' then
        if aiBrain:PBMHasPlatoonList() then
            for k, v in aiBrain.PBM.Locations do
                if v.LocationType == location then
                    radius = v.Radius
                    location = v.Location
                    break
                end
            end
        elseif aiBrain.BuilderManagers[location] then
            radius = aiBrain.BuilderManagers[location].FactoryManager:GetLocationRadius()
            location = aiBrain.BuilderManagers[location].FactoryManager:GetLocationCoords()
        end
        if not radius then
            error('*AI ERROR: Invalid locationType- '..location..' for army- '..aiBrain.Name, 2)
        end
    end

    if not location or not radius then
        error('*AI ERROR: Need location and radius or locationType for AIUtilities.GetBasePatrolPoints', 2)
    end

    if not layer then
        layer = 'Land'
    end

    local vecs = aiBrain:GetBaseVectors()
    local locList = {}
    for k, v in vecs do
        if LayerCheckPosition(v, layer) and VDist2(v[1], v[3], location[1], location[3]) < radius then
            table.insert(locList, v)
        end
    end

    if table.getsize(locList) == 0 then return {} end

    -- Sort the locations from point to closest point, that way it  makes a nice patrol path
    local sortedList = {}
    local lastX = location[1]
    local lastZ = location[3]
    local num = table.getsize(locList)
    for i = 1, num do
        local lowest
        local czX, czZ, pos, distance, key
        for k, v in locList do
            local x = v[1]
            local z = v[3]
            distance = VDist2(lastX, lastZ, x, z)
            if not lowest or distance < lowest then
                pos = v
                lowest = distance
                key = k
            end
        end
        if not pos then return {} end
        sortedList[i] = pos
        lastX = pos[1]
        lastZ = pos[3]
        table.remove(locList, key)
    end

    return sortedList
end

function GetUnitBaseStructureVector(unit)
    if not unit.Dead then
        local pos = unit:GetPosition()
        pos[1] = pos[1] + 16
        pos[3] = pos[3] + 16
        local x = math.floor(pos[1] / 32) - 1
        local z = math.floor(pos[3] / 32) - 1
        local height = GetTerrainHeight(x, z)
        if GetSurfaceHeight(x, z) > height then
            height = GetSurfaceHeight(x, z)
        end
        return {(x * 32) + 16 , height,  (z * 32) + 16}
    else
        return false
    end
end

function GetOwnUnitsAroundPoint(aiBrain, category, location, radius, min, max, rings, tType)
    local units = aiBrain:GetUnitsAroundPoint(category, location, radius, 'Ally')
    local index = aiBrain:GetArmyIndex()
    local retUnits = {}
    local checkThreat = false
    if min and max and rings then
        checkThreat = true
    end
    for _, v in units do
        if not v.Dead and not v:IsBeingBuilt() and v:GetAIBrain():GetArmyIndex() == index then
            if checkThreat then
                local threat = aiBrain:GetThreatAtPosition(v:GetPosition(), rings, true, tType or 'Overall')
                if threat >= min and threat <= max then
                    table.insert(retUnits, v)
                end
            else
                table.insert(retUnits, v)
            end
        end
    end

    return retUnits
end

function GetBrainUnitsAroundPoint(aiBrain, category, location, radius, tBrain)
    local units = aiBrain:GetUnitsAroundPoint(category, location, radius)
    local tIndex = tBrain:GetArmyIndex()
    local retTable = {}
    for _, v in units do
        if not v.Dead and v:GetAIBrain():GetArmyIndex() == tIndex then
            table.insert(retTable, v)
        end
    end

    return retTable
end

function LayerCheckPosition(pos, layer)
    if pos[1] > 0 and pos[1] < ScenarioInfo.size[1] and pos[3] > 0 and pos[3] < ScenarioInfo.size[2] then
        local surf = GetSurfaceHeight(pos[1], pos[3])
        local terr = GetTerrainHeight(pos[1], pos[3])
        if layer == 'Air' then
            return true
        elseif surf > terr and layer == 'Sea' then
            return true
        elseif terr >= surf and layer == 'Land' then
            return true
        else
            return false
        end
    else
        return false
    end
end

function GetNearestPathingPoint(position)
    if not position then
        return false
    end
    local x = math.floor(position[1] / 8)
    local z = math.floor(position[3] / 8)
    retPos = {(x * 8) , 0,  (z * 8)}
    if retPos[1] == 0 then
        retPos[1] = 1
    elseif retPos[1] == ScenarioInfo.size[1] then
        retPos[1] = retPos[1] - 1
    end
    if retPos[3] == 0 then
        retPos[3] = 1
    elseif retPos[3] == ScenarioInfo.size[2] then
        retPos[3] = retPos[3] - 1
    end

    return retPos
end

function CheckUnitPathingEx(destPos, curlocation, unit)
    if unit.Dead then
        return false
    end

    local pathingType = 'Land'
    local mType = unit:GetBlueprint().Physics.MotionType
    if mType == 'RULEUMT_AmphibiousFloating' or mType == 'RULEUMT_Hover' or mType == 'RULEUMT_Amphibious' then
        pathingType = 'Amphibious'
    elseif mType == 'RULEUMT_Water' or mType == 'RULEUMT_SurfacingSub' then
        pathingType = 'Water'
    elseif mType == 'RULEUMT_Air' then
        return true
    end

    local surf = GetSurfaceHeight(destPos[1], destPos[3])
    local terr = GetTerrainHeight(destPos[1], destPos[3])
    local land = terr >= surf
    local result = false
    local finalPos = {destPos[1], terr, destPos[3] }
    local bestGoal = curlocation
    if land then
        if pathingType == 'Land' or pathingType == 'Amphibious' then
            result, bestGoal = unit:CanPathTo(finalPos)
        end
    else
        if pathingType == 'Water' or pathingType == 'Amphibious' then
            result, bestGoal = unit:CanPathTo(finalPos)
        end
    end

    return result
end

function FindPointInTable(point, posTable)
    for _, v in posTable do
        if point[1] == v[1] and point[2] == v[2] and point[3] == v[3] then
            return true
        end
    end

    return false
end

function AIFindBrainTargetInRange(aiBrain, platoon, squad, maxRange, atkPri, enemyBrain)
    local position = platoon:GetPlatoonPosition()
    if not aiBrain or not position or not maxRange or not platoon or not enemyBrain then
        return false
    end

    local enemyIndex = enemyBrain:GetArmyIndex()
    local targetUnits = aiBrain:GetUnitsAroundPoint(categories.ALLUNITS, position, maxRange, 'Enemy')
    for _, v in atkPri do
        local category = v
        if type(category) == 'string' then
            category = ParseEntityCategory(category)
        end
        local retUnit = false
        local distance = false
        for num, unit in targetUnits do
            if not unit.Dead and EntityCategoryContains(category, unit) and unit:GetAIBrain():GetArmyIndex() == enemyIndex and platoon:CanAttackTarget(squad, unit) then
                local unitPos = unit:GetPosition()
                if not retUnit or Utils.XZDistanceTwoVectors(position, unitPos) < distance then
                    retUnit = unit
                    distance = Utils.XZDistanceTwoVectors(position, unitPos)
                end
            end
        end
        if retUnit then
            return retUnit
        end
    end

    return false
end

function AIFindBrainTargetAroundPoint(aiBrain, position, maxRange, category)
    if not aiBrain or not position or not maxRange then
        return false
    end

    local testCat = category
    if type(testCat) == 'string' then
        testCat = ParseEntityCategory(testCat)
    end

    local targetUnits = aiBrain:GetUnitsAroundPoint(testCat, position, maxRange, 'Enemy')

    local retUnit = false
    local distance = false
    for num, unit in targetUnits do
        if not unit.Dead then
            local unitPos = unit:GetPosition()
            if not retUnit or Utils.XZDistanceTwoVectors(position, unitPos) < distance then
                retUnit = unit
                distance = Utils.XZDistanceTwoVectors(position, unitPos)
            end
        end
    end

    if retUnit then
        return retUnit
    end

    return false
end

function RandomLocation(x, z)
    local finalX = x + Random(-30, 30)
    while finalX <= 0 or finalX >= ScenarioInfo.size[1] do
        finalX = x + Random(-30, 30)
    end

    local finalZ = z + Random(-30, 30)
    while finalZ <= 0 or finalZ >= ScenarioInfo.size[2] do
        finalZ = z + Random(-30, 30)
    end

    local movePos = {finalX, 0, finalZ}
    local height = GetTerrainHeight(movePos[1], movePos[3])
    if GetSurfaceHeight(movePos[1], movePos[3]) > height then
        height = GetSurfaceHeight(movePos[1], movePos[3])
    end
    movePos[2] = height

    return movePos
end

function FindIdleGates(aiBrain)
    local gates = aiBrain:GetListOfUnits(categories.GATE, true)
    if gates and table.getn(gates) > 0 then
        local retGates = {}
        for _, v in gates do
            if not v:IsUnitState('Building') and not v:IsUnitState('TransportLoading') then
                table.insert(retGates, v)
            end
        end
        return retGates
    end

    return false
end

----------------------------------------------------------
-- Utility Function
-- Returns the number of slots the transport has available
----------------------------------------------------------
function GetNumTransportSlots(unit)
    local bones = {
        Large = 0,
        Medium = 0,
        Small = 0,
    }
    for i = 1, unit:GetBoneCount() do
        if unit:GetBoneName(i) ~= nil then
            if string.find(unit:GetBoneName(i), 'Attachpoint_Lrg') then
                bones.Large = bones.Large + 1
            elseif string.find(unit:GetBoneName(i), 'Attachpoint_Med') then
                bones.Medium = bones.Medium + 1
            elseif string.find(unit:GetBoneName(i), 'Attachpoint') then
                bones.Small = bones.Small + 1
            end
        end
    end

    return bones
end

----------------------------------------------------------------
-- Utility Function
-- Returns the number of transports required to move the platoon
----------------------------------------------------------------
function GetNumTransports(units)
    local transportNeeded = {
        Small = 0,
        Medium = 0,
        Large = 0,
    }
    local transportClass
    for k, v in units do
        if not v.Dead then
            transportClass = v:GetBlueprint().Transport.TransportClass
            if(transportClass == 1) then
                transportNeeded.Small = transportNeeded.Small + 1
            elseif(transportClass == 2) then
                transportNeeded.Medium = transportNeeded.Medium + 1
            elseif(transportClass == 3) then
                transportNeeded.Large = transportNeeded.Large + 1
            else
                transportNeeded.Small = transportNeeded.Small + 1
            end
        end
    end

    return transportNeeded
end

--------------------------------------------------------------------
-- Utility Function
-- Function that gets the correct number of transports for a platoon
--------------------------------------------------------------------
function GetTransports(platoon, units)
    if not units then
        units = platoon:GetPlatoonUnits()
    end

    -- Check for empty platoon
    if table.getn(units) == 0 then
        return 0
    end

    local neededTable = GetNumTransports(units)
    local transportsNeeded = false
    if neededTable.Small > 0 or neededTable.Medium > 0 or neededTable.Large > 0 then
        transportsNeeded = true
    end


    local aiBrain = platoon:GetBrain()
    local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')

    -- Make sure more are needed
    local tempNeeded = {}
    tempNeeded.Small = neededTable.Small
    tempNeeded.Medium = neededTable.Medium
    tempNeeded.Large = neededTable.Large

    local location = platoon:GetPlatoonPosition()
    if not location then
        -- We can assume we have at least one unit here
        location = units[1]:GetCachePosition()
    end

    if not location then
        return 0
    end

    -- Determine distance of transports from platoon
    local transports = {}
    for _, unit in pool:GetPlatoonUnits() do
        if not unit.Dead and EntityCategoryContains(categories.TRANSPORTATION - categories.uea0203, unit) and not unit:IsUnitState('Busy') and not unit:IsUnitState('TransportLoading') and table.getn(unit:GetCargo()) < 1 and unit:GetFractionComplete() == 1 then
            local unitPos = unit:GetPosition()
            local curr = {Unit = unit, Distance = VDist2(unitPos[1], unitPos[3], location[1], location[3]),
                           Id = unit:GetUnitId()}
            table.insert(transports, curr)
        end
    end

    local numTransports = 0
    local transSlotTable = {}
    if table.getn(transports) > 0 then
        local sortedList = {}
        -- Sort distances
        for k = 1, table.getn(transports) do
            local lowest = -1
            local key, value
            for j, u in transports do
                if lowest == -1 or u.Distance < lowest then
                    lowest = u.Distance
                    value = u
                    key = j
                end
            end
            sortedList[k] = value
            -- Remove from unsorted table
            table.remove(transports, key)
        end

        -- Take transports as needed
        for i = 1, table.getn(sortedList) do
            if transportsNeeded and table.getn(sortedList[i].Unit:GetCargo()) < 1 and not sortedList[i].Unit:IsUnitState('TransportLoading') then
                local id = sortedList[i].Id
                aiBrain:AssignUnitsToPlatoon(platoon, {sortedList[i].Unit}, 'Scout', 'GrowthFormation')
                numTransports = numTransports + 1
                if not transSlotTable[id] then
                    transSlotTable[id] = GetNumTransportSlots(sortedList[i].Unit)
                end
                local tempSlots = {}
                tempSlots.Small = transSlotTable[id].Small
                tempSlots.Medium = transSlotTable[id].Medium
                tempSlots.Large = transSlotTable[id].Large
                -- Update number of slots needed
                while tempNeeded.Large > 0 and tempSlots.Large > 0 do
                    tempNeeded.Large = tempNeeded.Large - 1
                    tempSlots.Large = tempSlots.Large - 1
                    tempSlots.Medium = tempSlots.Medium - 2
                    tempSlots.Small = tempSlots.Small - 4
                end
                while tempNeeded.Medium > 0 and tempSlots.Medium > 0 do
                    tempNeeded.Medium = tempNeeded.Medium - 1
                    tempSlots.Medium = tempSlots.Medium - 1
                    tempSlots.Small = tempSlots.Small - 2
                end
                while tempNeeded.Small > 0 and tempSlots.Small > 0 do
                    tempNeeded.Small = tempNeeded.Small - 1
                    tempSlots.Small = tempSlots.Small - 1
                end
                if tempNeeded.Small <= 0 and tempNeeded.Medium <= 0 and tempNeeded.Large <= 0 then
                    transportsNeeded = false
                end
            end
        end
    end

    if transportsNeeded then
        ReturnTransportsToPool(platoon:GetSquadUnits('Scout'), false)
        return false, tempNeeded.Small, tempNeeded.Medium, tempNeeded.Large
    else
        platoon.UsingTransport = true
        return numTransports, 0, 0, 0
    end
end

---------------------------------------------
-- Utility Function
-- Get and load transports with platoon units
---------------------------------------------
function UseTransports(units, transports, location, transportPlatoon)
    local aiBrain
    for k, v in units do
        if not v.Dead then
            aiBrain = v:GetAIBrain()
            break
        end
    end

    if not aiBrain then
        return false
    end

    -- Load transports
    local transportTable = {}
    local transSlotTable = {}
    if not transports then
        return false
    end

    for num, unit in transports do
        local id = unit:GetUnitId()
        if not transSlotTable[id] then
            transSlotTable[id] = GetNumTransportSlots(unit)
        end
        table.insert(transportTable,
            {
                Transport = unit,
                LargeSlots = transSlotTable[id].Large,
                MediumSlots = transSlotTable[id].Medium,
                SmallSlots = transSlotTable[id].Small,
                Units = {}
            }
        )
    end

    local shields = {}
    local remainingSize3 = {}
    local remainingSize2 = {}
    local remainingSize1 = {}
    local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
    for num, unit in units do
        if not unit.Dead then
            if unit:IsUnitState('Attached') then
                aiBrain:AssignUnitsToPlatoon(pool, {unit}, 'Unassigned', 'None')
            elseif EntityCategoryContains(categories.url0306 + categories.DEFENSE, unit) then
                table.insert(shields, unit)
            elseif unit:GetBlueprint().Transport.TransportClass == 3 then
                table.insert(remainingSize3, unit)
            elseif unit:GetBlueprint().Transport.TransportClass == 2 then
                table.insert(remainingSize2, unit)
            elseif unit:GetBlueprint().Transport.TransportClass == 1 then
                table.insert(remainingSize1, unit)
            else
                table.insert(remainingSize1, unit)
            end
        end
    end

    local needed = GetNumTransports(units)
    local largeHave = 0
    for num, data in transportTable do
        largeHave = largeHave + data.LargeSlots
    end

    local leftoverUnits = {}
    local currLeftovers = {}
    local leftoverShields = {}
    transportTable, leftoverShields = SortUnitsOnTransports(transportTable, shields, largeHave - needed.Large)

    transportTable, leftoverUnits = SortUnitsOnTransports(transportTable, remainingSize3, -1)

    transportTable, currLeftovers = SortUnitsOnTransports(transportTable, leftoverShields, -1)

    for _, v in currLeftovers do table.insert(leftoverUnits, v) end
    transportTable, currLeftovers = SortUnitsOnTransports(transportTable, remainingSize2, -1)

    for _, v in currLeftovers do table.insert(leftoverUnits, v) end
    transportTable, currLeftovers = SortUnitsOnTransports(transportTable, remainingSize1, -1)

    for _, v in currLeftovers do table.insert(leftoverUnits, v) end
    transportTable, currLeftovers = SortUnitsOnTransports(transportTable, currLeftovers, -1)

    aiBrain:AssignUnitsToPlatoon(pool, currLeftovers, 'Unassigned', 'None')
    if transportPlatoon then
        transportPlatoon.UsingTransport = true
    end

    local monitorUnits = {}
    for num, data in transportTable do
        if table.getn(data.Units) > 0 then
            IssueClearCommands(data.Units)
            IssueTransportLoad(data.Units, data.Transport)
            for k, v in data.Units do table.insert(monitorUnits, v) end
        end
    end

    local attached = true
    repeat
        WaitSeconds(2)
        local allDead = true
        local transDead = true
        for k, v in units do
            if not v.Dead then
                allDead = false
                break
            end
        end
        for k, v in transports do
            if not v.Dead then
                transDead = false
                break
            end
        end
        if allDead or transDead then return false end
        attached = true
        for k, v in monitorUnits do
            if not v.Dead and not v:IsIdleState() then
                attached = false
                break
            end
        end
    until attached

    -- Any units that aren't transports and aren't attached send back to pool
    for k, unit in units do
        if not unit.Dead and not EntityCategoryContains(categories.TRANSPORTATION, unit) then
            if not unit:IsUnitState('Attached') then
                aiBrain:AssignUnitsToPlatoon(pool, {unit}, 'Unassigned', 'None')
            end
        elseif not unit.Dead and EntityCategoryContains(categories.TRANSPORTATION, unit) and table.getn(unit:GetCargo()) < 1 then
            ReturnTransportsToPool({unit}, true)
            table.remove(transports, k)
        end
    end

    -- If some transports have no units return to pool
    for k, t in transports do
        if not t.Dead and table.getn(t:GetCargo()) < 1 then
            aiBrain:AssignUnitsToPlatoon('ArmyPool', {t}, 'Scout', 'None')
            table.remove(transports, k)
        end
    end

    if table.getn(transports) ~= 0 then
        -- If no location then we have loaded transports then return true
        if location then
            local safePath = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, 'Air', transports[1]:GetPosition(), location, 200)
            if safePath then
                for _, p in safePath do
                    IssueMove(transports, p)
                end
            end
        else
            return true
        end
    else
        -- If no transports return false
        return false
    end

    IssueTransportUnload(transports, location)
    local attached = true
    while attached do
        WaitSeconds(2)
        local allDead = true
        for _, v in transports do
            if not v.Dead then
                allDead = false
                break
            end
        end

        if allDead then
            return false
        end

        attached = false
        for num, unit in units do
            if not unit.Dead and unit:IsUnitState('Attached') then
                attached = true
                break
            end
        end
    end

    if transportPlatoon then
        transportPlatoon.UsingTransport = false
    end
    ReturnTransportsToPool(transports, true)

    return true
end

---------------------------------------------------
-- Utility function
-- Sorts units onto transports distributing equally
---------------------------------------------------
function SortUnitsOnTransports(transportTable, unitTable, numSlots)
    local leftoverUnits = {}
    numSlots = numSlots or -1
    for num, unit in unitTable do
        if numSlots == -1 or num <= numSlots then
            local transSlotNum = 0
            local remainingLarge = 0
            local remainingMed = 0
            local remainingSml = 0
            for tNum, tData in transportTable do
                if tData.LargeSlots > remainingLarge then
                    transSlotNum = tNum
                    remainingLarge = tData.LargeSlots
                    remainingMed = tData.MediumSlots
                    remainingSml = tData.SmallSlots
                elseif tData.LargeSlots == remainingLarge and tData.MediumSlots > remainingMed then
                    transSlotNum = tNum
                    remainingLarge = tData.LargeSlots
                    remainingMed = tData.MediumSlots
                    remainingSml = tData.SmallSlots
                elseif tData.LargeSlots == remainingLarge and tData.MediumSlots == remainingMed and tData.SmallSlots > remainingSml then
                    transSlotNum = tNum
                    remainingLarge = tData.LargeSlots
                    remainingMed = tData.MediumSlots
                    remainingSml = tData.SmallSlots
                end
            end
            if transSlotNum > 0 then
                table.insert(transportTable[transSlotNum].Units, unit)
                if unit:GetBlueprint().Transport.TransportClass == 3 and remainingLarge >= 1 then
                    transportTable[transSlotNum].LargeSlots = transportTable[transSlotNum].LargeSlots - 1
                    transportTable[transSlotNum].MediumSlots = transportTable[transSlotNum].MediumSlots - 2
                    transportTable[transSlotNum].SmallSlots = transportTable[transSlotNum].SmallSlots - 4
                elseif unit:GetBlueprint().Transport.TransportClass == 2 and remainingMed > 0 then
                    if transportTable[transSlotNum].LargeSlots > 0 then
                        transportTable[transSlotNum].LargeSlots = transportTable[transSlotNum].LargeSlots - .5
                    end
                    transportTable[transSlotNum].MediumSlots = transportTable[transSlotNum].MediumSlots - 1
                    transportTable[transSlotNum].SmallSlots = transportTable[transSlotNum].SmallSlots - 2
                elseif unit:GetBlueprint().Transport.TransportClass == 1 and remainingSml > 0 then
                    transportTable[transSlotNum].SmallSlots = transportTable[transSlotNum].SmallSlots - 1
                elseif remainingSml > 0 then
                    transportTable[transSlotNum].SmallSlots = transportTable[transSlotNum].SmallSlots - 1
                else
                    table.insert(leftoverUnits, unit)
                end
            else
                table.insert(leftoverUnits, unit)
            end
        end
    end

    return transportTable, leftoverUnits
end

---------------------------------------------------------------------------------------
-- Utility Function
-- Takes transports in platoon, returns them to pool, flys them back to return location
---------------------------------------------------------------------------------------
function ReturnTransportsToPool(units, move)
    -- Put transports back in TPool
    local unit
    if not units then
        return false
    end

    for k, v in units do
        if not v.Dead then
            unit = v
            break
        end
    end

    if not unit then
        return false
    end

    local aiBrain = unit:GetAIBrain()
    local x, z = aiBrain:GetArmyStartPos()
    local position = RandomLocation(x, z)
    local safePath, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, 'Air', unit:GetPosition(), position, 200)
    for k, unit in units do
        if not unit.Dead and EntityCategoryContains(categories.TRANSPORTATION, unit) then
            aiBrain:AssignUnitsToPlatoon('ArmyPool', {unit}, 'Scout', 'None')
            if move then
                if safePath then
                    for _, p in safePath do
                        IssueMove({unit}, p)
                    end
                else
                    IssueMove({unit}, position)
                end
            end
        end
    end
end

--------------------------------------------------------------------------------------
-- Utility Function
-- Removes excess units from a platoon we want to transport
--------------------------------------------------------------------------------------
function SplitTransportOverflow(units, overflowSm, overflowMd, overflowLg)
    local leftovers = {}
    local goodUnits = {}
    local numUnits = table.getn(units)
    if numUnits == overflowSm+overflowMd+overflowLg then
        return goodUnits, units
    end
    for _, unit in units do
        if overflowSm + overflowMd+overflowLg > 0 then
            local transportClass = unit:GetBlueprint().Transport.TransportClass
            if transportClass == 2 and overflowMd > 0 then
                table.insert(leftovers, unit)
                overflowMd = overflowMd - 1
            elseif transportClass == 3 and overflowLg > 0 then
                table.insert(leftovers, unit)
                overflowLg = overflowLg - 1
            elseif overflowSm > 0 then
                table.insert(leftovers, unit)
                overflowSm = overflowSm - 1
            else
                table.insert(goodUnits, unit)
            end
        else
            table.insert(goodUnits, unit)
        end
    end

    return goodUnits, leftovers
end

-- Used by engineers to move to a safe location
function EngineerMoveWithSafePath(aiBrain, unit, destination)
    if not destination then
        return false
    end
    local pos = unit:GetPosition()
    local result, bestPos = unit:CanPathTo(destination)
    local bUsedTransports = false
    -- Increase check to 300 for transports
    if not result or VDist2Sq(pos[1], pos[3], destination[1], destination[3]) > 300 * 300
    and unit.PlatoonHandle and not EntityCategoryContains(categories.COMMAND, unit) then
        -- If we can't path to our destination, we need, rather than want, transports
        local needTransports = not result
        if VDist2Sq(pos[1], pos[3], destination[1], destination[3]) > 300 * 300 then
            needTransports = true
        end

        -- Skip the last move... we want to return and do a build
        bUsedTransports = AIAttackUtils.SendPlatoonWithTransportsNoCheck(aiBrain, unit.PlatoonHandle, destination, needTransports, true, false)

        if bUsedTransports then
            return true
        elseif VDist2Sq(pos[1], pos[3], destination[1], destination[3]) > 512 * 512 then
            -- If over 512 and no transports dont try and walk!
            return false
        end
    end

    -- If we're here, we haven't used transports and we can path to the destination
    if result then
        local path, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, 'Amphibious', pos, destination)
        if path then
            local pathSize = table.getn(path)
            -- Move to way points (but not to destination... leave that for the final command)
            for widx, waypointPath in path do
                if pathSize ~= widx then
                    IssueMove({unit}, waypointPath)
                end
            end
        end
        -- If there wasn't a *safe* path (but dest was pathable), then the last move would have been to go there directly
        -- so don't bother... the build/capture/reclaim command will take care of that after we return
        return true
    end
    return false
end


function EngineerTryReclaimCaptureArea(aiBrain, eng, pos)
    if not pos then
        return false
    end

    -- Check if enemy units are at location
    local checkUnits = aiBrain:GetUnitsAroundPoint(categories.STRUCTURE + (categories.MOBILE * categories.LAND), pos, 10, 'Enemy')

    if checkUnits and table.getn(checkUnits) > 0 then
        for num, unit in checkUnits do
            if not unit.Dead and EntityCategoryContains(categories.ENGINEER, unit) and (unit:GetAIBrain():GetFactionIndex() ~= aiBrain:GetFactionIndex()) then
                IssueReclaim({eng}, unit)
            elseif not EntityCategoryContains(categories.COMMAND, eng) then
                IssueCapture({eng}, unit)
            end
        end
        return true
    end

    return false
end


function EngineerTryRepair(aiBrain, eng, whatToBuild, pos)
    if not pos then
        return false
    end

    local structureCat = ParseEntityCategory(whatToBuild)
    local checkUnits = aiBrain:GetUnitsAroundPoint(structureCat, pos, 1, 'Ally')
    if checkUnits and table.getn(checkUnits) > 0 then
        for num, unit in checkUnits do
            IssueRepair({eng}, unit)
        end
        return true
    end

    return false
end

function GetThreatDistance(aiBrain, position, threatCutoff)
    local threatTable = aiBrain:GetThreatsAroundPosition(position, 16, true, 'StructuresNotMex')
    local closestHighThreat = false
    for k, v in threatTable do
        if v[3] > threatCutoff then
            local dist = VDist2(v[1], v[2], position[1], position[3])
            if not closestHighThreat or dist < closestHighThreat then
                closestHighThreat = dist
            end
        end
    end

    return closestHighThreat
end

-- Cheat Utilities
function SetupCheat(aiBrain, cheatBool)
    if cheatBool then
        aiBrain.CheatEnabled = true

        local buffDef = Buffs['CheatBuildRate']
        local buffAffects = buffDef.Affects
        buffAffects.BuildRate.Mult = tonumber(ScenarioInfo.Options.BuildMult)

        buffDef = Buffs['CheatIncome']
        buffAffects = buffDef.Affects
        buffAffects.EnergyProduction.Mult = tonumber(ScenarioInfo.Options.CheatMult)
        buffAffects.MassProduction.Mult = tonumber(ScenarioInfo.Options.CheatMult)

        local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
        for _, v in pool:GetPlatoonUnits() do
            -- Apply build rate and income buffs
            ApplyCheatBuffs(v)
        end

    end
end

function ApplyCheatBuffs(unit)
    if EntityCategoryContains(categories.COMMAND, unit) and ScenarioInfo.Options.OmniCheat == "on" then
        Buff.ApplyBuff(unit, 'IntelCheat')
    end
    Buff.ApplyBuff(unit, 'CheatIncome')
    Buff.ApplyBuff(unit, 'CheatBuildRate')
end

function EngineerTryReclaimCaptureAreaSorian(aiBrain, eng, pos)
    if not pos then
        return false
    end

    -- Check if enemy units are at location
    local checkCats = {categories.ENGINEER - categories.COMMAND, categories.STRUCTURE + (categories.MOBILE * categories.LAND - categories.ENGINEER - categories.COMMAND)}
    for k, v in checkCats do
        local checkUnits = aiBrain:GetUnitsAroundPoint(v, pos, 10, 'Enemy')
        for num, unit in checkUnits do
            if not unit.Dead and EntityCategoryContains(categories.ENGINEER, unit) then
                IssueCapture({eng}, unit)
                return true
            elseif not unit.Dead and not EntityCategoryContains(categories.ENGINEER, unit) then
                IssueReclaim({eng}, unit)
                return true
            end
        end
    end

    return false
end

function GetAssisteesSorian(aiBrain, locationType, assisteeType, buildingCategory, assisteeCategory)
    if assisteeType == 'Factory' then
        -- Sift through the factories in the location
        local manager = aiBrain.BuilderManagers[locationType].FactoryManager
        return manager:GetFactoriesWantingAssistance(buildingCategory, assisteeCategory)
    elseif assisteeType == 'Engineer' then
        local manager = aiBrain.BuilderManagers[locationType].EngineerManager
        return manager:GetEngineersWantingAssistance(buildingCategory, assisteeCategory)
    elseif assisteeType == 'Structure' then
        local manager = aiBrain.BuilderManagers[locationType].PlatoonFormManager
        return manager:GetUnitsBeingBuilt(buildingCategory, assisteeCategory)
    elseif assisteeType == 'NonUnitBuildingStructure' then
        return GetUnitsBeingBuilt(aiBrain, locationType, assisteeCategory)
    else
        WARN('*AI ERROR: Invalid assisteeType - ' .. assisteeType)
    end

    return false
end

function GetUnitsBeingBuilt(aiBrain, locationType, assisteeCategory)
    if not aiBrain or not locationType or not assisteeCategory then
        WARN('*AI ERROR: GetUnitsBeingBuilt missing data!')
        return false
    end

    local manager = aiBrain.BuilderManagers[locationType].EngineerManager
    if not manager then
        return false
    end

    local filterUnits = GetOwnUnitsAroundPoint(aiBrain, assisteeCategory, manager:GetLocationCoords(), manager:GetLocationRadius())
    local retUnits = {}
    for k, v in filterUnits do
        if v:IsUnitState('Building') or v:IsUnitState('Upgrading') then
            table.insert(retUnits, v)
        end
    end

    return retUnits
end

function GetBasePatrolPointsSorian(aiBrain, location, radius, layer)
    if type(location) == 'string' then
        if aiBrain:PBMHasPlatoonList() then
            for k, v in aiBrain.PBM.Locations do
                if v.LocationType == location then
                    radius = v.Radius
                    location = v.Location
                    break
                end
            end
        elseif aiBrain.BuilderManagers[location] then
            radius = aiBrain.BuilderManagers[location].FactoryManager:GetLocationRadius()
            location = aiBrain.BuilderManagers[location].FactoryManager:GetLocationCoords()
        end
        if not radius then
            error('*AI ERROR: Invalid locationType- '..location..' for army- '..aiBrain.Name, 2)
        end
    end
    if not location or not radius then
        error('*AI ERROR: Need location and radius or locationType for AIUtilities.GetBasePatrolPoints', 2)
    end

    if not layer then
        layer = 'Land'
    end

    local vecs = aiBrain:GetBaseVectors()
    local locList = {}
    for _, v in vecs do
        if LayerCheckPosition(v, layer) and VDist2(v[1], v[3], location[1], location[3]) < radius then
            table.insert(locList, v)
        end
    end
    local sortedList = {}
    local lastX = location[1]
    local lastZ = location[3]

    if table.getsize(locList) == 0 then return {} end

    local num = table.getsize(locList)
    local startX, startZ = aiBrain:GetArmyStartPos()
    local tempdistance = false
    local edistance
    local closeX, closeZ
    -- Sort the locations from point to closest point, that way it  makes a nice patrol path
    for _, v in ArmyBrains do
        if IsEnemy(v:GetArmyIndex(), aiBrain:GetArmyIndex()) then
            local estartX, estartZ = v:GetArmyStartPos()
            local tempdistance = VDist2(startX, startZ, estartX, estartZ)
            if not edistance or tempdistance < edistance then
                edistance = tempdistance
                closeX = estartX
                closeZ = estartZ
            end
        end
    end
    for i = 1, num do
        local lowest
        local czX, czZ, pos, distance, key
        for k, v in locList do
            local x = v[1]
            local z = v[3]
            if i == 1 then
                distance = VDist2(closeX, closeZ, x, z)
            else
                distance = VDist2(lastX, lastZ, x, z)
            end
            if not lowest or distance < lowest then
                pos = v
                lowest = distance
                key = k
            end
        end
        if not pos then return {} end
        sortedList[i] = pos
        lastX = pos[1]
        lastZ = pos[3]
        table.remove(locList, key)
    end

    return sortedList
end

function IsMex(building)
    return building == 'uab1103' or building == 'uab1202' or building == 'uab1302' or
    building == 'urb1103' or building == 'urb1202' or building == 'urb1302' or
    building == 'ueb1103' or building == 'ueb1202' or building == 'ueb1302' or
    building == 'xsb1103' or building == 'xsb1202' or building == 'xsb1302'
end

function AIGetSortedDefensiveLocationsFromLast(aiBrain, maxNum)
    local markerList = AIGetMarkerLocations(aiBrain, 'Defensive Point')
    return AISortMarkersFromLastPos(aiBrain, markerList, maxNum or 1000)
end

function AIGetSortedHydroLocations(aiBrain, maxNum, tMin, tMax, tRings, tType, position)
    local markerList = AIGetMarkerLocations(aiBrain, 'Hydrocarbon')
    local newList = {}
    for _, v in markerList do
        if aiBrain:CanBuildStructureAt('ueb1102', v.Position) then
            table.insert(newList, v)
        end
    end

    return AISortMarkersFromLastPos(aiBrain, newList, maxNum, tMin, tMax, tRings, tType, position)
end

-- used by engineers to move to a safe location
function EngineerMoveWithSafePathSorian(aiBrain, unit, destination)
    if not destination then
        return false
    end

    local result, bestPos = false
    result, bestPos = AIAttackUtils.CanGraphTo(unit, destination, 'Land')
    if not result then
        result, bestPos = AIAttackUtils.CanGraphTo(unit, destination, 'Amphibious')
        if not result and not SUtils.CheckForMapMarkers(aiBrain) then
            result, bestPos = unit:CanPathTo(destination)
        end
    end

    local pos = unit:GetPosition()
    local bUsedTransports = false
    if not result or VDist2Sq(pos[1], pos[3], destination[1], destination[3]) > 65536 and unit.PlatoonHandle and not EntityCategoryContains(categories.COMMAND, unit) then
        -- If we can't path to our destination, we need, rather than want, transports
        local needTransports = not result
        -- If distance > 512
        if VDist2Sq(pos[1], pos[3], destination[1], destination[3]) > 262144 then
            needTransports = true
        end
        -- Skip the last move... we want to return and do a build
        bUsedTransports = AIAttackUtils.SendPlatoonWithTransportsSorian(aiBrain, unit.PlatoonHandle, destination, needTransports, true, needTransports)

        if bUsedTransports then
            return true
        end
    end

    -- If we're here, we haven't used transports and we can path to the destination
    if result then
        local path, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, 'Amphibious', unit:GetPosition(), destination, 10)
        if path then
            local pathSize = table.getn(path)
            -- Move to way points (but not to destination... leave that for the final command)
            for widx, waypointPath in path do
                if pathSize ~= widx then
                    IssueMove({unit}, waypointPath)
                end
            end
        end
        -- If there wasn't a *safe* path (but dest was pathable), then the last move would have been to go there directly
        -- so don't bother... the build/capture/reclaim command will take care of that after we return
        return true
    end

    return false
end

function EngineerTryRepairSorian(aiBrain, eng, whatToBuild, pos)
    if not pos then
        return false
    end

    local checkRange = 75
    if IsMex(whatToBuild) then
        checkRange = 1
    end

    local structureCat = ParseEntityCategory(whatToBuild)
    local checkUnits = aiBrain:GetUnitsAroundPoint(structureCat, pos, checkRange, 'Ally')
    if checkUnits and table.getn(checkUnits) > 0 then
        for num, unit in checkUnits do
            if unit:IsBeingBuilt() then
                IssueRepair({eng}, unit)
                return true
            end
        end
    end

    return false
end

function AIFindPingTargetInRangeSorian(aiBrain, platoon, squad, maxRange, atkPri, avoidbases)
    local position = platoon:GetPlatoonPosition()
    if not aiBrain or not position or not maxRange then
        return false
    end

    local AttackPositions = AIGetAttackPointsAroundLocation(aiBrain, position, maxRange)
    for x, z in AttackPositions do
        local targetUnits = aiBrain:GetUnitsAroundPoint(categories.ALLUNITS, z, 100, 'Enemy')
        for _, v in atkPri do
            local category = ParseEntityCategory(v)
            local retUnit = false
            local distance = false
            local targetShields = 9999
            for num, unit in targetUnits do
                if not unit.Dead and EntityCategoryContains(category, unit) and platoon:CanAttackTarget(squad, unit) then
                    local unitPos = unit:GetPosition()
                    if avoidbases then
                        for _, w in ArmyBrains do
                            if IsAlly(w:GetArmyIndex(), aiBrain:GetArmyIndex()) or (aiBrain:GetArmyIndex() == w:GetArmyIndex()) then
                                local estartX, estartZ = w:GetArmyStartPos()
                                if VDist2Sq(estartX, estartZ, unitPos[1], unitPos[3]) < 22500 then
                                    continue
                                end
                            end
                        end
                    end
                    local numShields = aiBrain:GetNumUnitsAroundPoint(categories.DEFENSE * categories.SHIELD * categories.STRUCTURE, unitPos, 50, 'Enemy')
                    if not retUnit or numShields < targetShields or (numShields == targetShields and Utils.XZDistanceTwoVectors(position, unitPos) < distance) then
                        retUnit = unit
                        distance = Utils.XZDistanceTwoVectors(position, unitPos)
                        targetShields = numShields
                    end
                end
            end
            if retUnit and targetShields > 0 then
                local platoonUnits = platoon:GetPlatoonUnits()
                for _, w in platoonUnits do
                    if not w.Dead then
                        unit = w
                        break
                    end
                end
                local closestBlockingShield = AIBehaviors.GetClosestShieldProtectingTargetSorian(unit, retUnit)
                if closestBlockingShield then
                    return closestBlockingShield
                end
            end
            if retUnit then
                return retUnit
            end
        end
    end

    return false
end

function AIFindAirAttackTargetInRangeSorian(aiBrain, platoon, squad, atkPri, position)
    if not aiBrain or not position then
        return false
    end

    local targetUnits = aiBrain:GetUnitsAroundPoint(categories.ALLUNITS, position, 100, 'Enemy')
    for _, v in atkPri do
        local category = ParseEntityCategory(v)
        local retUnit = false
        local distance = false
        local targetShields = 9999
        for num, unit in targetUnits do
            if not unit.Dead and EntityCategoryContains(category, unit) and platoon:CanAttackTarget(squad, unit) then
                local unitPos = unit:GetPosition()
                local numShields = aiBrain:GetNumUnitsAroundPoint(categories.DEFENSE * categories.SHIELD * categories.STRUCTURE, unitPos, 50, 'Enemy')
                if not retUnit or numShields < targetShields or (numShields == targetShields and Utils.XZDistanceTwoVectors(position, unitPos) < distance) then
                    retUnit = unit
                    distance = Utils.XZDistanceTwoVectors(position, unitPos)
                    targetShields = numShields
                end
            end
        end
        if retUnit and targetShields > 0 then
            local platoonUnits = platoon:GetPlatoonUnits()
            for _, v in platoonUnits do
                if not v.Dead then
                    unit = v
                    break
                end
            end
            local closestBlockingShield = AIBehaviors.GetClosestShieldProtectingTargetSorian(unit, retUnit)
            if closestBlockingShield then
                return closestBlockingShield
            end
        end
        if retUnit then
            return retUnit
        end
    end

    return false
end

-- We use both Blank Marker that are army names as well as the new Large Expansion Area to determine big expansion bases
function AIFindStartLocationNeedsEngineerSorian(aiBrain, locationType, radius, tMin, tMax, tRings, tType, eng)
    local pos = aiBrain:PBMGetLocationCoords(locationType)
    if not pos then
        return false
    end

    local validStartPos = {}
    local validPos = AIGetMarkersAroundLocation(aiBrain, 'Large Expansion Area', pos, radius, tMin, tMax, tRings, tType)
    local positions = AIGetMarkersAroundLocation(aiBrain, 'Blank Marker', pos, radius, tMin, tMax, tRings, tType)
    local startX, startZ = aiBrain:GetArmyStartPos()
    for _, v in positions do
        if string.sub(v.Name, 1, 5) == 'ARMY_' then
            if startX ~= v.Position[1] and startZ ~= v.Position[3] then
                table.insert(validStartPos, v)
            end
        end
    end

    local retPos, retName
    if eng then
        if table.getn(validStartPos) > 0 then
            retPos, retName = AIFindMarkerNeedsEngineer(aiBrain, eng:GetPosition(), radius, tMin, tMax, tRings, tType, validStartPos)
        end
        if not retPos then
            retPos, retName = AIFindMarkerNeedsEngineer(aiBrain, eng:GetPosition(), radius, tMin, tMax, tRings, tType, validPos)
        end
    else
        if table.getn(validStartPos) > 0 then
            retPos, retName = AIFindMarkerNeedsEngineer(aiBrain, pos, radius, tMin, tMax, tRings, tType, validStartPos)
        end
        if not retPos then
            retPos, retName = AIFindMarkerNeedsEngineer(aiBrain, pos, radius, tMin, tMax, tRings, tType, validPos)
        end
    end

    return retPos, retName
end

function AIGetAttackPointsAroundLocation(aiBrain, pos, maxRange)
    local markerList = {}
    if aiBrain.AttackPoints then
        for k, v in aiBrain.AttackPoints do
            local dist = VDist2(pos[1], pos[3], v.Position[1], v.Position[3])
            if dist < maxRange then
                table.insert(markerList, {Position = v.Position})
            end
        end
    end

    return AISortMarkersFromStartPos(aiBrain, markerList, 100, nil, nil, nil, nil, nil, pos)
end

function AIFindBrainTargetInRangeSorian(aiBrain, platoon, squad, maxRange, atkPri, avoidbases)
    local position = platoon:GetPlatoonPosition()
    if not aiBrain or not position or not maxRange then
        return false
    end

    local targetUnits = aiBrain:GetUnitsAroundPoint(categories.ALLUNITS, position, maxRange, 'Enemy')
    for _, v in atkPri do
        local category = ParseEntityCategory(v)
        local retUnit = false
        local distance = false
        local targetShields = 9999
        for num, unit in targetUnits do
            if not unit.Dead and EntityCategoryContains(category, unit) and platoon:CanAttackTarget(squad, unit) then
                local unitPos = unit:GetPosition()
                if avoidbases then
                    for _, w in ArmyBrains do
                        if IsAlly(w:GetArmyIndex(), aiBrain:GetArmyIndex()) or (aiBrain:GetArmyIndex() == w:GetArmyIndex()) then
                            local estartX, estartZ = w:GetArmyStartPos()
                            if VDist2Sq(estartX, estartZ, unitPos[1], unitPos[3]) < 22500 then
                                continue
                            end
                        end
                    end
                end
                local numShields = aiBrain:GetNumUnitsAroundPoint(categories.DEFENSE * categories.SHIELD * categories.STRUCTURE, unitPos, 46, 'Enemy')
                if not retUnit or numShields < targetShields or (numShields == targetShields and Utils.XZDistanceTwoVectors(position, unitPos) < distance) then
                    retUnit = unit
                    distance = Utils.XZDistanceTwoVectors(position, unitPos)
                    targetShields = numShields
                end
            end
        end
        if retUnit and targetShields > 0 then
            local platoonUnits = platoon:GetPlatoonUnits()
            for _, w in platoonUnits do
                if not w.Dead then
                    unit = w
                    break
                end
            end
            local closestBlockingShield = AIBehaviors.GetClosestShieldProtectingTargetSorian(unit, retUnit)
            if closestBlockingShield then
                return closestBlockingShield
            end
        end
        if retUnit then
            return retUnit
        end
    end

    return false
end

function AIFindUndefendedBrainTargetInRangeSorian(aiBrain, platoon, squad, maxRange, atkPri)
    local position = platoon:GetPlatoonPosition()
    if not aiBrain or not position or not maxRange then
        return false
    end

    local numUnits = table.getn(platoon:GetPlatoonUnits())
    local maxShields = math.ceil(numUnits / 7)
    local targetUnits = aiBrain:GetUnitsAroundPoint(categories.ALLUNITS, position, maxRange, 'Enemy')
    for _, v in atkPri do
        local category = ParseEntityCategory(v)
        local retUnit = false
        local distance = false
        local targetShields = 9999
        for num, unit in targetUnits do
            if not unit.Dead and EntityCategoryContains(category, unit) and platoon:CanAttackTarget(squad, unit) then
                local unitPos = unit:GetPosition()
                local numShields = aiBrain:GetNumUnitsAroundPoint(categories.DEFENSE * categories.SHIELD * categories.STRUCTURE, unitPos, 46, 'Enemy')
                if numShields < maxShields and (not retUnit or numShields < targetShields or (numShields == targetShields and Utils.XZDistanceTwoVectors(position, unitPos) < distance)) then
                    retUnit = unit
                    distance = Utils.XZDistanceTwoVectors(position, unitPos)
                    targetShields = numShields
                end
            end
        end
        if retUnit and targetShields > 0 then
            local platoonUnits = platoon:GetPlatoonUnits()
            for _, w in platoonUnits do
                if not w.Dead then
                    unit = w
                    break
                end
            end
            local closestBlockingShield = AIBehaviors.GetClosestShieldProtectingTargetSorian(unit, retUnit)
            if closestBlockingShield then
                return closestBlockingShield
            end
        end
        if retUnit then
            return retUnit
        end
    end

    return false
end

function AIFindBrainNukeTargetInRangeSorian(aiBrain, platoon, maxRange, atkPri, nukeCount, oldTarget)
    local position = platoon:GetPosition()
    if not aiBrain or not position or not maxRange then
        return false
    end

    local massCost = 12000
    local targetUnits = aiBrain:GetUnitsAroundPoint(categories.ALLUNITS, position, maxRange, 'Enemy')
    for _, v in atkPri do
        local category = ParseEntityCategory(v)
        local retUnit = false
        local retPosition = false
        local retAntis = 0
        local distance = false
        for num, unit in targetUnits do
            if not unit.Dead and EntityCategoryContains(category, unit) then
                local unitPos = unit:GetPosition()
                local antiNukes = SUtils.NumberofUnitsBetweenPoints(aiBrain, position, unitPos, categories.ANTIMISSILE * categories.TECH3 * categories.STRUCTURE, 90, 'Enemy')
                if not SUtils.CheckCost(aiBrain, unitPos, massCost * antiNukes) then continue end
                local dupTarget = false
                for x, z in oldTarget do
                    if unit == z or (not z.Dead and Utils.XZDistanceTwoVectors(z:GetPosition(), unitPos) < 30) then
                        dupTarget = true
                    end
                end
                for _, w in ArmyBrains do
                    if IsAlly(w:GetArmyIndex(), aiBrain:GetArmyIndex()) or (aiBrain:GetArmyIndex() == w:GetArmyIndex()) then
                        local estartX, estartZ = w:GetArmyStartPos()
                        if VDist2(estartX, estartZ, unitPos[1], unitPos[3]) < 220 then
                            dupTarget = true
                        end
                    end
                end
                if (not retUnit or (distance and Utils.XZDistanceTwoVectors(position, unitPos) < distance)) and ((antiNukes + 2 < nukeCount or antiNukes == 0) and not dupTarget) then
                    retUnit = unit
                    retPosition = unitPos
                    retAntis = antiNukes
                    distance = Utils.XZDistanceTwoVectors(position, unitPos)
                elseif (not retUnit or (distance and Utils.XZDistanceTwoVectors(position, unitPos) < distance)) and not dupTarget then
                    for i = -1, 1 do
                        for j = -1, 1 do
                            if i ~= 0 and j ~= 0 then
                                local pos = {unitPos[1] + (i * 10), 0, unitPos[3] + (j * 10)}
                                antiNukes = SUtils.NumberofUnitsBetweenPoints(aiBrain, position, pos, categories.ANTIMISSILE * categories.TECH3 * categories.STRUCTURE, 90, 'Enemy')
                                if antiNukes + 2 < nukeCount or antiNukes == 0 then
                                    retUnit = unit
                                    retPosition = pos
                                    retAntis = antiNukes
                                    distance = Utils.XZDistanceTwoVectors(position, unitPos)
                                end
                            end
                            if retUnit then break end
                        end
                        if retUnit then break end
                    end
                end
            end
        end
        if retUnit then
            return retUnit, retPosition, retAntis
        end
    end

    return false
end

function GetOwnUnitsAroundPointSorian(aiBrain, category, location, radius, min, max, rings, tType, minRadius)
    local units = aiBrain:GetUnitsAroundPoint(category, location, radius, 'Ally')
    local index = aiBrain:GetArmyIndex()
    local minDist = minRadius * minRadius
    local retUnits = {}
    local checkThreat = false
    if min and max and rings then
        checkThreat = true
    end
    for _, v in units do
        if not v.Dead and not v:IsBeingBuilt() and v:GetAIBrain():GetArmyIndex() == index then
            local loc = v:GetPosition()
            if VDist2Sq(location[1], location[3], loc[1], loc[3]) > minDist then
                if checkThreat then
                    local threat = aiBrain:GetThreatAtPosition(v:GetPosition(), rings, true, tType or 'Overall')
                    if threat >= min and threat <= max then
                        table.insert(retUnits, v)
                    end
                else
                    table.insert(retUnits, v)
                end
            end
        end
    end

    return retUnits
end

function FindUnclutteredArea(aiBrain, category, location, radius, maxUnits, maxRadius, avoidCat)
    local units = aiBrain:GetUnitsAroundPoint(category, location, radius, 'Ally')
    local index = aiBrain:GetArmyIndex()
    local retUnits = {}
    for _, v in units do
        if not v.Dead and not v:IsBeingBuilt() and v:GetAIBrain():GetArmyIndex() == index then
            local nearby = aiBrain:GetNumUnitsAroundPoint(avoidCat, v:GetPosition(), maxRadius, 'Ally')
            if nearby < maxUnits then
                table.insert(retUnits, v)
            end
        end
    end

    return retUnits
end

function AIFindExpansionPointNeedsStructure(aiBrain, locationType, radius, category, markerRadius, unitMax, tMin, tMax, tRings, tType)
    local pos = aiBrain:PBMGetLocationCoords(locationType)
    if not pos then
        return false
    end

    local positions = AIGetMarkersAroundLocation(aiBrain, 'Expansion Area', pos, radius, tMin, tMax, tRings, tType)
    local retPos, retName, lowest
    for _, v in positions do
        local numUnits = table.getn(GetOwnUnitsAroundPoint(aiBrain, ParseEntityCategory(category), v.Position, markerRadius))
        if numUnits < unitMax then
            if not retPos or numUnits < lowest then
                lowest = numUnits
                retName = v.Name
                retPos = v.Position
            end
        end
    end

    return retPos, retName
end


function AIFindDefensiveAreaSorian(aiBrain, unit, category, range, runShield)
    if not unit.Dead then
        -- Build a grid to find units near
        local gridSize = range / 5
        if gridSize > 150 then
            gridSize = 150
        end

        local highPoint = false
        local highNum = false
        local unitPos = unit:GetPosition()
        local distance
        local startPosX, startPosZ = aiBrain:GetArmyStartPos()
        for i = -5, 5 do
            for j = -5, 5 do
                local height = GetTerrainHeight(unitPos[1] - (gridSize * i), unitPos[3] - (gridSize * j))
                if GetSurfaceHeight(unitPos[1] - (gridSize * i), unitPos[3] - (gridSize * j)) > height then
                    height = GetSurfaceHeight(unitPos[1] - (gridSize * i), unitPos[3] - (gridSize * j))
                end
                local checkPos = {unitPos[1] - (gridSize * i), height, unitPos[3] - (gridSize * j)}
                local units = aiBrain:GetUnitsAroundPoint(category, checkPos, gridSize, 'Ally')
                local tempNum = 0
                for k, v in units do
                    if (EntityCategoryContains(categories.TECH3, v) and not runShield) or (EntityCategoryContains(categories.TECH3, v) and runShield and v:ShieldIsOn()) then
                        tempNum = tempNum + 10
                    elseif (EntityCategoryContains(categories.TECH2, v) and not runShield) or (EntityCategoryContains(categories.TECH2, v) and runShield and v:ShieldIsOn()) then
                        tempNum = tempNum + 5
                    else
                        tempNum = tempNum + 1
                    end
                end
                local units = aiBrain:GetUnitsAroundPoint(categories.MOBILE, checkPos, gridSize, 'Enemy')
                for k, v in units do
                    if EntityCategoryContains(categories.TECH3, v) then
                        tempNum = tempNum - 10
                    elseif EntityCategoryContains(categories.TECH2, v) then
                        tempNum = tempNum - 5
                    else
                        tempNum = tempNum - 1
                    end
                end
                if not highNum or tempNum > highNum then
                    highNum = tempNum
                    distance = VDist2(startPosX, startPosZ, checkPos[1], checkPos[3])
                    highPoint = checkPos
                elseif tempNum == highNum then
                    local tempDist = VDist2(startPosX, startPosZ, checkPos[1], checkPos[3])
                    if tempDist < distance then
                        highNum = tempNum
                        highPoint = checkPos
                    end
                end
            end
        end
        if not highPoint then
            local x, z = aiBrain:GetArmyStartPos()
            return RandomLocation(x, z)
        else
            return highPoint
        end
    else
        return {0, 0, 0}
    end
end

function AIGetPingMarkersAroundLocation(aiBrain, threatMin, threatMax, threatRings, threatType)
    local returnMarkers = {}
    if aiBrain.TacticalBases then
        for k, v in aiBrain.TacticalBases do
            if not threatMin then
                table.insert(returnMarkers, v)
            else
                local threat = aiBrain:GetThreatAtPosition(v.Position, threatRings, true, threatType or 'Overall')
                if threat >= threatMin and threat <= threatMax then
                    table.insert(returnMarkers, v)
                end
            end
        end
    end

    return returnMarkers
end

function AIGetMarkerLocationsSorian(aiBrain, markerType)
    local markerList = {}
    if aiBrain.TacticalBases then
        for k, v in aiBrain.TacticalBases do
            table.insert(markerList, {Position = v.Position, Name = k})
        end
    end
    local markers = ScenarioUtils.GetMarkers()
    if markers then
        for k, v in markers do
            if v.type == markerType then
                table.insert(markerList, {Position = v.position, Name = k})
            end
        end
    end

    return markerList
end

function AIFindDefensivePointNeedsStructureSorian(aiBrain, locationType, radius, category, markerRadius, unitMax, tMin, tMax, tRings, tType)
    local pos = aiBrain:PBMGetLocationCoords(locationType)
    if not pos then
        return false
    end

    local primarkers = AIGetPingMarkersAroundLocation(aiBrain, tMin, tMax, tRings, tType)
    local positions = AIGetMarkersAroundLocation(aiBrain, 'Defensive Point', pos, radius, tMin, tMax, tRings, tType)
    local retPos, retName, lowest
    for _, v in primarkers do
        local numUnits = table.getn(GetOwnUnitsAroundPoint(aiBrain, ParseEntityCategory(category), v.Position, markerRadius))
        if numUnits < unitMax then
            if not retPos or numUnits < lowest then
                lowest = numUnits
                retName = v.Name
                retPos = v.Position
            end
        end
    end
    if retPos and retName then
        return retPos, retName
    end
    for _, v in positions do
        local numUnits = table.getn(GetOwnUnitsAroundPoint(aiBrain, ParseEntityCategory(category), v.Position, markerRadius))
        if numUnits < unitMax then
            if not retPos or numUnits < lowest then
                lowest = numUnits
                retName = v.Name
                retPos = v.Position
            end
        end
    end

    return retPos, retName
end

function AIFindFirebaseLocationSorian(aiBrain, locationType, radius, markerType, tMin, tMax, tRings, tType, maxUnits, unitCat, markerRadius)
    -- Get location of commander
    local estartX, estartZ = aiBrain:GetCurrentEnemy():GetArmyStartPos()
    local threatPos = {estartX, 0, estartZ}

    -- Get markers
    local markerList = AIGetMarkerLocationsSorian(aiBrain, markerType)

    -- For each marker, check against threatpos. Save markers that are within the FireBaseRange
    local inRangeList = {}
    for _, marker in markerList do
        local distSq = VDist2Sq(marker.Position[1], marker.Position[3], threatPos[1], threatPos[3])
        if distSq < radius * radius  then
            table.insert(inRangeList, marker)
        end
    end

    -- Pick the closest, least-threatening position in range
    local bestDistSq = 9999999999
    local bestThreat = 9999999999
    local bestMarker = false
    local maxThreat = tMax or 1
    local catCheck = ParseEntityCategory(unitCat) or categories.ALLUNITS
    local reference = false
    local refName = false
    for _, marker in inRangeList do
        local threat = aiBrain:GetThreatAtPosition(marker.Position, 1, true, 'AntiSurface')
        if threat < maxThreat then
            local numUnits = table.getn(GetOwnUnitsAroundPoint(aiBrain, catCheck, marker.Position, markerRadius or 20))
            if numUnits < maxUnits then
                if threat < bestThreat and threat < maxThreat then
                    bestDistSq = VDist2Sq(threatPos[1], threatPos[3], marker.Position[1], marker.Position[3])
                    bestThreat = threat
                    bestMarker = marker
                elseif threat == bestThreat then
                    local distSq = VDist2Sq(threatPos[1], threatPos[3], marker.Position[1], marker.Position[3])
                    if distSq > bestDistSq then
                        bestDistSq = distSq
                        bestMarker = marker
                    end
                end
            end
        end
    end
    if bestMarker then
        reference = bestMarker.Position
        refName = bestMarker.Name
    end

    return reference, refName
end

function UseTransportsGhetto(units, transports)
    local aiBrain
    for k, v in units do
        if not v.Dead then
            aiBrain = v:GetAIBrain()
            break
        end
    end

    if not aiBrain then
        return false
    end

    -- Load transports
    local transportTable = {}
    local transSlotTable = {}
    if not transports then
        return false
    end

    for num, unit in transports do
        local id = unit:GetUnitId()
        if not transSlotTable[id] then
            transSlotTable[id] = GetNumTransportSlots(unit)
        end
        table.insert(transportTable,
            {
                Transport = unit,
                LargeSlots = transSlotTable[id].Large,
                MediumSlots = transSlotTable[id].Medium,
                SmallSlots = transSlotTable[id].Small,
                Units = {}
            }
        )
    end

    local shields = {}
    local remainingSize3 = {}
    local remainingSize2 = {}
    local remainingSize1 = {}
    local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
    for num, unit in units do
        if not unit.Dead then
            if unit:IsUnitState('Attached') then
                aiBrain:AssignUnitsToPlatoon(pool, {unit}, 'Unassigned', 'None')
            elseif EntityCategoryContains(categories.url0306 + categories.DEFENSE, unit) then
                table.insert(shields, unit)
            elseif unit:GetBlueprint().Transport.TransportClass == 3 then
                table.insert(remainingSize3, unit)
            elseif unit:GetBlueprint().Transport.TransportClass == 2 then
                table.insert(remainingSize2, unit)
            elseif unit:GetBlueprint().Transport.TransportClass == 1 then
                table.insert(remainingSize1, unit)
            else
                table.insert(remainingSize1, unit)
            end
        end
    end

    local needed = GetNumTransports(units)
    local largeHave = 0
    for num, data in transportTable do
        largeHave = largeHave + data.LargeSlots
    end
    local leftoverUnits = {}
    local currLeftovers = {}
    local leftoverShields = {}
    transportTable, leftoverShields = SortUnitsOnTransports(transportTable, shields, largeHave - needed.Large)

    transportTable, leftoverUnits = SortUnitsOnTransports(transportTable, remainingSize3, -1)

    transportTable, currLeftovers = SortUnitsOnTransports(transportTable, leftoverShields, -1)

    for _, v in currLeftovers do table.insert(leftoverUnits, v) end
    transportTable, currLeftovers = SortUnitsOnTransports(transportTable, remainingSize2, -1)

    for _, v in currLeftovers do table.insert(leftoverUnits, v) end
    transportTable, currLeftovers = SortUnitsOnTransports(transportTable, remainingSize1, -1)

    for _, v in currLeftovers do table.insert(leftoverUnits, v) end
    transportTable, currLeftovers = SortUnitsOnTransports(transportTable, currLeftovers, -1)

    aiBrain:AssignUnitsToPlatoon(pool, currLeftovers, 'Unassigned', 'None')


    if transportPlatoon then
        transportPlatoon.UsingTransport = true
    end

    local monitorUnits = {}
    for num, data in transportTable do
        if table.getn(data.Units) > 0 then
            IssueClearCommands(data.Units)
            IssueTransportLoad(data.Units, data.Transport)
            for _, v in data.Units do table.insert(monitorUnits, v) end
        end
    end

    local attached = true
    repeat
        WaitSeconds(2)
        local allDead = true
        local transDead = true
        for _, v in units do
            if not v.Dead then
                allDead = false
                break
            end
        end
        for _, v in transports do
            if not v.Dead then
                transDead = false
                break
            end
        end
        if allDead or transDead then return false end
        attached = true
        for _, v in monitorUnits do
            if not v.Dead and not v:IsIdleState() then
                attached = false
                break
            end
        end
    until attached

    -- Any units that aren't transports and aren't attached send back to pool
    for k, unit in units do
        if not unit.Dead and not EntityCategoryContains(categories.TRANSPORTATION, unit) then
            if not unit:IsUnitState('Attached') then
                aiBrain:AssignUnitsToPlatoon(pool, {unit}, 'Unassigned', 'None')
            end
        elseif not unit.Dead and EntityCategoryContains(categories.TRANSPORTATION, unit) and table.getn(unit:GetCargo()) < 1 then
            ReturnTransportsToPool({unit}, true)
            table.remove(transports, k)
        end
    end

    -- Return empty transports to base
    for k, v in transports do
        if not v.Dead and EntityCategoryContains(categories.TRANSPORTATION, v) and table.getn(v:GetCargo()) < 1 then
            ReturnTransportsToPool({v}, true)
            table.remove(transports, k)
        end
    end

    return true
end

function AIFindFurthestMarkerNeedsEngineer(aiBrain, pos, radius, tMin, tMax, tRings, tType, positions)
   local closest = false
   local retPos, retName
   local positions = AIFilterAlliedBases(aiBrain, positions)
   for _, v in positions do
       if not aiBrain.BuilderManagers[v.Name] then
           if not closest or VDist3(pos, v.Position) > closest then
               closest = VDist3(pos, v.Position)
               retPos = v.Position
               retName = v.Name
           end
       else
           local managers = aiBrain.BuilderManagers[v.Name]
           if managers.EngineerManager:GetNumUnits('Engineers') == 0 and managers.FactoryManager:GetNumFactories() == 0 then
               if not closest or VDist3(pos, v.Position) > closest then
                   closest = VDist3(pos, v.Position)
                   retPos = v.Position
                   retName = v.Name
               end
           end
       end
   end

   return retPos, retName
end

-- We use both Blank Marker that are army names as well as the new Large Expansion Area to determine big expansion bases
function AIFindFurthestStartLocationNeedsEngineer(aiBrain, locationType, radius, tMin, tMax, tRings, tType, eng)
    local pos = aiBrain:PBMGetLocationCoords(locationType)
    if not pos then
        return false
    end

    local validPos = AIGetMarkersAroundLocation(aiBrain, 'Large Expansion Area', pos, radius, tMin, tMax, tRings, tType)
    local positions = AIGetMarkersAroundLocation(aiBrain, 'Blank Marker', pos, radius, tMin, tMax, tRings, tType)
    local startX, startZ = aiBrain:GetArmyStartPos()
    for _, v in positions do
        if string.sub(v.Name, 1, 5) == 'ARMY_' then
            if startX ~= v.Position[1] and startZ ~= v.Position[3] then
                table.insert(validPos, v)
            end
        end
    end

    local retPos, retName
    if eng then
        retPos, retName = AIFindFurthestMarkerNeedsEngineer(aiBrain, eng:GetPosition(), radius, tMin, tMax, tRings, tType, validPos)
    else
        retPos, retName = AIFindFurthestMarkerNeedsEngineer(aiBrain, pos, radius, tMin, tMax, tRings, tType, validPos)
    end

    return retPos, retName
end

function AIFindFurthestExpansionAreaNeedsEngineer(aiBrain, locationType, radius, tMin, tMax, tRings, tType, eng)
    local pos = aiBrain:PBMGetLocationCoords(locationType)
    if not pos then
        return false
    end

    local positions = AIGetMarkersAroundLocation(aiBrain, 'Expansion Area', pos, radius, tMin, tMax, tRings, tType)
    local retPos, retName
    if eng then
        retPos, retName = AIFindFurthestMarkerNeedsEngineer(aiBrain, eng:GetPosition(), radius, tMin, tMax, tRings, tType, positions)
    else
        retPos, retName = AIFindFurthestMarkerNeedsEngineer(aiBrain, pos, radius, tMin, tMax, tRings, tType, positions)
    end

    return retPos, retName
end
