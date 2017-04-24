#****************************************************************************
#**
#**  File     :  /lua/editor/EconomyBuildConditions.lua
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
local BuildingTemplates = import('/lua/BuildingTemplates.lua')

##############################################################################################################
# function: GreaterThanEconStorageRatio = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string	aiBrain		= "default_brain"
# parameter 1: float	mStorageRatio	= 0.0				doc = "docs for param1"
# parameter 2: float	eStorageRatio	= 0.0				doc = "param2 docs"
#
##############################################################################################################
function GreaterThanEconStorageRatio(aiBrain, mStorageRatio, eStorageRatio)
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassStorageRatio >= mStorageRatio and econ.EnergyStorageRatio >= eStorageRatio) then
        return true
    end
    return false
end

##############################################################################################################
# function: GreaterThanEconStorageMax = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string	aiBrain         = "default_brain"
# parameter 1: int	mStorage        = 0				doc = "docs for param1"
# parameter 2: int	eStorage	= 0				doc = "param2 docs"
#
##############################################################################################################
function GreaterThanEconStorageMax(aiBrain, mStorage, eStorage)
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassMaxStored >= mStorage and econ.EnergyMaxStored >= eStorage) then
        return true
    end
    return false
end

##############################################################################################################
# function: GreaterThanEconStorageCurrent = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string	aiBrain		= "default_brain"		doc = "docs for param1"
# parameter 1: integer	mStorage	= 0					doc = "docs for param1"
# parameter 2: integer	eStorage	= 0					doc = "param2 docs"
#
##############################################################################################################
function GreaterThanEconStorageCurrent(aiBrain, mStorage, eStorage)
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassStorage >= mStorage and econ.EnergyStorage >= eStorage) then
        return true
    end
    return false
end

##############################################################################################################
# function: LessThanEconTrend = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string	aiBrain		= "default_brain"			doc = "docs for param1"
# parameter 1: integer	mTrend	        = 0				doc = "docs for param1"
# parameter 2: integer	eTrend	        = 0      			doc = "param2 docs"
#
##############################################################################################################
function LessThanEconTrend(aiBrain, mTrend, eTrend)
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassTrend < mTrend and econ.EnergyTrend < eTrend) then
        return true
    else
        return false
    end
end

##############################################################################################################
# function: LessThanEconStorageRatio = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string	aiBrain		     = "default_brain"				doc = "docs for param1"
# parameter 1: integer	mStorageRatio        = 0					doc = "docs for param1"
# parameter 2: integer	eStorageRatio	     = 0					doc = "param2 docs"
#
##############################################################################################################
function LessThanEconStorageRatio(aiBrain, mStorageRatio, eStorageRatio)
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassStorageRatio < mStorageRatio and econ.EnergyStorageRatio < eStorageRatio) then
        return true
    end
    return false
end

##############################################################################################################
# function: LessEconStorageMax = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string       aiBrain	    = "default_brain"				doc = "docs for param1"
# parameter 1: integer      mStorage    = 0					doc = "docs for param1"
# parameter 2: integer      eStorage    = 0					doc = "param2 docs"
#
##############################################################################################################
function LessEconStorageMax(aiBrain, mStorage, eStorage)
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassMaxStored < mStorage and econ.EnergyMaxStored < eStorage) then
        return true
    end
    return false
end

##############################################################################################################
# function: LessEconStorageCurrent = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string       aiBrain         = "default_brain"				doc = "docs for param1"
# parameter 1: integer      mStorage	= 0					doc = "docs for param1"
# parameter 2: integer      eStorage	= 0					doc = "param2 docs"
#
##############################################################################################################
function LessEconStorageCurrent(aiBrain, mStorage, eStorage)
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassStorage < mStorage and econ.EnergyStorage < eStorage) then
        return true
    end
    return false
end


##############################################################################################################
# function: GreaterThanEconTrend = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string	aiBrain		= "default_brain"				doc = "docs for param1"
# parameter 1: int	MassTrend	= 1             doc = "docs for param1"
# parameter 2: int	EnergyTrend	= 1             doc = "param2 docs"
#
##############################################################################################################
function GreaterThanEconTrend(aiBrain, MassTrend, EnergyTrend)
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassTrend >= MassTrend and econ.EnergyTrend >= EnergyTrend) then
        return true
    end
    return false
end

##############################################################################################################
# function: GreaterThanEconIncome = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string	aiBrain		= "default_brain"				doc = "docs for param1"
# parameter 1: int	MassIncome	= 0.1             doc = "docs for param1"
# parameter 2: int	EnergyIncome	= 1             doc = "param2 docs"
#
##############################################################################################################
function GreaterThanEconIncome(aiBrain, MassIncome, EnergyIncome)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, 'ENERGYPRODUCTION EXPERIMENTAL STRUCTURE') then
        #LOG('*AI DEBUG: Found Paragon')
        return true
    end
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassIncome >= MassIncome and econ.EnergyIncome >= EnergyIncome) then
        return true
    end
    return false
end


##############################################################################################################
# function: LessThanEconIncome = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string	aiBrain		= "default_brain"				doc = "docs for param1"
# parameter 1: int	MassIncome	= 0.1             doc = "docs for param1"
# parameter 2: int	EnergyIncome	= 1             doc = "param2 docs"
#
##############################################################################################################
function LessThanEconIncome(aiBrain, MassIncome, EnergyIncome)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, 'ENERGYPRODUCTION EXPERIMENTAL STRUCTURE') then
        #LOG('*AI DEBUG: Found Paragon')
        return false
    end
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassIncome < MassIncome and econ.EnergyIncome < EnergyIncome) then
        return true
    end
    return false
end




