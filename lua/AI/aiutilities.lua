----------------------------------------------------------------
-- File     :  /lua/AI/aiutilities.lua
-- Author(s): John Comes, Dru Staltman
-- Summary  :
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- --------------------------------------------------------------

local StructureTemplates = import("/lua/buildingtemplates.lua")
local UnitTemplates = import("/lua/unittemplates.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local Utils = import("/lua/utilities.lua")
local AIAttackUtils = import("/lua/ai/aiattackutilities.lua")
local Buff = import("/lua/sim/buff.lua")
local SUtils = import("/lua/ai/sorianutilities.lua")
local AIBehaviors = import("/lua/ai/aibehaviors.lua")

---@param aiBrain AIBrain
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
        econ.EnergyRequestOverTime = aiBrain.EconomyOverTimeCurrent.EnergyRequested
        econ.MassRequestOverTime = aiBrain.EconomyOverTimeCurrent.MassRequested
        econ.EnergyIncomeOverTime = aiBrain.EconomyOverTimeCurrent.EnergyIncome
        econ.MassIncomeOverTime = aiBrain.EconomyOverTimeCurrent.MassIncome
        econ.EnergyEfficiencyOverTime = aiBrain.EconomyOverTimeCurrent.EnergyEfficiencyOverTime
        econ.MassEfficiencyOverTime = aiBrain.EconomyOverTimeCurrent.MassEfficiencyOverTime
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

---@param aiBrain AIBrain
---@param structureType string
---@return UnitId
function AIGetStructureUnitId(aiBrain, structureType)
    local unitId
    for _, v in StructureTemplates.BuildingTemplates[aiBrain:GetFactionIndex()] do
        if v[1] == structureType then
            unitId = v[2]
            break
        end
    end

    return unitId
end

---@param aiBrain AIBrain
---@param unitType string
---@return UnitId
function AIGetMobileUnitId(aiBrain, unitType)
    local unitId
    for _, v in UnitTemplates.UnitTemplates[aiBrain:GetFactionIndex()] do
        if v[1] == unitType then
            unitId = v[2]
            break
        end
    end

    return unitId
end

---@param aiBrain AIBrain
---@return table
function AIGetStartLocations(aiBrain)
    local markerList = {}
    for i = 1, 16 do
        if Scenario.MasterChain._MASTERCHAIN_.Markers['ARMY_'..i] then
            table.insert(markerList, Scenario.MasterChain._MASTERCHAIN_.Markers['ARMY_'..i].position)
        end
    end

    return markerList
end

---@param aiBrain AIBrain
---@param maxNum number
---@return table
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
        local rand = Random(1, numMarkers + 1 - i)
        table.insert(retMarkers, markers[rand])
        table.remove(markers, rand)
    end

    return retMarkers
end

---@param aiBrain AIBrain
---@param maxNum number
---@return unknown
function AIGetSortedDefensiveLocations(aiBrain, maxNum)
    local markerList = AIGetMarkerLocations(aiBrain, 'Defensive Point')
    return AISortMarkersFromStartPos(aiBrain, markerList, maxNum or 1000)
end

---@param aiBrain AIBrain
---@param maxNum number
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@param position Vector
---@return unknown
function AIGetSortedMassLocations(aiBrain, maxNum, tMin, tMax, tRings, tType, position)
    local markerList = AIGetMarkerLocations(aiBrain, 'Mass')
    local newList = {}
    for _, v in markerList do
        -- check distance to map border. (game engine can't build mass closer then 8 mapunits to the map border.)
        if v.Position[1] <= 8 or v.Position[1] >= ScenarioInfo.size[1] - 8 or v.Position[3] <= 8 or v.Position[3] >= ScenarioInfo.size[2] - 8 then
            -- mass marker is too close to border, skip it.
            continue
        end
        if aiBrain:CanBuildStructureAt('ueb1103', v.Position) then
            table.insert(newList, v)
        end
    end
    return AISortMarkersFromLastPos(aiBrain, newList, maxNum, tMin, tMax, tRings, tType, position)
end

---@param aiBrain AIBrain
---@param maxNum number
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@param position Vector
---@return unknown
function AIGetSortedHydrocarbonLocation(aiBrain, maxNum, tMin, tMax, tRings, tType, position)
    local markerList = AIGetMarkerLocations(aiBrain, 'Hydrocarbon')
    return AISortMarkersFromLastPos(aiBrain, markerList, maxNum, tMin, tMax, tRings, tType, position)
end

---@param aiBrain AIBrain
---@param maxNum number
---@return unknown
function AIGetSortedNavalLocations(aiBrain, maxNum)
    local markerList = AIGetMarkerLocations(aiBrain, 'Naval Area')
    return AISortMarkersFromLastPos(aiBrain, markerList, maxNum or 1000)
end

--- Function sorts the points by which is closest to a defensive point
---@param aiBrain AIBrain
---@param points any
---@return table
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

---@param aiBrain AIBrain
---@param markerList any
---@param maxNumber number
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@param position Vector
---@return table
function AISortMarkersFromStartPos(aiBrain, markerList, maxNumber, tMin, tMax, tRings,_, tType, position)
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
    if table.empty(markerList) then return {} end

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

---@param aiBrain AIBrain
---@param markerList any
---@param maxNumber number
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@param position Vector
---@return table
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
    if table.empty(markerList) then return {} end

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

---@param aiBrain AIBrain
---@param markerType string
---@return table
function AIGetMarkerLocations(aiBrain, markerType)
    local markerList = {}
    if markerType == 'Start Location' then
        local tempMarkers = AIGetMarkerLocations(aiBrain, 'Spawn')
        for k, v in tempMarkers do
            if string.sub(v.Name, 1, 5) == 'ARMY_' then
                table.insert(markerList, {Position = v.Position, Name = v.Name})
            end
        end
    else
        local markers = import("/lua/sim/markerutilities.lua").GetMarkersByType(markerType)
        if markers then
            for k, v in markers do
                table.insert(markerList, {Position = v.position, Name = k})
            end
        end
    end

    return markerList
end

---@param aiBrain AIBrain
---@param markerType string
---@return table|unknown
function AIGetMarkerLocationsEx(aiBrain, markerType)
    local markerList = {}
    local markers = ScenarioUtils.GetMarkers()
    if markers then
        markerList = GenerateMarkerList(markerList,markers,markerType)
        LOG('AIGetMarkerLocationsEx '..table.getn(markerList)..' markers for '..markerType)
        -- If we have no Amphibious Path Nodes, generate them from Land and Water Nodes
        if markerType == 'Amphibious Path Node' and table.empty(markerList) then
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

---@param markerList string[]
---@param markers Marker[]
---@param markerType string
---@return any
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

---@param markerList string[]
---@param markers Marker[]
---@param markerType string
---@return any
function GenerateAmphibiousMarkerList(markerList,markers,markerType)
    for k, v in markers do
        local marker = table.copy(v)
        if marker.type == markerType then
            if marker.adjacentTo and marker.adjacentTo ~= '' then
                -- transform adjacentTo to Amphibious marker names
                local adjacentTo = ''
                for i, node in STR_GetTokens(marker.adjacentTo or '', ' ') do
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
    end
    return markerList
end

---@param aiBrain AIBrain
---@param markerType string
---@param pos Vector
---@param radius number
---@param threatMin number
---@param threatMax number
---@param threatRings number
---@param threatType string
---@return table
function AIGetMarkerPositionsAroundLocation(aiBrain, markerType, pos, radius, threatMin, threatMax, threatRings, threatType)
    local markers = AIGetMarkersAroundLocation(aiBrain, markerType, pos, radius, threatMin, threatMax, threatRings, threatType)
    local retMarkers = {}
    for _, v in markers do
        table.insert(markers, v.Position)
    end

    return retMarkers
end

---@param aiBrain AIBrain
---@param markerType string
---@param pos Vector
---@param radius number
---@param threatMin number
---@param threatMax number
---@param threatRings number
---@param threatType string
---@return table
function AIGetMarkersAroundLocation(aiBrain, markerType, pos, radius, threatMin, threatMax, threatRings, threatType)
    local markers = import("/lua/sim/markerutilities.lua").GetMarkersByType(markerType)
    local returnMarkers = {}
    for _, v in markers do
        local dist = VDist2(pos[1], pos[3], v.position[1], v.position[3])
        if dist < radius then
            if not threatMin then
                table.insert(returnMarkers, { Name = v.Name, Position = v.position })
            else
                local threat = aiBrain:GetThreatAtPosition(v.position, threatRings, true, threatType or 'Overall')
                if threat >= threatMin and threat <= threatMax then
                    table.insert(returnMarkers, { Name = v.Name, Position = v.position })
                end
            end
        end
    end

    return returnMarkers
end

---@param aiBrain AIBrain
---@param markerType string
---@param markerRadius number
---@param pos Vector
---@param posRad number
---@param unitCount number
---@param unitCat EntityCategory
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@return boolean
---@return boolean
function AIGetMarkerLeastUnits(aiBrain, markerType, markerRadius, pos, posRad, unitCount, unitCat, tMin, tMax, tRings, tType)
    local markers = {}
    if markerType == 'Start Location' then
        local tempMarkers = AIGetMarkersAroundLocation(aiBrain, 'Spawn', pos, posRad, tMin, tMax, tRings, tType)
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

--- Expansion functions - Finds bases needing expansion bases
---@param aiBrain AIBrain
---@param marker Marker
---@param threatRings number
---@param threatType string
---@return number
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

---@param aiBrain AIBrain
---@param positions table
---@return table
function AIFilterAlliedBases(aiBrain, positions)
    local retPositions = {}
    local armyIndex = aiBrain:GetArmyIndex()
    for _, v in positions do
        local allyPosition = false
        for index,brain in ArmyBrains do
            if brain.BrainType == 'AI' and IsAlly(brain:GetArmyIndex(), armyIndex) then
                if brain.BuilderManagers[v.Name]  or ( v.Position[1] == brain.BuilderManagers['MAIN'].Position[1] and v.Position[3] == brain.BuilderManagers['MAIN'].Position[3] ) then
                    allyPosition = true
                    break
                end
            end
        end
        if not allyPosition then
            local threat = GetAlliesThreat(aiBrain, v, 2, 'StructuresNotMex')
            if threat == 0 then
                table.insert(retPositions, v)
            end
        end
    end

    return retPositions
end

---@param aiBrain AIBrain
---@param pos Vector
---@param radius number
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@param positions table
---@return table
---@return string
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

--- We use both Blank Marker that are army names as well as the new Large Expansion Area to determine big expansion bases
---@param aiBrain AIBrain
---@param locationType string
---@param radius number
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@param eng Unit
---@return boolean
---@return string
function AIFindStartLocationNeedsEngineer(aiBrain, locationType, radius, tMin, tMax, tRings, tType, eng)
    local pos = aiBrain:PBMGetLocationCoords(locationType)
    if not pos then
        return false
    end

    local validPos = AIGetMarkersAroundLocation(aiBrain, 'Large Expansion Area', pos, radius, tMin, tMax, tRings, tType)

    local positions = AIGetMarkersAroundLocation(aiBrain, 'Spawn', pos, radius, tMin, tMax, tRings, tType)
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

---@param aiBrain AIBrain
---@param locationType string
---@param radius number
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@param eng Unit
---@return boolean
---@return string
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

---@param aiBrain AIBrain
---@param locationType string
---@param radius number
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@param eng Unit
---@return boolean
---@return string
function AIFindNavalAreaNeedsEngineer(aiBrain, locationType, radius, tMin, tMax, tRings, tType, eng)
    local pos = aiBrain:PBMGetLocationCoords(locationType)
    if not pos then
        return false
    end
    local positions = AIGetMarkersAroundLocation(aiBrain, 'Naval Area', pos, radius, tMin, tMax, tRings, tType)

    local closest
    local retPos, retName
    local positions = AIFilterAlliedBases(aiBrain, positions)
    for _, v in positions do
        local bx = pos[1] - v.Position[1]
        local bz = pos[3] - v.Position[3]
        local distance = bx * bx + bz * bz
        if not aiBrain.BuilderManagers[v.Name] then
            if not closest or distance < closest then
                closest = distance
                retPos = v.Position
                retName = v.Name
            end
        else
            local managers = aiBrain.BuilderManagers[v.Name]
            if managers.EngineerManager:GetNumUnits('Engineers') == 0 and managers.FactoryManager:GetNumFactories() == 0 then
                if not closest or distance < closest then
                    closest = distance
                    retPos = v.Position
                    retName = v.Name
                end
            end
        end
    end
    return retPos, retName
end

---@param aiBrain AIBrain
---@param locationType string
---@param radius number
---@param category string
---@param markerRadius number
---@param unitMax number
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@return boolean
---@return any
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

---@param aiBrain AIBrain
---@param locationType string
---@param radius number
---@param category string
---@param markerRadius number
---@param unitMax number
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@return boolean
---@return any
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

---@param aiBrain AIBrain
---@param locationType string
---@param radius number
---@param markerType MarkerType
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@param maxUnits number
---@param unitCat EntityCategory
---@param markerRadius number
---@return boolean
---@return boolean
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

---@param aiBrain AIBrain
---@param markerType MarkerType
---@param markerRadius number
---@param pos Vector
---@param posRad number
---@param unitCount number
---@param unitCat EntityCategory
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@return unknown
---@return boolean
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

---@param aiBrain AIBrain
---@param markerType MarkerType
---@param startX Vector
---@param startZ Vector
---@param extraTypes string
---@return unknown
---@return unknown
function AIGetClosestMarkerLocation(aiBrain, markerType, startX, startZ, extraTypes)
    local markerList = AIGetMarkerLocations(aiBrain, markerType)
    if extraTypes then
        for num, pType in extraTypes do
            local moreMarkers = AIGetMarkerLocations(aiBrain, pType)
            if not table.empty(moreMarkers) then
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

---@param aiBrain AIBrain
---@param markerType MarkerType
---@param startX Vector
---@param startZ Vector
---@param threatMin number
---@param threatMax number
---@param rings number
---@param threatType string
---@return unknown
---@return unknown
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

---@param aiBrain AIBrain
---@param unit Unit
---@param category string
---@param range number
---@return boolean|table
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

---@param aiBrain AIBrain
---@param radius number
---@param count number
---@param unitCategory EntityCategory
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@return unknown
function GetLocationNeedingWalls(aiBrain, radius, count, unitCategory, tMin, tMax, tRings, tType)
    local positions = {}
    if aiBrain.HasPlatoonList then
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

---@param aiBrain AIBrain
---@param locationType string
---@return boolean
function AIGetReclaimablesAroundLocation(aiBrain, locationType)
    local position, radius
    if aiBrain.HasPlatoonList then
        for _, v in aiBrain.PBM.Locations do
            if v.LocationType == locationType then
                position = v.Location
                radius = v.Radius
                break
            end
        end
    elseif aiBrain.BuilderManagers[locationType] then
        radius = aiBrain.BuilderManagers[locationType].FactoryManager.Radius
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

--- Assist Utility functions
---@param aiBrain AIBrain
---@param locationType string
---@param assisteeType string
---@param buildingCategory string
---@param assisteeCategory string
---@return unknown
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

--- Assist factories based on what factories have less units helping
---@param aiBrain AIBrain
---@param engineers Unit
---@param factories Unit
---@return boolean
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
---@param factory Unit
---@return table
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

---@param aiBrain AIBrain
---@param location Vector
---@param radius number
---@param layer Layer
---@return table
function GetBasePatrolPoints(aiBrain, location, radius, layer)
    if type(location) == 'string' then
        if aiBrain.HasPlatoonList then
            for k, v in aiBrain.PBM.Locations do
                if v.LocationType == location then
                    radius = v.Radius
                    location = v.Location
                    break
                end
            end
        elseif aiBrain.BuilderManagers[location] then
            radius = aiBrain.BuilderManagers[location].FactoryManager.Radius
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

    if table.empty(locList) then return {} end

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

---@param unit Unit
---@return table
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

---@param aiBrain AIBrain
---@param category string
---@param location Vector
---@param radius number
---@param min number
---@param max number
---@param rings number
---@param tType string
---@return table
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

---@param aiBrain AIBrain
---@param category string
---@param location Vector
---@param radius number
---@param tBrain string
---@return table
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

---@param pos Vector
---@param layer Layer
---@return boolean
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

---@param position Vector
---@return boolean
function GetNearestPathingPoint(position)
    if not position then
        return false
    end
    local x = math.floor(position[1] / 8)
    local z = math.floor(position[3] / 8)
    local retPos = {(x * 8) , 0,  (z * 8)}
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

---@param destPos Vector
---@param curlocation Vector
---@param unit Unit
---@return boolean
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

---@param point any
---@param posTable table
---@return boolean
function FindPointInTable(point, posTable)
    for _, v in posTable do
        if point[1] == v[1] and point[2] == v[2] and point[3] == v[3] then
            return true
        end
    end

    return false
end

---@param aiBrain AIBrain
---@param platoon Platoon
---@param squad PlatoonSquads
---@param maxRange number
---@param atkPri number
---@param enemyBrain AIBrain
---@return boolean
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

---@param aiBrain AIBrain
---@param position Vector
---@param maxRange number
---@param category string
---@return boolean
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

---@param x number
---@param z number
---@return table
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

---@param aiBrain AIBrain
---@return table
function FindIdleGates(aiBrain)
    local gates = aiBrain:GetListOfUnits(categories.GATE, true)
    if gates and not table.empty(gates) then
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

--- Utility Function
--- Returns the number of slots the transport has available
---@param unit Unit
---@return table
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


--- Utility Function
--- Returns the number of transports required to move the platoon
---@param units Unit[]
---@return table
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

--- Utility Function
--- Function that gets the correct number of transports for a platoon
---@param platoon Platoon
---@param units Unit[]|nil
---@return number
---@return number
---@return number
---@return number
function GetTransports(platoon, units)
    if not units then
        units = platoon:GetPlatoonUnits()
    end

    -- Check for empty platoon
    if table.empty(units) then
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
        location = units[1]:GetPosition()
    end

    if not location then
        return 0
    end

    -- Determine distance of transports from platoon
    local transports = {}
    for _, unit in pool:GetPlatoonUnits() do
        if not unit.Dead and EntityCategoryContains(categories.TRANSPORTATION - categories.uea0203, unit) and not unit:IsUnitState('Busy') and not unit:IsUnitState('TransportLoading') and table.empty(unit:GetCargo()) and unit:GetFractionComplete() == 1 then
            local unitPos = unit:GetPosition()
            local curr = {Unit = unit, Distance = VDist2(unitPos[1], unitPos[3], location[1], location[3]),
                           Id = unit.UnitId}
            table.insert(transports, curr)
        end
    end

    local numTransports = 0
    local transSlotTable = {}
    if not table.empty(transports) then
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
            if transportsNeeded and table.empty(sortedList[i].Unit:GetCargo()) and not sortedList[i].Unit:IsUnitState('TransportLoading') then
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

--- Utility Function
--- Get and load transports with platoon units
---@param units Unit[]
---@param transports AirUnit[]
---@param location Vector
---@param transportPlatoon Platoon
---@return boolean
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

    IssueClearCommands(transports)

    for num, unit in transports do
        local id = unit.UnitId
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
        if not table.empty(data.Units) then
            IssueClearCommands(data.Units)
            IssueTransportLoad(data.Units, data.Transport)
            for k, v in data.Units do table.insert(monitorUnits, v) end
        end
    end

    local attached = true
    repeat
        coroutine.yield(20)
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
        elseif not unit.Dead and EntityCategoryContains(categories.TRANSPORTATION, unit) and table.empty(unit:GetCargo()) then
            ReturnTransportsToPool({unit}, true)
            table.remove(transports, k)
        end
    end

    -- If some transports have no units return to pool
    for k, t in transports do
        if not t.Dead and table.empty(t:GetCargo()) then
            aiBrain:AssignUnitsToPlatoon('ArmyPool', {t}, 'Scout', 'None')
            table.remove(transports, k)
        end
    end

    if not table.empty(transports) then
        -- If no location then we have loaded transports then return true
        if location then
            -- Adding Surface Height, so the transporter get not confused, because the target is under the map (reduces unload time)
            location = {location[1], GetSurfaceHeight(location[1],location[3]), location[3]}
            local safePath = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, 'Air', transports[1]:GetPosition(), location, 200)
            if safePath then
                for _, p in safePath do
                    IssueMove(transports, p)
                end
                IssueMove(transports, location)
                IssueTransportUnload(transports, location)
            else
                IssueMove(transports, location)
                IssueTransportUnload(transports, location)
            end
        else
            return true
        end
    else
        -- If no transports return false
        return false
    end

    local attached = true
    while attached do
        coroutine.yield(20)
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

--- Utility function
--- Sorts units onto transports distributing equally
---@param transportTable table
---@param unitTable table
---@param numSlots number
---@return any
---@return table
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

--- Utility Function
--- Takes transports in platoon, returns them to pool, flys them back to return location
---@param units Unit[]
---@param move any
---@return boolean
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
                        IssueToUnitMove(unit, p)
                    end
                else
                    IssueToUnitMove(unit, position)
                end
            end
        end
    end
end

--- Utility Function
--- Removes excess units from a platoon we want to transport
---@param units Unit[]
---@param overflowSm any
---@param overflowMd any
---@param overflowLg any
---@return table
---@return any
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

--- Used by engineers to move to a safe location
---@param aiBrain AIBrain
---@param unit Unit
---@param destination Vector
---@return boolean
function EngineerMoveWithSafePath(aiBrain, unit, destination)
    if not destination then
        return false
    end
    local NavUtils = import("/lua/sim/navutils.lua")
    local TransportUtils = import("/lua/ai/transportutilities.lua")
    local pos = unit:GetPosition()
    -- don't check a path if we are in build range
    if VDist2(pos[1], pos[3], destination[1], destination[3]) < 14 then
        return true
    end
    local result = NavUtils.CanPathTo('Amphibious', pos, destination)
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
        -- needTransports need to fix this
        bUsedTransports = TransportUtils.SendPlatoonWithTransports(aiBrain, unit.PlatoonHandle, destination, 3, true)
        if bUsedTransports then
            return true
        elseif VDist2Sq(pos[1], pos[3], destination[1], destination[3]) > 512 * 512 then
            -- If over 512 and no transports dont try and walk!
            return false
        end
    end

    -- If we're here, we haven't used transports and we can path to the destination
    if result then
        local path, reason = NavUtils.PathToWithThreatThreshold('Amphibious', pos, destination, aiBrain, NavUtils.ThreatFunctions.AntiSurface, 200, aiBrain.IMAPConfig.Rings)
        if path then
            local pathSize = table.getn(path)
            -- Move to way points (but not to destination... leave that for the final command)
            for widx, waypointPath in path do
                if pathSize ~= widx then
                    IssueToUnitMove(unit, waypointPath)
                end
            end
        end
        -- If there wasn't a *safe* path (but dest was pathable), then the last move would have been to go there directly
        -- so don't bother... the build/capture/reclaim command will take care of that after we return
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param eng Unit
---@param pos Vector
---@return boolean
function EngineerTryReclaimCaptureArea(aiBrain, eng, pos)
    if not pos then
        return false
    end
    local Reclaiming = false
    -- Check if enemy units are at location
    local checkUnits = aiBrain:GetUnitsAroundPoint( (categories.STRUCTURE + categories.MOBILE) - categories.AIR, pos, 10, 'Enemy')
    -- reclaim units near our building place.
    if checkUnits and not table.empty(checkUnits) then
        for num, unit in checkUnits do
            if unit.Dead or unit:BeenDestroyed() then
                continue
            end
            if not IsEnemy( aiBrain:GetArmyIndex(), unit:GetAIBrain():GetArmyIndex() ) then
                continue
            end
            if unit:IsCapturable() then
                -- if we can capture the unit/building then do so
                unit.CaptureInProgress = true
                IssueCapture({eng}, unit)
            else
                -- if we can't capture then reclaim
                unit.ReclaimInProgress = true
                IssueReclaim({eng}, unit)
            end
            Reclaiming = true
        end
    end
    -- reclaim rocks etc or we can't build mexes or hydros
    local Reclaimables = GetReclaimablesInRect(Rect(pos[1], pos[3], pos[1], pos[3]))
    if Reclaimables and not table.empty( Reclaimables ) then
        for k,v in Reclaimables do
            if v.MaxMassReclaim > 0 or v.MaxEnergyReclaim > 0 then
                IssueReclaim({eng}, v)
                Reclaiming = true
            end
        end
    end
    return Reclaiming
end

---@param aiBrain AIBrain
---@param eng Unit
---@param whatToBuild any
---@param pos Vector
---@return boolean
function EngineerTryRepair(aiBrain, eng, whatToBuild, pos)
    if not pos then
        return false
    end

    local structureCat = ParseEntityCategory(whatToBuild)
    local checkUnits = aiBrain:GetUnitsAroundPoint(structureCat, pos, 1, 'Ally')
    if checkUnits and not table.empty(checkUnits) then
        for num, unit in checkUnits do
            IssueRepair({eng}, unit)
        end
        return true
    end

    return false
end

---@param aiBrain AIBrain
---@param position Vector
---@param threatCutoff number
---@return boolean|number
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

--------------------
-- Cheat Utilities
--------------------

---@param aiBrain AIBrain
---@param cheatBool boolean
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

---@param unit Unit
function ApplyCheatBuffs(unit)
    if EntityCategoryContains(categories.COMMAND, unit) and ScenarioInfo.Options.OmniCheat == "on" then
        Buff.ApplyBuff(unit, 'IntelCheat')
    end
    Buff.ApplyBuff(unit, 'CheatIncome')
    Buff.ApplyBuff(unit, 'CheatBuildRate')
end

---@param aiBrain AIBrain
---@param locationType string
---@param assisteeCategory string
---@return boolean
function GetUnitsBeingBuilt(aiBrain, locationType, assisteeCategory)
    if not aiBrain or not locationType or not assisteeCategory then
        WARN('*AI ERROR: GetUnitsBeingBuilt missing data!')
        return false
    end

    local manager = aiBrain.BuilderManagers[locationType].EngineerManager
    if not manager then
        return false
    end

    local filterUnits = GetOwnUnitsAroundPoint(aiBrain, assisteeCategory, manager:GetLocationCoords(), manager.Radius)
    local retUnits = {}
    for k, v in filterUnits do
        if v:IsUnitState('Building') or v:IsUnitState('Upgrading') then
            table.insert(retUnits, v)
        end
    end

    return retUnits
end

---@param building boolean
---@return boolean
function IsMex(building)
    return building == 'uab1103' or building == 'uab1202' or building == 'uab1302' or
    building == 'urb1103' or building == 'urb1202' or building == 'urb1302' or
    building == 'ueb1103' or building == 'ueb1202' or building == 'ueb1302' or
    building == 'xsb1103' or building == 'xsb1202' or building == 'xsb1302'
end

---@param aiBrain AIBrain
---@param maxNum number
---@return table
function AIGetSortedDefensiveLocationsFromLast(aiBrain, maxNum)
    local markerList = AIGetMarkerLocations(aiBrain, 'Defensive Point')
    return AISortMarkersFromLastPos(aiBrain, markerList, maxNum or 1000)
end

---@param aiBrain AIBrain
---@param maxNum number
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@param position Vector
---@return table
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

---@param aiBrain AIBrain
---@param platoon Platoon
---@param squad string
---@param atkPri number
---@param position Vector
---@return boolean
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
            local unit
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

---@param aiBrain AIBrain
---@param pos Vector
---@param maxRange number
---@return table
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

---@param aiBrain AIBrain
---@param platoon Platoon
---@param squad string
---@param maxRange number
---@param atkPri number
---@param avoidbases any
---@return boolean
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
            local unit
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

---@param aiBrain AIBrain
---@param platoon Platoon
---@param squad string
---@param maxRange number
---@param atkPri number
---@return boolean
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
            local unit
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

---@param aiBrain AIBrain
---@param platoon Platoon
---@param maxRange number
---@param atkPri number
---@param nukeCount number
---@param oldTarget any
---@return boolean
---@return boolean|table|unknown
---@return integer
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

---@param aiBrain AIBrain
---@param category string
---@param location Vector
---@param radius number
---@param min number
---@param max number
---@param rings number
---@param tType string
---@param minRadius number
---@return table
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

---@param aiBrain AIBrain
---@param category string
---@param location Vector
---@param radius number
---@param maxUnits number
---@param maxRadius number
---@param avoidCat string
---@return table
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

---@param aiBrain AIBrain
---@param locationType string
---@param radius number
---@param category string
---@param markerRadius number
---@param unitMax number
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@return boolean
---@return unknown
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

---@param aiBrain AIBrain
---@param unit Unit
---@param category string
---@param range number
---@param runShield boolean
---@return table
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

---@param aiBrain AIBrain
---@param threatMin number
---@param threatMax number
---@param threatRings number
---@param threatType string
---@return table
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

---@param aiBrain AIBrain
---@param markerType MarkerType
---@return table
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

---@param aiBrain AIBrain
---@param locationType string
---@param radius number
---@param category string
---@param markerRadius number
---@param unitMax number
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType number
---@return boolean
---@return unknown
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

---@param aiBrain AIBrain
---@param locationType string
---@param radius number
---@param markerType MarkerType
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@param maxUnits number
---@param unitCat EntityCategory
---@param markerRadius number
---@return boolean
---@return boolean
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

---@param units Unit
---@param transports AirTransport
---@return boolean
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
        local id = unit.UnitId
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
        if not table.empty(data.Units) then
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
        elseif not unit.Dead and EntityCategoryContains(categories.TRANSPORTATION, unit) and table.empty(unit:GetCargo()) then
            ReturnTransportsToPool({unit}, true)
            table.remove(transports, k)
        end
    end

    -- Return empty transports to base
    for k, v in transports do
        if not v.Dead and EntityCategoryContains(categories.TRANSPORTATION, v) and table.empty(v:GetCargo()) then
            ReturnTransportsToPool({v}, true)
            table.remove(transports, k)
        end
    end

    return true
end

---@param aiBrain AIBrain
---@param pos Vector
---@param radius number
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@param positions Vector
---@return unknown
---@return unknown
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

--- We use both Blank Marker that are army names as well as the new Large Expansion Area to determine big expansion bases
---@param aiBrain AIBrain
---@param locationType string
---@param radius number
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@param eng Unit
---@return boolean
---@return unknown
function AIFindFurthestStartLocationNeedsEngineer(aiBrain, locationType, radius, tMin, tMax, tRings, tType, eng)
    local pos = aiBrain:PBMGetLocationCoords(locationType)
    if not pos then
        return false
    end

    local validPos = AIGetMarkersAroundLocation(aiBrain, 'Large Expansion Area', pos, radius, tMin, tMax, tRings, tType)
    local positions = AIGetMarkersAroundLocation(aiBrain, 'Spawn', pos, radius, tMin, tMax, tRings, tType)
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

---@param aiBrain AIBrain
---@param locationType string
---@param radius number
---@param tMin number
---@param tMax number
---@param tRings number
---@param tType string
---@param eng Unit
---@return boolean
---@return unknown
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

---@param pos1 table
---@param pos2 table
---@param dist number
---@param reverse boolean
---@return table
function ShiftPosition(pos1, pos2, dist, reverse)
    --This function will lerp a position in two ways
    --By default it will shift from pos2 to pos1 at the specified distance    
    --if the reverse bool is set it will go in the oposite direction e.g towards/away
    --It is multipurpose, used for simple vector3 lerps and enemy avoidence logic
    if not pos1 or not pos2 then
        WARN('*AI WARNING: ShiftPosition missing positions')
    end
    local delta
    if reverse then
        delta = VDiff(pos1,pos2)
    else
        delta = VDiff(pos2,pos1)
    end
    local norm = math.max(VDist2(delta[1],delta[3],0,0),1)
    local x = pos1[1]+dist*delta[1]/norm
    local z = pos1[3]+dist*delta[3]/norm
    x = math.min(ScenarioInfo.size[1]-5,math.max(5,x))
    z = math.min(ScenarioInfo.size[2]-5,math.max(5,z))
    return {x,GetSurfaceHeight(x,z),z}
end

---@param aiBrain AIBrain
---@param eng unit
---@return boolean
function EngAvoidLocalDanger(aiBrain, eng)
    local engPos = eng:GetPosition()
    local enemyUnits = aiBrain:GetUnitsAroundPoint(categories.LAND * categories.MOBILE, engPos, 45, 'Enemy')
    local action = false
    for _, unit in enemyUnits do
        local enemyUnitPos = unit:GetPosition()
        if EntityCategoryContains(categories.SCOUT + categories.ENGINEER * (categories.TECH1 + categories.TECH2) - categories.COMMAND, unit) then
            if VDist2Sq(engPos[1], engPos[3], enemyUnitPos[1], enemyUnitPos[3]) < 144 then
                if unit and not IsDestroyed(unit) and unit:GetFractionComplete() == 1 then
                    if VDist2Sq(engPos[1], engPos[3], enemyUnitPos[1], enemyUnitPos[3]) < 156 then
                        IssueToUnitClearCommands(eng)
                        IssueReclaim({eng}, unit)
                        action = true
                        break
                    end
                end
            end
        elseif EntityCategoryContains(categories.LAND * categories.MOBILE - categories.SCOUT, unit) then
            if VDist2Sq(engPos[1], engPos[3], enemyUnitPos[1], enemyUnitPos[3]) < 81 then
                if unit and not IsDestroyed(unit) and unit:GetFractionComplete() == 1 then
                    if VDist2Sq(engPos[1], engPos[3], enemyUnitPos[1], enemyUnitPos[3]) < 156 then
                        IssueToUnitClearCommands(eng)
                        IssueReclaim({eng}, unit)
                        action = true
                        break
                    end
                end
            else
                IssueToUnitClearCommands(eng)
                IssueToUnitMove(eng, ShiftPosition(enemyUnitPos, engPos, 50, false))
                coroutine.yield(60)
                action = true
            end
        end
    end
    return action
end

---@param aiBrain AIBrain
---@param eng Unit
---@return boolean
function EngLocalExtractorBuild(aiBrain, eng)
    -- Will get an engineer to build a mass extractor on nearby mass markers
    -- if the marker is too close to the border then it will use IssueBuildMobile to avoid issues
    -- requires the engineer to not have the default EngineerBuildAI OnUnitBuilt callback set
    local action = false
    local bool,markers=CanBuildOnLocalMassPoints(aiBrain, eng:GetPosition(), 25)
    if bool then
        IssueToUnitClearCommands(eng)
        local factionIndex = aiBrain:GetFactionIndex()
        local buildingTmplFile = import('/lua/BuildingTemplates.lua')
        local buildingTmpl = buildingTmplFile[('BuildingTemplates')][factionIndex]
        local whatToBuild = aiBrain:DecideWhatToBuild(eng, 'T1Resource', buildingTmpl)
        for _,massMarker in markers do
            EngineerTryReclaimCaptureArea(aiBrain, eng, massMarker.Position, 2)
            EngineerTryRepair(aiBrain, eng, whatToBuild, massMarker.Position)
            if massMarker.BorderWarning then
                IssueBuildMobile({eng}, massMarker.Position, whatToBuild, {})
                action = true
            else
                aiBrain:BuildStructure(eng, whatToBuild, {massMarker.Position[1], massMarker.Position[3], 0}, false)
                action = true
            end
        end
        while eng and not eng.Dead and (0<table.getn(eng:GetCommandQueue()) or eng:IsUnitState('Building') or eng:IsUnitState("Moving")) do
            coroutine.yield(20)
        end
        return action
    end
end

---@param aiBrain AIBrain
---@param engPos table
---@param distance number
---@return boolean
---@return table
function CanBuildOnLocalMassPoints(aiBrain, engPos, distance)
    -- Checks if an engineer can build on mass points close to its location
    -- will return a bool if it found anything and if it did then a table of mass markers
    -- the BorderWarning is used to tell the AI that the mass marker is too close to the map border
    local pointDistance = distance * distance
    local massMarkers = import("/lua/sim/markerutilities.lua").GetMarkersByType('Mass')
    local NavUtils = import("/lua/sim/navutils.lua")
    local validMassMarkers = {}
    for _, v in massMarkers do
        if v.type == 'Mass' then
            local massBorderWarn = false
            if v.position[1] <= 8 or v.position[1] >= ScenarioInfo.size[1] - 8 or v.position[3] <= 8 or v.position[3] >= ScenarioInfo.size[2] - 8 then
                massBorderWarn = true
            end 
            local mexDistance = VDist2Sq( v.position[1],v.position[3], engPos[1], engPos[3] )
            if mexDistance < pointDistance and aiBrain:CanBuildStructureAt('ueb1103', v.position) and NavUtils.CanPathTo('Amphibious', engPos, v.position) then
                table.insert(validMassMarkers, {Position = v.position, Distance = mexDistance , MassSpot = v, BorderWarning = massBorderWarn})
            end
        end
    end
    table.sort(validMassMarkers, function(a,b) return a.Distance < b.Distance end)
    if table.getn(validMassMarkers) > 0 then
        return true, validMassMarkers
    else
        return false
    end
end

---@param aiBrain AIBrain
---@param engPos table
---@param distance number
---@return boolean
---@return table
function CanBuildOnGridMassPoints(aiBrain, engPos, distance, layer)
    -- Checks if an engineer can build on mass points close to its location
    -- will return a bool if it found anything and if it did then a table of mass markers
    -- the BorderWarning is used to tell the AI that the mass marker is too close to the map border
    local pointDistance = distance * distance
    local depositsGrid = aiBrain.GridDeposits
    if not depositsGrid then
        WARN('GridDeposits class is not setup for AI')
        return
    end
    local massMarkers = depositsGrid:GetResourcesWithinDistance('Mass', engPos, distance, layer)
    local NavUtils = import("/lua/sim/navutils.lua")
    local validMassMarkers = {}
    for _, v in massMarkers do
        if v.type == 'Mass' then
            local massBorderWarn = false
            if v.position[1] <= 8 or v.position[1] >= ScenarioInfo.size[1] - 8 or v.position[3] <= 8 or v.position[3] >= ScenarioInfo.size[2] - 8 then
                massBorderWarn = true
            end 
            local mexDistance = VDist2Sq( v.position[1],v.position[3], engPos[1], engPos[3] )
            if mexDistance < pointDistance and aiBrain:CanBuildStructureAt('ueb1103', v.position) and NavUtils.CanPathTo('Amphibious', engPos, v.position) then
                table.insert(validMassMarkers, {Position = v.position, Distance = mexDistance , MassSpot = v, BorderWarning = massBorderWarn})
            end
        end
    end
    table.sort(validMassMarkers, function(a,b) return a.Distance < b.Distance end)
    if table.getn(validMassMarkers) > 0 then
        return true, validMassMarkers
    else
        return false
    end
end

---@param eng Unit
---@param minimumReclaim number
---@return boolean
function EngPerformReclaim(eng, minimumReclaim)
    -- Will get an engineer to search within its reclaim range for any close reclaim 
    -- and issue reclaim commands if it is above the minimumReclaim requires the
    -- engineer to not have the EngineerBuildAi OnReclaimed callback set also requires
    -- the delay for reclaim time when the return is true
    -- Could be improved with a OnStartReclaim callback utilized
    local engPos = eng:GetPosition()
    local rectDef = Rect(engPos[1] - 10, engPos[3] - 10, engPos[1] + 10, engPos[3] + 10)
    local reclaimRect = GetReclaimablesInRect(rectDef)
    local maxReclaimCount = 0
    local action = false
    if reclaimRect then
        local closeReclaim = {}
        for _, v in reclaimRect do
            if not IsProp(v) then continue end
            if v.MaxMassReclaim and v.MaxMassReclaim > minimumReclaim then
                if VDist2Sq(engPos[1],engPos[3], v.CachePosition[1], v.CachePosition[3]) <= 100 then
                    table.insert(closeReclaim, v)
                    maxReclaimCount = maxReclaimCount + 1
                end
            end
            if maxReclaimCount > 10 then
                break
            end
        end
        if table.getn(closeReclaim) > 0 then
            IssueToUnitClearCommands(eng)
            for _, rec in closeReclaim do
                IssueReclaim({eng}, rec)
            end
            action = true
        end
    end
    return action
end

---@param aiBrain AIBrain
---@param eng Unit
---@param movementLayer string
---@return number
---@return number
function EngFindReclaimCell(aiBrain, eng, movementLayer, searchType)
    -- Will find a reclaim grid cell to target for reclaim engineers
    -- requires the GridReclaim and GridBrain to have an instance against the 
    -- AI Brain, movementLayer is included for mods that have different layer engineers
    -- searchRadius could be improved to be dynamic
        -----------------------------------
    -- find a nearby cell to reclaim --

    -- @Relent0r this uses the newly introduced API to find nearby cells. Short descriptions:
    -- `MaximumInRadius`            Finds most valuable cell to reclaim in a radius
    -- `FilterInRadius`             Finds all cells that meets some threshold
    -- `FilterAndSortInRadius`      Finds all cells that meets some threshold and sorts the list of cells from high value to low value
    local CanPathTo = import("/lua/sim/navutils.lua").CanPathTo
    local reclaimGridInstance = aiBrain.GridReclaim
    local brainGridInstance = aiBrain.GridBrain
    local maxmapdimension = math.max(ScenarioInfo.size[1],ScenarioInfo.size[2])
    local searchRadius = 16
    if maxmapdimension == 256 then
        searchRadius = 8
    end
    if searchType == 'MAIN' then
        searchRadius = aiBrain.IMAPConfig.Rings
    end
    local searchLoop = 0
    local reclaimTargetX, reclaimTargetZ
    local engPos = eng:GetPosition()
    local gx, gz = reclaimGridInstance:ToGridSpace(engPos[1],engPos[3])
    while searchLoop < searchRadius and (not (reclaimTargetX and reclaimTargetZ)) do 
        WaitTicks(1)

        -- retrieve a list of cells with some mass value
        local cells, count = reclaimGridInstance:FilterAndSortInRadius(gx, gz, searchRadius, 10)
        -- find out if we can path to the center of the cell and check engineer maximums
        for k = 1, count do
            local cell = cells[k] --[[@as AIGridReclaimCell]]
            local centerOfCell = reclaimGridInstance:ToWorldSpace(cell.X, cell.Z)
            local maxEngineers = math.min(math.ceil(cell.TotalMass / 500), 8)
            -- make sure we can path to it and it doesnt have high threat e.g Point Defense
            if CanPathTo(movementLayer, engPos, centerOfCell) and aiBrain:GetThreatAtPosition(centerOfCell, 0, true, 'AntiSurface') < 10 then
                local brainCell = brainGridInstance:ToCellFromGridSpace(cell.X, cell.Z)
                local engineersInCell = brainGridInstance:CountReclaimingEngineers(brainCell)
                if engineersInCell < maxEngineers then
                    reclaimTargetX, reclaimTargetZ = cell.X, cell.Z
                    break
                end
            end
        end
        searchLoop = searchLoop + 1
    end
    if reclaimTargetX and reclaimTargetZ then
        return reclaimTargetX, reclaimTargetZ
    end
end

function GetBuildLocation(aiBrain, buildingTemplate, baseTemplate, buildUnit, eng, adjacent, category, radius, relative)
    -- This will get a build location based on the parameters
    -- Will take into account any adjacency request
    -- Note: borderWarning (too close to map border) will be returned, make sure your build functions can support it
    local buildLocation = false
    local borderWarning = false
    local whatToBuild = aiBrain:DecideWhatToBuild(eng, buildUnit, buildingTemplate)
    local engPos = eng:GetPosition()
    local playableArea = ScenarioInfo.PlayableArea or {0, 0, ScenarioInfo.size[1], ScenarioInfo.size[2]}
    local function normalposition(vec)
        return {vec[1],GetTerrainHeight(vec[1],vec[2]),vec[2]}
    end
    local function heightbuildpos(vec)
        return {vec[1],vec[2],0}
    end
    
    if adjacent then
        local unitSize = aiBrain:GetUnitBlueprint(whatToBuild).Physics
        local testUnits  = aiBrain:GetUnitsAroundPoint(category, engPos, radius, 'Ally')
        local index = aiBrain:GetArmyIndex()
        local closeUnits = {}
        for _, v in testUnits do
            if not v.Dead and not v:IsBeingBuilt() and v:GetAIBrain():GetArmyIndex() == index then
                table.insert(closeUnits, v)
            end
        end
        local template = {}
        table.insert(template, {})
        table.insert(template[1], { buildUnit })
        for _,unit in closeUnits do
            local targetSize = unit:GetBlueprint().Physics
            local targetPos = unit:GetPosition()
            local differenceX=math.abs(targetSize.SkirtSizeX-unitSize.SkirtSizeX)
            local offsetX=math.floor(differenceX/2)
            local differenceZ=math.abs(targetSize.SkirtSizeZ-unitSize.SkirtSizeZ)
            local offsetZ=math.floor(differenceZ/2)
            local offsetfactory=0
            if EntityCategoryContains(categories.FACTORY, unit) and (buildUnit=='T1LandFactory' or buildUnit=='T1AirFactory' or buildUnit=='T2SupportLandFactory' or buildUnit=='T3SupportLandFactory') then
                offsetfactory=2
            end
            -- Top/bottom of unit
            for i=-offsetX,offsetX do
                local testPos = { targetPos[1] + (i * 1), targetPos[3]-targetSize.SkirtSizeZ/2-(unitSize.SkirtSizeZ/2)-offsetfactory, 0 }
                local testPos2 = { targetPos[1] + (i * 1), targetPos[3]+targetSize.SkirtSizeZ/2+(unitSize.SkirtSizeZ/2)+offsetfactory, 0 }
                -- check if the buildplace is to close to the border or inside buildable area
                if testPos[1] > 8 and testPos[1] < ScenarioInfo.size[1] - 8 and testPos[2] > 8 and testPos[2] < ScenarioInfo.size[2] - 8 then
                    if aiBrain:CanBuildStructureAt(whatToBuild, normalposition(testPos)) and VDist3Sq(engPos,normalposition(testPos)) < radius * radius then
                        return heightbuildpos(testPos), whatToBuild
                    end
                end
                if testPos2[1] > 8 and testPos2[1] < ScenarioInfo.size[1] - 8 and testPos2[2] > 8 and testPos2[2] < ScenarioInfo.size[2] - 8 then
                    if aiBrain:CanBuildStructureAt(whatToBuild, normalposition(testPos2)) then
                        if aiBrain:CanBuildStructureAt(whatToBuild, normalposition(testPos2)) and VDist3Sq(engPos,normalposition(testPos2)) < radius * radius then
                            return heightbuildpos(testPos2), whatToBuild
                        end
                    end
                end
            end
            -- Sides of unit
            for i=-offsetZ,offsetZ do
                local testPos = { targetPos[1]-targetSize.SkirtSizeX/2-(unitSize.SkirtSizeX/2)-offsetfactory, targetPos[3] + (i * 1), 0 }
                local testPos2 = { targetPos[1]+targetSize.SkirtSizeX/2+(unitSize.SkirtSizeX/2)+offsetfactory, targetPos[3] + (i * 1), 0 }
                if testPos[1] > 8 and testPos[1] < ScenarioInfo.size[1] - 8 and testPos[2] > 8 and testPos[2] < ScenarioInfo.size[2] - 8 then
                    if aiBrain:CanBuildStructureAt(whatToBuild, normalposition(testPos)) and VDist3Sq(engPos,normalposition(testPos)) < radius * radius then
                        return heightbuildpos(testPos), whatToBuild
                    end
                end
                if testPos2[1] > 8 and testPos2[1] < ScenarioInfo.size[1] - 8 and testPos2[2] > 8 and testPos2[2] < ScenarioInfo.size[2] - 8 then
                    if aiBrain:CanBuildStructureAt(whatToBuild, normalposition(testPos2)) then
                        if aiBrain:CanBuildStructureAt(whatToBuild, normalposition(testPos2)) and VDist3Sq(engPos,normalposition(testPos2)) < radius * radius then
                            return heightbuildpos(testPos2), whatToBuild
                        end
                    end
                end
            end
        end
    else
        local location = aiBrain:FindPlaceToBuild(buildUnit, whatToBuild, baseTemplate, relative, eng, nil, engPos[1], engPos[3])
        if location and relative then
            local relativeLoc = {location[1] + engPos[1], location[3] + engPos[3], 0}
            if relativeLoc[1] - playableArea[1] <= 8 or relativeLoc[1] >= playableArea[3] - 8 or relativeLoc[2] - playableArea[2] <= 8 or relativeLoc[2] >= playableArea[4] - 8 then
                borderWarning = true
            end
            return relativeLoc, whatToBuild, borderWarning
        else
            return location, whatToBuild, borderWarning
        end
    end
    return false
end

function GetResourceMarkerWithinRadius(aiBrain, pos, markerType, radius, canBuild, maxThreat, threatType)
    local markers = import("/lua/sim/markerutilities.lua").GetMarkersByType(markerType)
    local markerTable = {}
    local radiusLimit = radius * radius
    local structureID
    if markerType == 'Hydrocarbon' then
        structureID = 'ueb1102'
    elseif markerType == 'Mass' then
        structureID = 'ueb1103'
    else
        WARN('*AI: Warning invalid markerType passed to function GetResourceMarkerWithinRadious')
        return
    end
    for k, v in markers do
        if v.type == markerType then
            table.insert(markerTable, {Position = v.position, Name = k, Distance = VDist2Sq(pos[1], pos[3], v.position[1], v.position[3])})
        end
    end
    table.sort(markerTable, function(a,b) return a.Distance < b.Distance end)
    for _, v in markerTable do
        if v.Distance <= radiusLimit then
            if canBuild then
                if aiBrain:CanBuildStructureAt(structureID, v.Position) then
                    if maxThreat and threatType then
                        if aiBrain:GetThreatAtPosition(v.Position, aiBrain.IMAPConfig.Rings, true, threatType) < maxThreat then
                            return v
                        end
                    else
                        return v
                    end
                end
            else
                return v
            end
            
        end
    end
    return false
end

MergeWithNearbyStatePlatoons = function(platoon, stateMachine, radius, maxMergeNumber, ignoreBase)
    -- check to see we're not near an ally base
    -- ignoreBase is not worded well, if false then ignore if too close to base
    if IsDestroyed(platoon) then
        return
    end
    local aiBrain = platoon:GetBrain()
    if not aiBrain then
        return
    end

    if platoon.UsingTransport then
        return
    end
    local platUnits = platoon:GetPlatoonUnits()
    local platCount = 0

    for _, u in platUnits do
        if not u.Dead then
            platCount = platCount + 1
        end
    end

    if (maxMergeNumber and platCount > maxMergeNumber) or platCount < 1 then
        return
    end 

    local platPos = platoon:GetPlatoonPosition()
    if not platPos then
        return
    end

    local radiusSq = radius*radius
    -- if we're too close to a base, forget it
    if not ignoreBase then
        if aiBrain.BuilderManagers then
            for baseName, base in aiBrain.BuilderManagers do
                if VDist2Sq(platPos[1], platPos[3], base.Position[1], base.Position[3]) <= (2*radiusSq) then
                    --RNGLOG('Platoon too close to base, not merge happening')
                    return
                end
            end
        end
    end

    local AlliedPlatoons = aiBrain:GetPlatoonsList()
    local bMergedPlatoons = false
    for _,aPlat in AlliedPlatoons do
        if aPlat.PlatoonName ~= stateMachine then
            continue
        end
        if aPlat == platoon then
            continue
        end

        if aPlat.UsingTransport then
            continue
        end

        if aPlat.PlatoonFull then
            --RNGLOG('Remote platoon is full, skip')
            continue
        end

        local allyPlatPos = aPlat:GetPlatoonPosition()
        if not allyPlatPos or not aiBrain:PlatoonExists(aPlat) then
            continue
        end

        if not platoon.MovementLayer then
            platoon:GetNavigationalLayer()
        end
        if not aPlat.MovementLayer then
            aPlat:GetNavigationalLayer()
        end

        -- make sure we're the same movement layer type to avoid hamstringing air of amphibious
        if platoon.MovementLayer ~= aPlat.MovementLayer then
            continue
        end

        if  VDist2Sq(platPos[1], platPos[3], allyPlatPos[1], allyPlatPos[3]) <= radiusSq then
            local units = aPlat:GetPlatoonUnits()
            local validUnits = {}
            local bValidUnits = false
            for _,u in units do
                if not u.Dead and not u:IsUnitState('Attached') then
                    table.insert(validUnits, u)
                    bValidUnits = true
                end
            end
            if bValidUnits then
                --LOG("*AI DEBUG: Merging platoons " .. platoon.BuilderName .. ": (" .. platPos[1] .. ", " .. platPos[3] .. ") and " .. aPlat.BuilderName .. ": (" .. allyPlatPos[1] .. ", " .. allyPlatPos[3] .. ")")
                aiBrain:AssignUnitsToPlatoon(platoon, validUnits, 'Attack', 'GrowthFormation')
                bMergedPlatoons = true
            end
        end
    end
    if bMergedPlatoons then
        local platUnits = platoon:GetPlatoonUnits()
        IssueClearCommands(platUnits)
    end
    return bMergedPlatoons
end
