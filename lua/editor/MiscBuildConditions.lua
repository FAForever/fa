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
local Utils = import('/lua/utilities.lua')

------------------------------------------------------------------------------
-- function: True = BuildCondition
--
-- parameter 0: string   aiBrain     = "default_brain"
--
------------------------------------------------------------------------------
function True(aiBrain)
    return true
end

------------------------------------------------------------------------------
-- function: False = BuildCondition
--
-- parameter 0: string   aiBrain     = "default_brain"
--
------------------------------------------------------------------------------
function False(aiBrain)
    return false
end

------------------------------------------------------------------------------
-- function: RandomNumber = BuildCondition
--
-- parameter 0: string   aiBrain         = "default_brain"
-- parameter 1: int      higherThan      = 0
-- parameter 2: int      lowerThan       = 0
-- parameter 3: int      minNumber       = 0
-- parameter 4: int      maxNumber       = 0
--
------------------------------------------------------------------------------
function RandomNumber(aiBrain, higherThan, lowerThan, minNumber, maxNumber)
    local num = Random(minNumber, maxNumber)
    if higherThan < num and lowerThan > num then
        return true
    end
    return false
end

------------------------------------------------------------------------------
-- function: DifficultyGreaterOrEqual = BuildCondition
--
-- parameter 0: string   aiBrain         = "default_brain"
-- parameter 1: int  diffLevel         = "1"
--
------------------------------------------------------------------------------
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

------------------------------------------------------------------------------
-- function: FactionIndex = BuildCondition
--
-- parameter 0: string   aiBrain     = "default_brain"
-- parameter 1: table    factionNum  = {1,2,3,4,5}
--
------------------------------------------------------------------------------
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

------------------------------------------------------------------------------
-- function: ReclaimablesInArea = BuildCondition
--
-- parameter 0: string   aiBrain     = "default_brain"
-- parameter 1: string   locType     = "MAIN"
--
------------------------------------------------------------------------------
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
    if ents and table.getn(ents) > 0 then
        return true
    end

    return false
end

------------------------------------------------------------------------------
-- function: GreaterThanMapWaterRatio = BuildCondition
--
-- parameter 0: string   aiBrain         = "default_brain"
-- parameter 1: int  num             = 1
--
------------------------------------------------------------------------------
function GreaterThanMapWaterRatio(aiBrain, num)
    local ratio = aiBrain:GetMapWaterRatio()
    if ratio > num then
        return true
    end
    return false
end

function LessThanMapWaterRatio(aiBrain, num)
    local ratio = aiBrain:GetMapWaterRatio()
    if ratio < num then
        return true
    end
    return false
end

------------------------------------------------------------------------------
-- function: ArmyNeedsTransports = BuildCondition
--
-- parameter 0: string   aiBrain         = "default_brain"
--
------------------------------------------------------------------------------
function ArmyNeedsTransports(aiBrain)
    if aiBrain and aiBrain:GetNoRushTicks() <= 0 and aiBrain.NeedTransports and aiBrain.NeedTransports > 0  then
        return true
    end
    return false
end

------------------------------------------------------------------------------
-- function: TransportNeedGreater = BuildCondition
--
-- parameter 0: string   aiBrain         = "default_brain"
-- parameter 1: int  num             = 1
--
------------------------------------------------------------------------------
function TransportNeedGreater(aiBrain, number)
    if aiBrain and aiBrain.NeedsTransports and aiBrain:GetNoRushTicks() <= 0 and aiBrain.NeedTransports > number then
        return true
    end
    return false
end

------------------------------------------------------------------------------
-- function: GreaterThanGameTime = BuildCondition
--
-- parameter 0: string   aiBrain         = "default_brain"
-- parameter 1: int  num             = 1
--
------------------------------------------------------------------------------
function GreaterThanGameTime(aiBrain, num)
    local time = GetGameTimeSeconds()
    if aiBrain.CheatEnabled and (0.5 * num) < time then
        return true
    elseif num < time then
        return true
    end
    return false
end

------------------------------------------------------------------------------
-- function: LessThanGameTime = BuildCondition
--
-- parameter 0: string   aiBrain         = "default_brain"
-- parameter 1: int  num             = 1
--
------------------------------------------------------------------------------
function LessThanGameTime(aiBrain, num)
    return (not GreaterThanGameTime(aiBrain, num))
end

------------------------------------------------------------------------------
-- function: PreBuiltBase = BuildCondition
--
-- parameter 0: string   aiBrain         = "default_brain"
--
------------------------------------------------------------------------------
function PreBuiltBase(aiBrain)
    if aiBrain.PreBuilt then
        return true
    else
        return false
    end
end

------------------------------------------------------------------------------
-- function: NotPreBuilt = BuildCondition
--
-- parameter 0: string   aiBrain         = "default_brain"
--
------------------------------------------------------------------------------
function NotPreBuilt(aiBrain)
    if not aiBrain.PreBuilt then
        return true
    else
        return false
    end
end

------------------------------------------------------------------------------
-- function: MapCheck = BuildCondition
--
-- parameter 0: string   aiBrain         = "default_brain"
-- parameter 1: string   mapname         = "Seton's Clutch"
-- parameter 2: bool     check           = true
--
------------------------------------------------------------------------------
--DUNCAN - added to check the map.
--UVESO - only used for the map "Seton's Clutch" for 4 Land builders: Mass Hunter Early Game, Mass Hunter Mid Game, StartLocationAttack, T1 Tanks - Engineer Guard
function MapCheck(aiBrain, mapname, check)
    if (ScenarioInfo.name == mapname) == check then
        return true
    end
    return false
end

------------------------------------------------------------------------------
-- function: IsIsland = BuildCondition
--
-- parameter 0: string   aiBrain         = "default_brain"
-- parameter 1: bool     check           = true
--
------------------------------------------------------------------------------
--DUNCAN - added to check for islands
--UVESO checks if the map has Island AI markers. Should be replaced with sorians "IsIslandMap" BuildCondition.
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

------------------------------------------------------------------------------
-- function: MapGreaterThan = BuildCondition
--
-- parameter 0: string   aiBrain         = "default_brain"
-- parameter 1: integer  sizeX           = "sizeX"
-- parameter 2: integer  sizeZ           = "sizeZ"
--
------------------------------------------------------------------------------
function MapGreaterThan(aiBrain, sizeX, sizeZ)
    local mapSizeX, mapSizeZ = GetMapSize()
    if mapSizeX > sizeX or mapSizeZ > sizeZ then
        --LOG('*AI DEBUG: MapGreaterThan returned True SizeX: ' .. sizeX .. ' sizeZ: ' .. sizeZ)
        return true
    end
    --LOG('*AI DEBUG: MapGreaterThan returned False SizeX: ' .. sizeX .. ' sizeZ: ' .. sizeZ)
    return false
end

------------------------------------------------------------------------------
-- function: MapLessThan = BuildCondition
--
-- parameter 0: string   aiBrain         = "default_brain"
-- parameter 1: integer  sizeX           = "sizeX"
-- parameter 2: integer  sizeZ           = "sizeZ"
--
------------------------------------------------------------------------------
function MapLessThan(aiBrain, sizeX, sizeZ)
    local mapSizeX, mapSizeZ = GetMapSize()
    if mapSizeX < sizeX and mapSizeZ < sizeZ then
        --LOG('*AI DEBUG: MapLessThan returned True SizeX: ' .. sizeX .. ' sizeZ: ' .. sizeZ)
        return true
    end
    --LOG('*AI DEBUG: MapLessThan returned False SizeX: ' .. sizeX .. ' sizeZ: ' .. sizeZ)
    return false
end

