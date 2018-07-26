#****************************************************************************
#**
#**  File     :  /lua/MiscBuildConditions.lua
#**  Author(s): Dru Staltman, John Comes
#**
#**  Summary  : Generic AI Platoon Build Conditions
#**             Build conditions always return true or false
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local AIUtils = import('/lua/ai/aiutilities.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local Utils = import('/lua/utilities.lua')

##############################################################################################################
# function: True = BuildCondition   doc = "Please work function docs."
#
# parameter 0: string   aiBrain     = "default_brain"
#
##############################################################################################################
function True(aiBrain)
    return true
end

##############################################################################################################
# function: False = BuildCondition  doc = "Please work function docs."
#
# parameter 0: string   aiBrain     = "default_brain"
#
##############################################################################################################
function False(aiBrain)
    return false
end

##############################################################################################################
# function: RandomNumber = BuildCondition   doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: int      higherThan      = 0                 doc = "docs for param1"
# parameter 2: int      lowerThan       = 0                 doc = "param2 docs"
# parameter 3: int      minNumber       = 0                 doc = "param2 docs"
# parameter 4: int      maxNumber       = 0                 doc = "param2 docs"
#
##############################################################################################################
function RandomNumber(aiBrain, higherThan, lowerThan, minNumber, maxNumber)
    local num = Random(minNumber, maxNumber)
    if higherThan < num and lowerThan > num then
        return true
    end
    return false
end

##############################################################################################################
# function: IsAIBrainLayerPref = BuildCondition doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: string   layerPref       = "Land"            doc = "docs for param1"
#
##############################################################################################################
function IsAIBrainLayerPref(aiBrain, layerPref)
    if layerPref == aiBrain.LayerPref then
        return true
    end
    return false
end

##############################################################################################################
# function: MissionNumber = BuildCondition  doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: int  num             = 1         doc = "docs for param1"
#
##############################################################################################################
function MissionNumber(aiBrain, num)
    if ScenarioInfo.MissionNumber and num == ScenarioInfo.MissionNumber then
        return true
    else
        return false
    end
end

##############################################################################################################
# function: MissionNumberGreaterOrEqual = BuildCondition  doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: int  num             = 1         doc = "docs for param1"
#
##############################################################################################################
function MissionNumberGreaterOrEqual(aiBrain, num)
    if ScenarioInfo.MissionNumber and num <= ScenarioInfo.MissionNumber then
        return true
    else
        return false
    end
end

##############################################################################################################
# function: MissionNumberLessOrEqual = BuildCondition  doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: int  num             = 1         doc = "docs for param1"
#
##############################################################################################################
function MissionNumberLessOrEqual(aiBrain, num)
    if ScenarioInfo.MissionNumber and num >= ScenarioInfo.MissionNumber then
        return true
    else
        return false
    end
end

##############################################################################################################
# function: CheckScenarioInfoVarTable = BuildCondition  doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: string   varName         = "VarName"         doc = "docs for param1"
#
##############################################################################################################
function CheckScenarioInfoVarTable(aiBrain, varName)
    if ScenarioInfo.VarTable then
        local i = 1
        if not ScenarioInfo.VarTable[varName] then
            return false
        end
        return true
    end
end

##############################################################################################################
# function: CheckScenarioInfoVarTableFalse = BuildCondition doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: string   varName         = "VarName"         doc = "docs for param1"
#
##############################################################################################################
function CheckScenarioInfoVarTableFalse(aiBrain, varName)
    if ScenarioInfo.VarTable then
        local i = 1
        if ScenarioInfo.VarTable[varName] then
            return false
        end
        return true
    end
end

##############################################################################################################
# function: DifficultyEqual = BuildCondition    doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: int  diffLevel         = "1"         doc = "docs for param1"
#
##############################################################################################################
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

##############################################################################################################
# function: DifficultyGreaterOrEqual = BuildCondition   doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: int  diffLevel         = "1"         doc = "docs for param1"
#
##############################################################################################################
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

##############################################################################################################
# function: DifficultyLessOrEqual = BuildCondition  doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: int  diffLevel         = "1"         doc = "docs for param1"
#
##############################################################################################################
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

##############################################################################################################
# function: MarkerChainExists = BuildCondition  doc = "Please work function docs."
#
# parameter 0: string  aiBrain         = "default_brain"
# parameter 1: string  chainName       = "CHAIN_NAME"         doc = "docs for param1"
#
##############################################################################################################
function MarkerChainExists(aiBrain, chainName)
    local chain = Scenario.Chains[chainName]
    if not chain then
        return false
    else
        return true
    end
end

##############################################################################################################
# function: FactionIndex = BuildCondition   doc = "Please work function docs."
#
# parameter 0: string   aiBrain     = "default_brain"
# parameter 1: int factionNum = "1"
# parameter 2: int otherFactionNum = "0"
#
##############################################################################################################
function FactionIndex(aiBrain, factionNum, otherFactionNum, thirdFacNum)
    local facIndex = aiBrain:GetFactionIndex()
    #LOG('*AI DEBUG: ARMY 2: Getting Faction Index = ', facIndex, ' while factionNum = ', factionNum, ' and otherFactionNum = ', otherFactionNum)
    if thirdFacNum and thirdFacNum ~= 0 then
        if thirdFacNum == facIndex or otherFactionNum == facIndex or factionNum == facIndex then
            return true
        else
            return false
        end
    elseif otherFactionNum ~= 0 then
        if facIndex == factionNum or otherFactionNum == facIndex then
            return true
        else
            return false
        end
    elseif facIndex == factionNum then
        return true
    else
        return false
    end
end

##############################################################################################################
# function: ReclaimablesInArea = BuildCondition   doc = "Please work function docs."
#
# parameter 0: string   aiBrain     = "default_brain"
# parameter 1: string   locType     = "MAIN"
#
##############################################################################################################
function ReclaimablesInArea(aiBrain, locType)
    #DUNCAN - was .9. Reduced as dont need to reclaim yet if plenty of mass
    if aiBrain:GetEconomyStoredRatio('MASS') > .7 then
        return false
    end

    #DUNCAN - who cares about energy for reclaming?
    #if aiBrain:GetEconomyStoredRatio('ENERGY') > .9 then
    #    return false
    #end

    local ents = AIUtils.AIGetReclaimablesAroundLocation(aiBrain, locType)
    if ents and table.getn(ents) > 0 then
        return true
    end

    return false
end

##############################################################################################################
# function: CheckAvailableGates = BuildCondition   doc = "Please work function docs."
#
# parameter 0: string   aiBrain     = "default_brain"
# parameter 1: string   locType     = "MAIN"
#
##############################################################################################################
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



##############################################################################################################
# function: GreaterThanMapWaterRatio = BuildCondition  doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: int  num             = 1         doc = "docs for param1"
#
##############################################################################################################
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



##############################################################################################################
# function: ArmyNeedsTransports = BuildCondition  doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
#
##############################################################################################################
function ArmyNeedsTransports(aiBrain)
    if aiBrain and aiBrain:GetNoRushTicks() <= 0 and aiBrain.NeedTransports and aiBrain.NeedTransports > 0  then
        return true
    end
    return false
end

##############################################################################################################
# function: TransportNeedGreater = BuildCondition  doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: int  num             = 1         doc = "docs for param1"
#
##############################################################################################################
function TransportNeedGreater(aiBrain, number)
    if aiBrain and aiBrain.NeedsTransports and aiBrain:GetNoRushTicks() <= 0 and aiBrain.NeedTransports > number then
        return true
    end
    return false
end

##############################################################################################################
# function: ArmyWantsTransports = BuildCondition  doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
#
##############################################################################################################
function ArmyWantsTransports(aiBrain)
    if aiBrain and aiBrain:GetNoRushTicks() <= 0 and aiBrain.WantTransports then
        return true
    end
    return false
end

##############################################################################################################
# function: CDRRunningAway = BuildCondition  doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
#
##############################################################################################################
function CDRRunningAway(aiBrain)
    local units = aiBrain:GetListOfUnits(categories.COMMAND, false)
    for k,v in units do
        if not v.Dead and v.Running then
            return true
        end
    end
    return false
end


##############################################################################################################
# function: GreaterThanGameTime = BuildCondition  doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: int  num             = 1         doc = "docs for param1"
#
##############################################################################################################
function GreaterThanGameTime(aiBrain, num)
    local time = GetGameTimeSeconds()
    if aiBrain.CheatEnabled and (0.5 * num) < time then
        return true
    elseif num < time then
        return true
    end
    return false
end

##############################################################################################################
# function: LessThanGameTime = BuildCondition  doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: int  num             = 1         doc = "docs for param1"
#
##############################################################################################################
function LessThanGameTime(aiBrain, num)
    return (not GreaterThanGameTime(aiBrain, num))
end

##############################################################################################################
# function: PreBuiltBase = BuildCondition  doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
#
##############################################################################################################
function PreBuiltBase(aiBrain)
    if aiBrain.PreBuilt then
        return true
    else
        return false
    end
end

##############################################################################################################
# function: NotPreBuilt = BuildCondition  doc = "Please work function docs."
#
# parameter 0: string   aiBrain         = "default_brain"
#
##############################################################################################################
function NotPreBuilt(aiBrain)
    if not aiBrain.PreBuilt then
        return true
    else
        return false
    end
end

#DUNCAN - added to check the map.
function MapCheck(aiBrain, mapname, check)
    if (ScenarioInfo.name == mapname) == check then
        return true
    end
    return false
end

#DUNCAN - added to check for islands
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


##############################################################################################################
# function: MapGreaterThan = BuildCondition
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: integer  sizeX           = "sizeX"
# parameter 2: integer  sizeZ           = "sizeZ"
#
##############################################################################################################
function MapGreaterThan(aiBrain, sizeX, sizeZ)
    local mapSizeX, mapSizeZ = GetMapSize()
    if mapSizeX > sizeX or mapSizeZ > sizeZ then
        #LOG('*AI DEBUG: MapGreaterThan returned True SizeX: ' .. sizeX .. ' sizeZ: ' .. sizeZ)
        return true
    end
    #LOG('*AI DEBUG: MapGreaterThan returned False SizeX: ' .. sizeX .. ' sizeZ: ' .. sizeZ)
    return false
end

##############################################################################################################
# function: MapLessThan = BuildCondition
#
# parameter 0: string   aiBrain         = "default_brain"
# parameter 1: integer  sizeX           = "sizeX"
# parameter 2: integer  sizeZ           = "sizeZ"
#
##############################################################################################################
function MapLessThan(aiBrain, sizeX, sizeZ)
    local mapSizeX, mapSizeZ = GetMapSize()
    if mapSizeX < sizeX and mapSizeZ < sizeZ then
        #LOG('*AI DEBUG: MapLessThan returned True SizeX: ' .. sizeX .. ' sizeZ: ' .. sizeZ)
        return true
    end
    #LOG('*AI DEBUG: MapLessThan returned False SizeX: ' .. sizeX .. ' sizeZ: ' .. sizeZ)
    return false
end





