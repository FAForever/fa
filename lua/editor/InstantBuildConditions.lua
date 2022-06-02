#****************************************************************************
#**
#**  File     :  /lua/editor/InstantBuildConditions.lua
#**  Author(s): Dru Staltman
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local AIUtils = import('/lua/ai/aiutilities.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local Utils = import('/lua/utilities.lua')

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

##############################################################################################################
# function: HaveEqualToUnitsWithCategory = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string	aiBrain		= "default_brain"
# parameter 1: int      numReq     	= 0					doc = "docs for param1"
# parameter 2: expr   category        = categories.ALLUNITS			doc = "param2 docs"
# parameter 3: bool   idleReq       = false         doc = "docs for param3"
#
##############################################################################################################
function HaveEqualToUnitsWithCategory(aiBrain, numReq, category, idleReq)
    local numUnits
    if not idleReq then
        numUnits = aiBrain:GetCurrentUnits(category)
    else
        numUnits = table.getn(aiBrain:GetListOfUnits(category, true))
    end
    if numUnits == numReq then
        return true
    end
    return false
end

##############################################################################################################
# function: HaveGreaterThanUnitsWithCategory = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string   aiBrain		    = "default_brain"
# parameter 1: int      numReq     = 0					doc = "docs for param1"
# parameter 2: expr   category        = categories.ALLUNITS		doc = "param2 docs"
# parameter 3: expr   idleReq       = false         doc = "docs for param3"
#
##############################################################################################################
function HaveGreaterThanUnitsWithCategory(aiBrain, numReq, category, idleReq)
    local numUnits
    if not idleReq then
        numUnits = aiBrain:GetCurrentUnits(category)
    else
        numUnits = table.getn(aiBrain:GetListOfUnits(category, true))
    end
    if numUnits > numReq then
        return true
    end
    return false
end

##############################################################################################################
# function: HaveLessThanUnitsWithCategory = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string	aiBrain		= "default_brain"
# parameter 1: int	numReq          = 0				doc = "docs for param1"
# parameter 2: expr   category        = categories.ALLUNITS		doc = "param2 docs"
# parameter 3: expr   idleReq       = false         doc = "docs for param3"
#
##############################################################################################################
function HaveLessThanUnitsWithCategory(aiBrain, numReq, category, idleReq)
    local numUnits
    if not idleReq then
        numUnits = aiBrain:GetCurrentUnits(category)
    else
        numUnits = table.getn(aiBrain:GetListOfUnits(category, true))
    end
    if numUnits < numReq then
        return true
    end
    return false
end

function BrainNotLowPowerMode(aiBrain)
    if not aiBrain.LowEnergyMode then
        return true
    end
    return false
end

function BrainNotLowMassMode(aiBrain)
    if not aiBrain.LowMassMode then
        return true
    end
    return false
end