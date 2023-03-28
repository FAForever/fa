----------------------------------------------------------------------------
--
--  File     :  /lua/MiscBuildConditions.lua
--  Author(s): Dru Staltman, John Comes
--
--  Summary  : Generic AI Platoon Build Conditions
--             Build conditions always return true or false
--
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------

local AIUtils = import("/lua/ai/aiutilities.lua")


---@param aiBrain AIBrain unused
---@return boolean
function True(aiBrain)
    return true
end

---@param aiBrain AIBrain unused
---@return boolean
function False(aiBrain)
    return false
end

---@param aiBrain AIBrain unused
---@param higherThan number
---@param lowerThan number
---@param minNumber number
---@param maxNumber number
---@return true | nil
function RandomNumber(aiBrain, higherThan, lowerThan, minNumber, maxNumber)
    local num = Random(minNumber, maxNumber)
    if higherThan < num and lowerThan > num then
        return true
    end
end

---@param aiBrain AIBrain
---@param layerPref string
---@return true | nil
function IsAIBrainLayerPref(aiBrain, layerPref)
    if layerPref == aiBrain.LayerPref then
        return true
    end
end

---@param aiBrain AIBrain unused
---@param num number
---@return true | nil
function MissionNumber(aiBrain, num)
    local missionNumber = ScenarioInfo.MissionNumber
    if missionNumber and missionNumber == num then
        return true
    end
end

---@param aiBrain AIBrain unused
---@param num number
---@return true | nil
function MissionNumberGreaterOrEqual(aiBrain, num)
    local missionNumber = ScenarioInfo.MissionNumber
    if missionNumber and missionNumber >= num then
        return true
    end
end

---@param aiBrain AIBrain unused
---@param num number
---@return true | nil
function MissionNumberLessOrEqual(aiBrain, num)
    local missionNumber = ScenarioInfo.MissionNumber
    if missionNumber and missionNumber <= num then
        return true
    end
end

---@param aiBrain AIBrain unused
---@param varName string
---@return true | nil
function CheckScenarioInfoVarTable(aiBrain, varName)
    if ScenarioInfo.VarTable[varName] then
        return true
    end
end

---@param aiBrain AIBrain unused
---@param varName string
---@return boolean
function CheckScenarioInfoVarTableFalse(aiBrain, varName)
    return not ScenarioInfo.VarTable[varName]
end

---@param aiBrain AIBrain unused
---@param diffLevel number
---@return true | nil
function DifficultyEqual(aiBrain, diffLevel)
    local difficulty = ScenarioInfo.Options.Difficulty
    if difficulty and difficulty == diffLevel then
        return true
    end
end

---@param aiBrain AIBrain unused
---@param diffLevel number
---@return true | nil
function DifficultyGreaterOrEqual(aiBrain, diffLevel)
    local difficulty = ScenarioInfo.Options.Difficulty
    if difficulty and difficulty >= diffLevel then
        return true
    end
end

---@param aiBrain AIBrain unused
---@param diffLevel number
---@return true | nil
function DifficultyLessOrEqual(aiBrain, diffLevel)
    local difficulty = ScenarioInfo.Options.Difficulty
    if difficulty and difficulty <= diffLevel then
        return true
    end
end

---@param aiBrain AIBrain unused
---@param chainName string
---@return true | nil
function MarkerChainExists(aiBrain, chainName)
    if Scenario.Chains[chainName] then
        return true
    end
end

---@param aiBrain AIBrain
---@param ... number[]
---@return true | nil
function FactionIndex(aiBrain, ...)
    local factionIndex = aiBrain:GetFactionIndex()
    for index = 1, arg.n do
        if arg[index] == factionIndex then
            return true
        end
    end
end

---@param aiBrain AIBrain
---@param locType string
---@return true | nil
function ReclaimablesInArea(aiBrain, locType)
    if aiBrain:GetEconomyStoredRatio("MASS") <= 0.7 then
        local reclaim = AIUtils.AIGetReclaimablesAroundLocation(aiBrain, locType)
        if reclaim and next(reclaim) then -- `reclaim` is non-empty
            return true
        end
    end
end

---@param aiBrain AIBrain
---@param locType string
---@return true | nil
function CheckAvailableGates(aiBrain, locType)
    local pos, rad
    if aiBrain.HasPlatoonList then
        for _, loc in aiBrain.PBM.Locations do
            if loc.LocationType == locType then
                pos = loc.Location
                rad = loc.Radius
                break
            end
        end
    else
        local builderManager = aiBrain.BuilderManagers[locType]
        if builderManager then
            local factoryManager = builderManager.FactoryManager
            pos = factoryManager:GetLocationCoords()
            rad = factoryManager.Radius
        end
    end
    if pos then
        local gates = GetOwnUnitsAroundPoint(aiBrain, categories.GATE, pos, rad)
        if gates then
            for _, unit in gates do
                if not unit:IsUnitState("TransportLoading") then
                    return true
                end
            end
        end
    end
end

---@param aiBrain AIBrain
---@param num number
---@return boolean
function GreaterThanMapWaterRatio(aiBrain, num)
    return aiBrain:GetMapWaterRatio() > num
end

---@param aiBrain AIBrain
---@param num number
---@return boolean
function LessThanMapWaterRatio(aiBrain, num)
    return aiBrain:GetMapWaterRatio() < num
end

---@param aiBrain AIBrain
---@return true | nil
function ArmyNeedsTransports(aiBrain)
    if aiBrain then
        local needTransports = aiBrain.NeedTransports
        if needTransports and needTransports > 0 and aiBrain:GetNoRushTicks() <= 0 then
            return true
        end
    end
end

