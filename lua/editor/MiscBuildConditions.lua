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
local AIUtils = import('/lua/ai/aiutilities.lua')

---@param aiBrain AIBrain
---@return boolean
function True(aiBrain)
    return true
end

---@param aiBrain AIBrain
---@return boolean
function False(aiBrain)
    return false
end

---@param aiBrain AIBrain
---@param higherThan integer
---@param lowerThan integer
---@param minNumber integer
---@param maxNumber integer
---@return boolean
function RandomNumber(aiBrain, higherThan, lowerThan, minNumber, maxNumber)
    local num = Random(minNumber, maxNumber)
    if higherThan < num and lowerThan > num then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param layerPref string
---@return boolean
function IsAIBrainLayerPref(aiBrain, layerPref)
    if layerPref == aiBrain.LayerPref then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param num integer
---@return boolean
function MissionNumber(aiBrain, num)
    if ScenarioInfo.MissionNumber and num == ScenarioInfo.MissionNumber then
        return true
    else
        return false
    end
end

---@param aiBrain AIBrain
---@param num integer
---@return boolean
function MissionNumberGreaterOrEqual(aiBrain, num)
    if ScenarioInfo.MissionNumber and num <= ScenarioInfo.MissionNumber then
        return true
    else
        return false
    end
end

---@param aiBrain AIBrain
---@param num integer
---@return boolean
function MissionNumberLessOrEqual(aiBrain, num)
    if ScenarioInfo.MissionNumber and num >= ScenarioInfo.MissionNumber then
        return true
    else
        return false
    end
end

---@param aiBrain AIBrain
---@param varName string
---@return boolean
function CheckScenarioInfoVarTable(aiBrain, varName)
    if ScenarioInfo.VarTable then
        local i = 1
        if not ScenarioInfo.VarTable[varName] then
            return false
        end
        return true
    end
end

---@param aiBrain AIBrain
---@param varName string
---@return boolean
function CheckScenarioInfoVarTableFalse(aiBrain, varName)
    if ScenarioInfo.VarTable then
        local i = 1
        if ScenarioInfo.VarTable[varName] then
            return false
        end
        return true
    end
end

---@param aiBrain AIBrain
---@param diffLevel integer
---@return boolean
function DifficultyEqual(aiBrain, diffLevel)
    if not ScenarioInfo.Options.Difficulty then
        return false
    end
    if ScenarioInfo.Options.Difficulty == diffLevel then
        return true
    else
        return false
    end
end

---@param aiBrain AIBrain
---@param diffLevel integer
---@return boolean
function DifficultyGreaterOrEqual(aiBrain, diffLevel)
    if not ScenarioInfo.Options.Difficulty then
        return false
    end
    if ScenarioInfo.Options.Difficulty >= diffLevel then
        return true
    else
        return false
    end
end

---@param aiBrain AIBrain
---@param diffLevel integer
---@return boolean
function DifficultyLessOrEqual(aiBrain, diffLevel)
    if not ScenarioInfo.Options.Difficulty then
        return false
    end
    if ScenarioInfo.Options.Difficulty <= diffLevel then
        return true
    else
        return false
    end
end

---@param aiBrain AIBrain
---@param chainName string
---@return boolean
function MarkerChainExists(aiBrain, chainName)
    local chain = Scenario.Chains[chainName]
    if not chain then
        return false
    else
        return true
    end
end

---@param aiBrain AIBrain
---@param ... number[]
---@return boolean
function FactionIndex(aiBrain, ...)
    local FactionIndex = aiBrain:GetFactionIndex()
    for index, faction in arg do
        if index == 'n' then continue end
        if faction == FactionIndex then
            return true
        end
    end
    return false
end

---@param aiBrain AIBrain
---@param locType string
---@return boolean
function ReclaimablesInArea(aiBrain, locType)
    --DUNCAN - was .9. Reduced as dont need to reclaim yet if plenty of mass
    if aiBrain:GetEconomyStoredRatio('MASS') > .7 then
        return false
    end

    --DUNCAN - who cares about energy for reclaming?
    --if aiBrain:GetEconomyStoredRatio('ENERGY') > .9 then
    --    return false
    --end

    local ents = AIUtils.AIGetReclaimablesAroundLocation(aiBrain, locType)
    if ents and not table.empty(ents) then
        return true
    end

    return false
end