##############################################################################################################
# function: LessThanEconEfficiency = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string	aiBrain		= "default_brain"				doc = "docs for param1"
# parameter 1: int	MassEfficiency	= 1             doc = "docs for param1"
# parameter 2: int	EnergyEfficiency	= 1             doc = "param2 docs"
#
##############################################################################################################
function GreaterThanEconEfficiency(aiBrain, MassEfficiency, EnergyEfficiency)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, 'ENERGYPRODUCTION EXPERIMENTAL STRUCTURE') then
        #LOG('*AI DEBUG: Found Paragon')
        return true
    end
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassEfficiency >= MassEfficiency and econ.EnergyEfficiency >= EnergyEfficiency) then
        return true
    end
    return false
end

function LessThanEconEfficiency(aiBrain, MassEfficiency, EnergyEfficiency)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, 'ENERGYPRODUCTION EXPERIMENTAL STRUCTURE') then
        #LOG('*AI DEBUG: Found Paragon')
        return false
    end
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassEfficiency <= MassEfficiency and econ.EnergyEfficiency <= EnergyEfficiency) then
        return true
    end
    return false
end

##############################################################################################################
# function: LessThanEconEfficiencyOverTime = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string	aiBrain		= "default_brain"				doc = "docs for param1"
# parameter 1: int	MassEfficiency	= 1             doc = "docs for param1"
# parameter 2: int	EnergyEfficiency	= 1             doc = "param2 docs"
#
##############################################################################################################
function GreaterThanEconEfficiencyOverTime(aiBrain, MassEfficiency, EnergyEfficiency)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, 'ENERGYPRODUCTION EXPERIMENTAL STRUCTURE') then
        #LOG('*AI DEBUG: Found Paragon')
        return true
    end
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassEfficiencyOverTime >= MassEfficiency and econ.EnergyEfficiencyOverTime >= EnergyEfficiency) then
        return true
    end
    return false
end

function LessThanEconEfficiencyOverTime(aiBrain, MassEfficiency, EnergyEfficiency)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, 'ENERGYPRODUCTION EXPERIMENTAL STRUCTURE') then
        #LOG('*AI DEBUG: Found Paragon')
        return false
    end
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassEfficiencyOverTime <= MassEfficiency and econ.EnergyEfficiencyOverTime <= EnergyEfficiency) then
        return true
    end
    return false
end

function MassIncomeToUnitRatio(aiBrain, ratio, compareType, unitCategory)
    local econTime = aiBrain:GetEconomyOverTime()

    local testCat = unitCategory
    if type(testCat) == 'string' then
        testCat = ParseEntityCategory(testCat)
    end
    local unitCount = aiBrain:GetCurrentUnits(testCat)

    # Find units of this type being built or about to be built
    unitCount = unitCount + aiBrain:GetEngineerManagerUnitsBeingBuilt(testCat)

    local checkRatio = (econTime.MassIncome * 10) / unitCount

    return CompareBody(checkRatio, ratio, compareType)
end

function GreaterThanMassIncomeToFactory(aiBrain, t1Drain, t2Drain, t3Drain)
    local econTime = aiBrain:GetEconomyOverTime()

    # T1 Test
    local testCat = categories.TECH1 * categories.FACTORY
    local unitCount = aiBrain:GetCurrentUnits(testCat)
    # Find units of this type being built or about to be built
    unitCount = unitCount + aiBrain:GetEngineerManagerUnitsBeingBuilt(testCat)

    local massTotal = unitCount * t1Drain

    # T2 Test
    testCat = categories.TECH2 * categories.FACTORY
    unitCount = aiBrain:GetCurrentUnits(testCat)

    massTotal = massTotal + (unitCount * t2Drain)

    # T3 Test
    testCat = categories.TECH3 * categories.FACTORY
    unitCount = aiBrain:GetCurrentUnits(testCat)

    massTotal = massTotal + (unitCount * t3Drain)

    if not CompareBody((econTime.MassIncome * 10), massTotal, '>') then
        return false
    end

    return true
end

function MassToFactoryRatioBaseCheck(aiBrain, locationType)
    local factoryManager = aiBrain.BuilderManagers[locationType].FactoryManager
    if not factoryManager then
        WARN('*AI WARNING: FactoryCapCheck - Invalid location - ' .. locationType)
        return false
    end

    local t1 = aiBrain.BuilderManagers[locationType].BaseSettings.MassToFactoryValues.T1Value or 8
    local t2 = aiBrain.BuilderManagers[locationType].BaseSettings.MassToFactoryValues.T2Value or 20
    local t3 = aiBrain.BuilderManagers[locationType].BaseSettings.MassToFactoryValues.T3Value or 30

    return GreaterThanMassIncomeToFactory(aiBrain, t1, t2, t3)
end

function CompareBody(numOne, numTwo, compareType)
    if compareType == '>' then
        if numOne > numTwo then
            return true
        end
    elseif compareType == '<' then
        if numOne < numTwo then
            return true
        end
    elseif compareType == '>=' then
        if numOne >= numTwo then
            return true
        end
    elseif compareType == '<=' then
        if numOne <= numTwo then
            return true
        end
    else
        error('*AI ERROR: Invalid compare type: ' .. compareType)
        return false
    end
    return false
end

function HaveGreaterThanUnitsWithCategory(aiBrain, numReq, category, idleReq)
    local numUnits
    local total = 0
    if type(category) == 'string' then
        category = ParseEntityCategory(category)
    end
    if not idleReq then
        numUnits = aiBrain:GetListOfUnits(category, false)
    else
        numUnits = aiBrain:GetListOfUnits(category, true)
    end
    for k,v in numUnits do
        if v:GetFractionComplete() == 1 then
            total = total + 1
            if total > numReq then
                return true
            end
        end
    end
    if total > numReq then
        return true
    end
    return false
end