---@param aiBrain AIBrain
---@param number number
---@return true | nil
function TransportNeedGreater(aiBrain, number)
    if aiBrain then
        local needTransports = aiBrain.NeedTransports
        if needTransports and needTransports > number and aiBrain:GetNoRushTicks() <= 0 then
            return true
        end
    end
end

---@param aiBrain AIBrain
---@return true | nil
function ArmyWantsTransports(aiBrain)
    if aiBrain and aiBrain.WantTransports and aiBrain:GetNoRushTicks() <= 0 then
        return true
    end
end

---@param aiBrain AIBrain
---@return true | nil
function CDRRunningAway(aiBrain)
    for _, unit in aiBrain:GetListOfUnits(categories.COMMAND, false) do
        if not unit.Dead and unit.Running then
            return true
        end
    end
end

---@param aiBrain AIBrain
---@param num number
---@return true | nil
function GreaterThanGameTime(aiBrain, num)
    local time = GetGameTimeSeconds()
    if aiBrain.CheatEnabled then
        time = time * 2
    end
    if num < time then
        return true
    end
end

---@param aiBrain AIBrain
---@param num number
---@return boolean
function LessThanGameTime(aiBrain, num)
    return not GreaterThanGameTime(aiBrain, num)
end

---@param aiBrain AIBrain
---@return true | nil
function PreBuiltBase(aiBrain)
    if aiBrain.PreBuilt then
        return true
    end
end

---@param aiBrain AIBrain
---@return boolean
function NotPreBuilt(aiBrain)
    return not aiBrain.PreBuilt
end

---@param aiBrain AIBrain unused
---@param mapname string
---@param check boolean
---@return boolean
function MapCheck(aiBrain, mapname, check)
    if ScenarioInfo.name == mapname then
        return check
    end
    return not check
end

---@param aiBrain AIBrain
---@param check boolean
---@return true | nil
function IsIsland(aiBrain, check)
    if not aiBrain.islandCheck then
        local startX, startZ = aiBrain:GetArmyStartPos()
        aiBrain.islandMarker = AIUtils.AIGetClosestMarkerLocation(aiBrain, "Island", startX, startZ)
        aiBrain.islandCheck = true
        if aiBrain.islandMarker then
            aiBrain.isIsland = true
        else
            aiBrain.isIsland = false
        end
    end
    if check == aiBrain.isIsland then
        return true
    end
end

---@param aiBrain AIBrain unused
---@param sizeX number
---@param sizeZ number
---@return true | nil
function MapGreaterThan(aiBrain, sizeX, sizeZ)
    local mapSizeX, mapSizeZ = GetMapSize()
    if mapSizeX > sizeX or mapSizeZ > sizeZ then
        return true
    end
end

---@param aiBrain AIBrain unused
---@param sizeX number
---@param sizeZ number
---@return true | nil
function MapLessThan(aiBrain, sizeX, sizeZ)
    local mapSizeX, mapSizeZ = GetMapSize()
    if mapSizeX < sizeX and mapSizeZ < sizeZ then
        return true
    end
end

--- Buildcondition to check pathing to current enemy 
--- Note this requires the CanPathToCurrentEnemy thread to be running
---@param aiBrain AIBrain
---@param locationType string
---@param pathType string
---@return boolean
function PathToEnemy(aiBrain, locationType, pathType)
    local currentEnemy = aiBrain:GetCurrentEnemy()
    if not currentEnemy then
        return true
    end
    local enemyIndex = aiBrain:GetCurrentEnemy():GetArmyIndex()
    local selfIndex = aiBrain:GetArmyIndex()
    if aiBrain.CanPathToEnemy[selfIndex][enemyIndex][locationType] == pathType then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@return boolean
function WaterMassMarkersPresent(aiBrain)
    if aiBrain.IntelData.WaterMassMarkersPresent then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param locationType string
---@return true | nil
function ReclaimAvailableInGrid(aiBrain, locationType, mapSearch)
    if not aiBrain.GridReclaim then
        WARN('AI WARNING: Reclaim grid does not exist on AI brain '..aiBrain.Nickname)
        return false
    end
    -- Placeholders this part is temporary until the ReclaimGrid defines the playable area min and max grid sizes
    local maxmapdimension = math.max(ScenarioInfo.size[1],ScenarioInfo.size[2])
    local minCellX = 0
    local minCellZ = 0
    local maxCellX = 16
    local maxCellZ = 16
    if maxmapdimension == 256 then
        maxCellX = 8
        maxCellZ = 8
    end
    ---
    if aiBrain.BuilderManagers[locationType].EngineerManager then
        local searchRange
        local reclaimGridInstance = aiBrain.GridReclaim
        local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
        if not mapSearch then
            searchRange = math.floor(engineerManager.Radius / reclaimGridInstance.CellSize)
        else
            searchRange = math.floor((engineerManager.Radius * 2) / reclaimGridInstance.CellSize)
        end
        local cellX, cellZ = reclaimGridInstance:ToGridSpace(engineerManager.Location[1],engineerManager.Location[3])
        local gridSize = 0
        if aiBrain:GetEconomyStoredRatio("MASS") <= 0.7 then
            while gridSize < searchRange do
                for x = math.max(minCellX, cellX - gridSize), math.min(maxCellX, cellX + gridSize), 1 do
                    for z = math.max(minCellZ, cellZ - gridSize), math.min(maxCellZ, cellZ + gridSize), 1 do
                        if reclaimGridInstance.Cells[x][z].TotalMass > 10 then
                            return true
                        end
                        gridSize = gridSize + 1
                    end
                end
            end
        end
    end
    return false
end

-- unused imports kept for mod support
local Utils = import("/lua/utilities.lua")