---@param aiBrain AIBrain
---@param locType string
---@return boolean
function CheckAvailableGates(aiBrain, locType)
    local pos, rad
    if aiBrain.HasPlatoonList then
        for k,v in aiBrain.PBM.Locations do
            if v.LocationType == locType then
                pos = v.Location
                rad = v.Radius
                break
            end
        end
    elseif aiBrain.BuilderManagers[locType] then
        pos = aiBrain.BuilderManagers[locType].FactoryManager:GetLocationCoords()
        rad = aiBrain.BuilderManagers[locType].FactoryManager.Radius
    end
    if not pos then
        return false
    end
    local gates = GetOwnUnitsAroundPoint(aiBrain, categories.GATE, pos, rad)
    if not gates then
        return false
    else
        for k,v in gates do
            if not v:IsUnitState('TransportLoading') then
                return true
            end
        end
    end
    return false
end

---@param aiBrain AIBrain
---@param num integer
---@return boolean
function GreaterThanMapWaterRatio(aiBrain, num)
    local ratio = aiBrain:GetMapWaterRatio()
    if ratio > num then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param num integer
---@return boolean
function LessThanMapWaterRatio(aiBrain, num)
    local ratio = aiBrain:GetMapWaterRatio()
    if ratio < num then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@return boolean
function ArmyNeedsTransports(aiBrain)
    if aiBrain and aiBrain:GetNoRushTicks() <= 0 and aiBrain.NeedTransports and aiBrain.NeedTransports > 0  then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param number integer
---@return boolean
function TransportNeedGreater(aiBrain, number)
    if aiBrain and aiBrain.NeedsTransports and aiBrain:GetNoRushTicks() <= 0 and aiBrain.NeedTransports > number then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@return boolean
function ArmyWantsTransports(aiBrain)
    if aiBrain and aiBrain:GetNoRushTicks() <= 0 and aiBrain.WantTransports then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@return boolean
function CDRRunningAway(aiBrain)
    local units = aiBrain:GetListOfUnits(categories.COMMAND, false)
    for k,v in units do
        if not v.Dead and v.Running then
            return true
        end
    end
    return false
end

---@param aiBrain AIBrain
---@param num integer
---@return boolean
function GreaterThanGameTime(aiBrain, num)
    local time = GetGameTimeSeconds()
    if aiBrain.CheatEnabled and (0.5 * num) < time then
        return true
    elseif num < time then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param num integer
---@return boolean
function LessThanGameTime(aiBrain, num)
    return (not GreaterThanGameTime(aiBrain, num))
end

---@param aiBrain AIBrain
---@return boolean
function PreBuiltBase(aiBrain)
    if aiBrain.PreBuilt then
        return true
    else
        return false
    end
end

---@param aiBrain AIBrain
---@return boolean
function NotPreBuilt(aiBrain)
    if not aiBrain.PreBuilt then
        return true
    else
        return false
    end
end

--- added to check the map.
---@param aiBrain AIBrain
---@param mapname string
---@param check boolean
---@return boolean
function MapCheck(aiBrain, mapname, check)
    if (ScenarioInfo.name == mapname) == check then
        return true
    end
    return false
end

--- added to check for islands
---@param aiBrain AIBrain
---@param check boolean
---@return boolean
function IsIsland(aiBrain, check)

    if not aiBrain.islandCheck then
        local startX, startZ = aiBrain:GetArmyStartPos()
        aiBrain.isIsland = false
        aiBrain.islandMarker = AIUtils.AIGetClosestMarkerLocation(aiBrain, 'Island', startX, startZ)
        aiBrain.islandCheck = true
        if aiBrain.islandMarker then
            aiBrain.isIsland = true
        end
    end

    if check == aiBrain.isIsland then
        return true
    else
        return false
    end
end

---@param aiBrain AIBrain
---@param sizeX integer
---@param sizeZ integer
---@return boolean
function MapGreaterThan(aiBrain, sizeX, sizeZ)
    local mapSizeX, mapSizeZ = GetMapSize()
    if mapSizeX > sizeX or mapSizeZ > sizeZ then
        --LOG('*AI DEBUG: MapGreaterThan returned True SizeX: ' .. sizeX .. ' sizeZ: ' .. sizeZ)
        return true
    end
    --LOG('*AI DEBUG: MapGreaterThan returned False SizeX: ' .. sizeX .. ' sizeZ: ' .. sizeZ)
    return false
end

---@param aiBrain AIBrain
---@param sizeX integer
---@param sizeZ integer
---@return boolean
function MapLessThan(aiBrain, sizeX, sizeZ)
    local mapSizeX, mapSizeZ = GetMapSize()
    if mapSizeX < sizeX and mapSizeZ < sizeZ then
        --LOG('*AI DEBUG: MapLessThan returned True SizeX: ' .. sizeX .. ' sizeZ: ' .. sizeZ)
        return true
    end
    --LOG('*AI DEBUG: MapLessThan returned False SizeX: ' .. sizeX .. ' sizeZ: ' .. sizeZ)
    return false
end

-- moved unused imports to bottom for modd support
local Utils = import('/lua/utilities.lua')