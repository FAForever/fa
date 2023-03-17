--****************************************************************************
--**
--**  File     :  /lua/editor/PlatoonCountBuildConditions.lua
--**  Author(s): Dru Staltman, John Comes
--**
--**  Summary  : Generic AI Platoon Build Conditions
--**             Build conditions always return true or false
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

---@param aiBrain AIBrain
---@param name string
---@param varName string
---@return boolean
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

---@param aiBrain AIBrain
---@param name string
---@param varName string
---@return boolean
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

---@param aiBrain AIBrain
---@param name1 string
---@param name2 string
---@return boolean
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

---@param aiBrain AIBrain
---@param name1 string
---@param name2 string
---@return boolean
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

---@param aiBrain AIBrain
---@param name string
---@param varName string
---@return boolean
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

---@param aiBrain AIBrain
---@param name string
---@param varName string
---@return boolean
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

---@param aiBrain AIBrain
---@param name string
---@param num number
---@return boolean
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

---@param aiBrain AIBrain
---@param name string
---@param num number
---@return boolean
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

---@param aiBrain AIBrain
---@param name string
---@param num number
---@return boolean
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

---@param aiBrain AIBrain
---@param name string
---@param num number
---@return boolean
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

---@param aiBrain AIBrain
---@param builderName string
---@param num number
---@return boolean
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

---@param aiBrain AIBrain
---@param builderName string
---@param num number
---@return boolean
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

-- Moved Unsused Imports to bottom for mod support
local AIUtils = import("/lua/ai/aiutilities.lua")
local ScenarioFramework = import("/lua/scenarioframework.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")