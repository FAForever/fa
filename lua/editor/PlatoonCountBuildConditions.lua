--****************************************************************************
--**
--**  File     :  /lua/editor/PlatoonCountBuildConditions.lua
--**  Author(s): Dru Staltman, John Comes
--**
--**  Summary  : Generic AI Platoon Build Conditions
--**             Build conditions always return true or false
--**
--**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local AIUtils = import('/lua/ai/aiutilities.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: AMPlatoonsGreaterOrEqualVarTable = BuildCondition	doc = "Please work function docs."
-- 
-- parameter 0: string	aiBrain		= "default_brain"		
-- parameter 1: string	name		= "DefaultGroupAir"		doc = "docs for param1"
-- parameter 2: string	varName		= "VarName"			    doc = "VarTableName"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function AMPlatoonsGreaterOrEqualVarTable(aiBrain, name, varName)
    local counter = 0
    local num
    
    if ScenarioInfo.VarTable then
        if ScenarioInfo.VarTable[varName] then
            num = ScenarioInfo.VarTable[varName]
            if aiBrain.AttackData.AMPlatoonCount[name] then
                counter = aiBrain.AttackData.AMPlatoonCount[name]
            end
            if counter >= num then
                return true
            end
        end
    end
    return false
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: AMPlatoonsLessThanVarTable = BuildCondition	doc = "Please work function docs."
-- 
-- parameter 0: string	aiBrain		= "default_brain"		
-- parameter 1: string	name		= "DefaultGroupAir"		doc = "docs for param1"
-- parameter 2: string	varName		= "VarName"			    doc = "VarTableName"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function AMPlatoonsLessThanVarTable(aiBrain, name, varName)
    local platoonList = aiBrain:GetPlatoonsList()
    local counter = 0
    local num
    
    if ScenarioInfo.VarTable then
        if ScenarioInfo.VarTable[varName] then
            num = ScenarioInfo.VarTable[varName]
            if aiBrain.AttackData.AMPlatoonCount[name] then
                counter = aiBrain.AttackData.AMPlatoonCount[name]
            end
            if counter < num then
                return true
            end
        end
    end

    return false

end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: NumBuilderPlatoonsGreaterOrEqualNumBuilderPlatoons = BuildCondition	doc = "Please work function docs."
-- 
-- parameter 0: string	aiBrain		= "default_brain"		
-- parameter 1: string	name1		= "Builder1Name"	   	doc = "docs for param1"
-- parameter 2: string	name2		= "Builder2Name"	   	doc = "docs for param2"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function NumBuilderPlatoonsGreaterOrEqualNumBuilderPlatoons(aiBrain, name1, name2)
    local builder1Count = 0
    local builder2Count = 0

    if aiBrain.PlatoonNameCounter[name1] then
        builder1Count = aiBrain.PlatoonNameCounter[name1]
    end
    if aiBrain.PlatoonNameCounter[name2] then
        builder2Count = aiBrain.PlatoonNameCounter[name2]
    end
    if builder1Count >= builder2Count then
        return true
    else
        return false
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: NumBuilderPlatoonsLessThanNumBuilderPlatoons = BuildCondition	doc = "Please work function docs."
-- 
-- parameter 0: string	aiBrain		= "default_brain"		
-- parameter 1: string	name1		= "Builder1Name"	   	doc = "docs for param1"
-- parameter 2: string	name2		= "Builder2Name"	   	doc = "docs for param2"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function NumBuilderPlatoonsLessThanNumBuilderPlatoons(aiBrain, name1, name2)
    local builder1Count = 0
    local builder2Count = 0

    if aiBrain.PlatoonNameCounter[name1] then
        builder1Count = aiBrain.PlatoonNameCounter[name1]
    end
    if aiBrain.PlatoonNameCounter[name2] then
        builder2Count = aiBrain.PlatoonNameCounter[name2]
    end
    if builder1Count < builder2Count then
        return true
    else
        return false
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: NumBuilderPlatoonsGreaterOrEqualVarTable = BuildCondition	doc = "Please work function docs."
-- 
-- parameter 0: string	aiBrain		= "default_brain"		
-- parameter 1: string	name		= "BuilderName"	    	doc = "docs for param1"
-- parameter 2: string	varName		= "VarName"			    doc = "VarTableName"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function NumBuilderPlatoonsGreaterOrEqualVarTable(aiBrain, name, varName)
    local platoonList = aiBrain:GetPlatoonsList()
    local counter = 0
    local num
    
    if ScenarioInfo.VarTable then
        if ScenarioInfo.VarTable[varName] then
            num = ScenarioInfo.VarTable[varName]
            if aiBrain.PlatoonNameCounter[name] then
                counter = aiBrain.PlatoonNameCounter[name]
            end
            if counter >= num then
                return true
            end
        end
    end
    return false
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: NumBuilderPlatoonsLessThanVarTable = BuildCondition	doc = "Please work function docs."
-- 
-- parameter 0: string	aiBrain		= "default_brain"		
-- parameter 1: string	name		= "BuilderName"		    doc = "docs for param1"
-- parameter 2: string	varName		= "VarName"			    doc = "VarTableName"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function NumBuilderPlatoonsLessThanVarTable(aiBrain, name, varName)
    local platoonList = aiBrain:GetPlatoonsList()
    local counter = 0
    local num
    
    if ScenarioInfo.VarTable then
        if ScenarioInfo.VarTable[varName] then
            num = ScenarioInfo.VarTable[varName]
            if aiBrain.PlatoonNameCounter[name] then
                counter = aiBrain.PlatoonNameCounter[name]
            end
            if counter < num then
                return true
            end
        end
    end
    return false
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: NumGreaterOrEqualAMPlatoons = BuildCondition	doc = "Please work function docs."
-- 
-- parameter 0: string	aiBrain		= "default_brain"		
-- parameter 1: string	name		= "DefaultGroupAir"		doc = "docs for param1"
-- parameter 2: int	num		= 1				doc = "param2 docs"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function NumGreaterOrEqualAMPlatoons(aiBrain, name, num)
    local count
    if aiBrain.AttackData.AMPlatoonCount[name] then
        count = aiBrain.AttackData.AMPlatoonCount[name]
    else
        return false
    end
    if count >= num then 
        return true
    else
        return false
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: NumGreaterAMPlatoons = BuildCondition	doc = "Please work function docs."
-- 
-- parameter 0: string	aiBrain		= "default_brain"		
-- parameter 1: string	name		= "DefaultGroupAir"		doc = "docs for param1"
-- parameter 2: int	num		= 1				doc = "param2 docs"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function NumGreaterAMPlatoons(aiBrain, name, num)
    local count
    if aiBrain.AttackData.AMPlatoonCount[name] then
        count = aiBrain.AttackData.AMPlatoonCount[name]
    else
        return false
    end
    if count > num then 
        return true
    else
        return false
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: NumLessOrEqualAMPlatoons = BuildCondition	doc = "Please work function docs."
-- 
-- parameter 0: string	aiBrain		= "default_brain"		
-- parameter 1: string	name		= "DefaultGroupAir"		doc = "docs for param1"
-- parameter 2: int	num		= 1				doc = "param2 docs"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function NumLessOrEqualAMPlatoons(aiBrain, name, num)
    local count
    if aiBrain.AttackData.AMPlatoonCount[name] then
        count = aiBrain.AttackData.AMPlatoonCount[name]
    else
        return true
    end
    if count <= num then 
        return true
    else
        return false
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: NumLessAMPlatoons = BuildCondition	doc = "Please work function docs."
-- 
-- parameter 0: string	aiBrain		= "default_brain"		
-- parameter 1: string	name		= "DefaultGroupAir"		doc = "docs for param1"
-- parameter 2: int	num		= 1				doc = "param2 docs"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function NumLessAMPlatoons(aiBrain, name, num)
    local count
    if aiBrain.AttackData.AMPlatoonCount[name] then
        count = aiBrain.AttackData.AMPlatoonCount[name]
    else
        return true
    end
    if count < num then 
        return true
    else
        return false
    end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: NumBuildersLessThanOSCounter = BuildCondition	doc = "Please work function docs."
-- 
-- parameter 0: string	aiBrain		= "default_brain"		
-- parameter 1: string	builderName	= "default_builder_name"		    doc = "docs for param1"
-- parameter 2: int      num             = "1"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function NumBuildersLessThanOSCounter(aiBrain, builderName, num)
    local counter = 0
    
    if ScenarioInfo.OSPlatoonCounter and ScenarioInfo.Options.Difficulty then
        if ScenarioInfo.OSPlatoonCounter[builderName .. '_D' .. ScenarioInfo.Options.Difficulty] then
            num = ScenarioInfo.OSPlatoonCounter[builderName .. '_D' .. ScenarioInfo.Options.Difficulty]
        end
        if aiBrain.PlatoonNameCounter[builderName] then
            counter = aiBrain.PlatoonNameCounter[builderName]
        end
        if counter < num then
            return true
        end
    end
    return false
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function: NumBuildersGreaterThanEqualOSCounter = BuildCondition	doc = "Please work function docs."
-- 
-- parameter 0: string	aiBrain		= "default_brain"		
-- parameter 1: string	builderName	= "default_builder_name"		    doc = "docs for param1"
-- parameter 2: int      num             = "1"
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function NumBuildersGreaterThanEqualOSCounter(aiBrain, builderName, num)
    local counter = 0
    
    if ScenarioInfo.OSPlatoonCounter and ScenarioInfo.Options.Difficulty then
        if ScenarioInfo.OSPlatoonCounter[builderName .. '_D' .. ScenarioInfo.Options.Difficulty] then
            num = ScenarioInfo.OSPlatoonCounter[builderName .. '_D' .. ScenarioInfo.Options.Difficulty]
        end
        if aiBrain.PlatoonNameCounter[builderName] then
            counter = aiBrain.PlatoonNameCounter[builderName]
        end
        if counter >= num then
            return true
        end
    end
    return false
end

