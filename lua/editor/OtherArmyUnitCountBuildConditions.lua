#****************************************************************************
#**
#**  File     :  /lua/editor/OtherArmyUnitCountBuildConditions.lua
#**  Author(s): Dru Staltman
#**
#**  Summary  : Generic AI Platoon Build Conditions
#**             Build conditions always return true or false
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local AIUtils = import('/lua/ai/aiutilities.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')

##############################################################################################################
# function: BrainGreaterThanNumCategory = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string	aiBrain		= "default_brain"
# parameter 1: string	targetBrain	= "ArmyName"
# parameter 2: int	numReq		= 0			doc = "docs for param1"
# parameter 3: expr	category	= categories.ALLUNITS			doc = "param2 docs"
#
##############################################################################################################
function BrainGreaterThanNumCategory( aiBrain, targetBrain, numReq, category )
    local testBrain = ArmyBrains[1]
    for k,v in ArmyBrains do
        if v.Name == targetBrain then
            testBrain = v
            break
        end
    end
    local numUnits = testBrain:GetCurrentUnits(category)
    if numUnits > numReq then
        return true
    else
        return false
    end
end


##############################################################################################################
# function: BrainLessThanNumCategory = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string	aiBrain		= "default_brain"
# parameter 1: string	targetBrain	= "ArmyName"
# parameter 2: int	numReq		= 0			doc = "docs for param1"
# parameter 3: expr	category	= categories.ALLUNITS			doc = "param2 docs"
#
##############################################################################################################
function BrainLessThanNumCategory( aiBrain, targetBrain, numReq, category )
    local testBrain = ArmyBrains[1]
    for k,v in ArmyBrains do
        if v.Name == targetBrain then
            testBrain = v
            break
        end
    end
    local numUnits = testBrain:GetCurrentUnits(category)
    if numUnits < numReq then
        return true
    else
        return false
    end
end


##############################################################################################################
# function: BrainGreaterThanOrEqualNumCategory = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string	aiBrain		= "default_brain"
# parameter 1: string	targetBrain	= "ArmyName"
# parameter 2: int	numReq		= 0			doc = "docs for param1"
# parameter 3: expr	category	= categories.ALLUNITS			doc = "param2 docs"
#
##############################################################################################################
function BrainGreaterThanOrEqualNumCategory( aiBrain, targetBrain, numReq, category )
    local testBrain = ArmyBrains[1]
    for k,v in ArmyBrains do
        if v.Name == targetBrain then
            testBrain = v
            break
        end
    end
    local numUnits = testBrain:GetCurrentUnits(category)
    if numUnits >= numReq then
        return true
    else
        return false
    end
end


##############################################################################################################
# function: BrainLessThanOrEqualNumCategory = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string	aiBrain		= "default_brain"
# parameter 1: string	targetBrain	= "ArmyName"
# parameter 2: int	numReq		= 0			doc = "docs for param1"
# parameter 3: expr	category	= categories.ALLUNITS			doc = "param2 docs"
#
##############################################################################################################
function BrainLessThanOrEqualNumCategory( aiBrain, targetBrain, numReq, category )
    local testBrain = ArmyBrains[1]
    for k,v in ArmyBrains do
        if v.Name == targetBrain then
            testBrain = v
            break
        end
    end
    local numUnits = testBrain:GetCurrentUnits(category)
    if numUnits <= numReq then
        return true
    else
        return false
    end
end

##############################################################################################################
# function: FocusBrainBeingBuiltOrActiveCategoryCompare = BuildCondition	doc = "Please work function docs."
#
# parameter 0: string	aiBrain		= "default_brain"
# parameter 1: int	numReq		= 0			doc = "docs for param1"
# parameter 2: expr	categories	= categories.ALLUNITS			doc = "param2 docs"
# parameter 3: string compareType = ">="
#
##############################################################################################################
function FocusBrainBeingBuiltOrActiveCategoryCompare( aiBrain, numReq, categories, compareType )
    local testBrain = ArmyBrains[GetFocusArmy()]
    local num = 0
    for k,v in categories do
        num = num + testBrain:GetBlueprintStat('Units_BeingBuilt', v)
        num = num + testBrain:GetBlueprintStat('Units_Active', v)
    end

    if not compareType or compareType == '>=' then
        if num >= numReq then
            return true
        end
    elseif compareType == '==' then
        if num == numReq then
            return true
        end
    elseif compareType == '<=' then
        if num <= numReq then
            return true
        end
    elseif compareType == '>' then
        if num > numReq then
            return true
        end
    elseif compareType == '<' then
        if num < numReq then
            return true
        end
    end
    return false
end