--***************************************************************************
--*
--**  File     :  /lua/sim/Builder.lua
--**
--**  Summary  : Builder class
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AIUtils = import('/lua/ai/aiutilities.lua')

---- Root builder class
-- Builder Sped
-- {
--        Priority = integer,
--        BuilderName = string,
--        BuilderType = string,
--        BuilderData = table,
--        BuilderConditions = list of functions that return true/false, list of args,  { < function>, {<args>}}
-- }

Builder = Class {
    Create = function(self, brain, data, locationType)
        -- make sure the table of strings exist, they are required for the builder
        local verifyDictionary = { 'Priority', 'BuilderName' }
        for k,v in verifyDictionary do
            if not self:VerifyDataName(v, data) then return false end
        end

        self.Priority = data.Priority
        self.OriginalPriority = self.Priority

        self.Brain = brain

        self.BuilderName = data.BuilderName

        self.DelayEqualBuildPlattons = data.DelayEqualBuildPlattons

        self.ReportFailure = data.ReportFailure

        self:SetupBuilderConditions(data, locationType)

        self.BuilderStatus = false

        return true
    end,

    GetPriority = function(self)
        return self.Priority
    end,

    GetActivePriority = function(self)
        if Builders[self.BuilderName].ActivePriority then
            return Builders[self.BuilderName].ActivePriority
        end
        return false
    end,

    SetPriority = function(self, val, temporary, setbystrat)
        if temporary then
            self.OldPriority = self.Priority
            if setbystrat then
                self.SetByStrat = true
            end
        end
        if val ~= self.Priority then
            self.PriorityAltered = true
        end
        self.Priority = val
    end,

    ResetPriority = function(self)
        self.Priority = self.OldPriority
        self.SetByStrat = false
        self.OldPriority = nil
    end,

    CalculatePriority = function(self, builderManager)
        self.PriorityAltered = false
        if Builders[self.BuilderName].PriorityFunction then
            --LOG('Calculate new Priority '..self.BuilderName..' - '..self.Priority)
            local newPri = Builders[self.BuilderName]:PriorityFunction(self.Brain)
            if newPri ~= self.Priority then
                self.Priority = newPri
                self.PriorityAltered = true
            end
            --LOG('New Priority '..self.BuilderName..' - '..self.Priority)
        end
        return self.PriorityAltered
    end,

    AdjustPriority = function(self, val)
        self.Priority = self.Priority + val
    end,

    GetBuilderData = function(self, locationType, builderData)
        -- Get builder data out of the globals and convert data here
        local returnData = {}
        builderData = builderData or Builders[self.BuilderName].BuilderData
        for k,v in builderData do
            if type(v) == 'table' then
                returnData[k] = self:GetBuilderData(locationType, v)
            else
                if type(v) == 'string' and v == 'LocationType' then
                    returnData[k] = locationType
                else
                    returnData[k] = v
                end
            end
        end
        return returnData
    end,

    GetBuilderType = function(self)
        return Builders[self.BuilderName].BuilderType
    end,

    GetBuilderName = function(self)
        return self.BuilderName
    end,

    GetBuilderStatus = function(self)
        if self.GetStatusFunction then
            self.GetStatusFunction()
        end
        self:CheckBuilderConditions()
        return self.BuilderStatus
    end,

    GetPlatoonTemplate = function(self)
        if Builders[self.BuilderName].PlatoonTemplate then
            return Builders[self.BuilderName].PlatoonTemplate
        end
        return false
    end,

    GetPlatoonAIFunction = function(self)
        if Builders[self.BuilderName].PlatoonAIFunction then
            return Builders[self.BuilderName].PlatoonAIFunction
        end
        return false
    end,

    GetPlatoonAIPlan = function(self)
        if Builders[self.BuilderName].PlatoonAIPlan then
            return Builders[self.BuilderName].PlatoonAIPlan
        end
        return false
    end,

    GetPlatoonAddPlans = function(self)
        if Builders[self.BuilderName].PlatoonAddPlans then
            return Builders[self.BuilderName].PlatoonAddPlans
        end
        return false
    end,

    GetPlatoonAddFunctions = function(self)
        if Builders[self.BuilderName].PlatoonAddFunctions then
            return Builders[self.BuilderName].PlatoonAddFunctions
        end
        return false
    end,

    GetPlatoonAddBehaviors = function(self)
        if Builders[self.BuilderName].PlatoonAddBehaviors then
            return Builders[self.BuilderName].PlatoonAddBehaviors
        end
        return false
    end,

    BuilderConditionTest = function(self)
        for k,v in self.BuilderConditions do
            if not self.Brain.ConditionsMonitor:CheckKeyedCondition(v, self.ReportFailure) then
                self.BuilderStatus = false
                if self.ReportFailure then
                    LOG('*AI DEBUG: ' .. self.BuilderName .. ' - Failure Report Complete')
                end
                return false
            end
        end
        self.BuilderStatus = true
        return true
    end,

    SetupBuilderConditions = function(self, data, locationType)
        local tempConditions = {}
        if data.BuilderConditions then
            -- Convert location type here
            for k,v in data.BuilderConditions do
                local bCond = table.deepcopy(v)
                if type(bCond[1]) == 'function' then
                    for pNum,param in bCond[2] do
                        if param == 'LocationType' then
                            bCond[2][pNum] = locationType
                        end
                    end
                else
                    for pNum,param in bCond[3] do
                        if param == 'LocationType' then
                            bCond[3][pNum] = locationType
                        end
                    end
                end
                table.insert(tempConditions, self.Brain.ConditionsMonitor:AddCondition(unpack(bCond)))
            end
        end
        self.BuilderConditions = tempConditions
    end,

    CheckBuilderConditions = function(self)
        self:BuilderConditionTest(self.Brain)
    end,

    VerifyDataName = function(self, valueName, data)
        if not data[valueName] and not data.BuilderName then
            error('*BUILDER ERROR: Invalid builder data missing: ' .. valueName .. ' - BuilderName not given')
            return false
        elseif not data[valueName] then
            error('*BUILDER ERROR: Invalid builder data missing: ' .. valueName .. ' - BuilderName given: ' .. data.BuilderName)
            return false
        end
        return true
    end,
}

function CreateBuilder(brain, data, locationType)
    local builder = Builder()
    if builder:Create(brain, data, locationType) then
        return builder
    end
    return false
end

-- FactoryBuilderSpec
-- This is the spec to have built by a factory
--{
--   PlatoonTemplate = platoon template,
--   RequiresConstruction = true/false do I need to build this from a factory or should I just try to form it?,
--   PlatoonBuildCallbacks = {FunctionsToCallBack when the platoon starts to build}
--}

FactoryBuilder = Class(Builder) {
    Create = function(self,brain,data,locationType)
        Builder.Create(self,brain,data,locationType)

        local verifyDictionary = { 'PlatoonTemplate', }
        for k,v in verifyDictionary do
            if not self:VerifyDataName(v, data) then return false end
        end
        return true
    end,
}

function CreateFactoryBuilder(brain, data, locationType)
    local builder = FactoryBuilder()
    if builder:Create(brain, data, locationType) then
        return builder
    end
    return false
end

-- PlatoonBuilderSpec
--{
--   PlatoonTemplate = platoon template,
--   InstanceCount = number of active platoons available,
--   PlatoonBuildCallbacks = { functions to call when platoon is formed }
--   PlatoonAIFunction = function the platoon uses when formed,
--   PlatoonAddFunctions = { other functions to run when platoon is formed }
--}

PlatoonBuilder = Class(Builder) {
    Create = function(self,brain,data,locationType)
        Builder.Create(self,brain,data,locationType)

        local verifyDictionary = { 'PlatoonTemplate', }
        for k,v in verifyDictionary do
            if not self:VerifyDataName(v, data) then return false end
        end

        -- Setup for instances to be stored inside a table rather than creating new
        self.InstanceCount = {}
        local num = 1
        while num <= (data.InstanceCount or 1) do
            table.insert(self.InstanceCount, { Status = 'Available', PlatoonHandle = false })
            num = num + 1
        end
        return true
    end,

    FormDebug = function(self)
        if self.FormDebugFunction then
            self.FormDebugFunction()
        end
    end,

    CheckInstanceCount = function(self)
        for k,v in self.InstanceCount do
            if v.Status == 'Available' then
                return true
            end
        end
        return false
    end,

    GetFormRadius = function(self)
        if Builders[self.BuilderName].FormRadius then
            return Builders[self.BuilderName].FormRadius
        end
        return false
    end,

    StoreHandle = function(self,platoon)
        for k,v in self.InstanceCount do
            if v.Status == 'Available' then
                v.Status = 'ActivePlatoon'
                v.PlatoonHandle = platoon

                platoon.BuilderHandle = self
                platoon.InstanceNumber = k
                local destroyedCallback = function(brain,platoon)
                    if platoon.BuilderHandle then
                        platoon.BuilderHandle:RemoveHandle(platoon)
                    end
                end
                platoon:AddDestroyCallback(destroyedCallback)
                break
            end
        end
    end,

    RemoveHandle = function(self,platoon)
        self.InstanceCount[platoon.InstanceNumber].Status = 'Available'
        self.InstanceCount[platoon.InstanceNumber].PlatoonHandle = false
        platoon.BuilderHandle = nil
    end,
}

function CreatePlatoonBuilder(brain, data, locationType)
    local builder = PlatoonBuilder()
    if builder:Create(brain, data, locationType) then
        return builder
    end
    return false
end

-- EngineerBuilderSpec
-- This is the spec to have built by a factory
--{
--   PlatoonBuildCallbacks = {FunctionsToCallBack when the platoon starts to build}
--   BuilderData = {
--       Construction = {
--           BaseTemplate = basetemplates, must contain templates for all 3 factions it will be viewed by faction index,
--           BuildingTemplate = building templates, contain templates for all 3 factions it will be viewed by faction index,
--           BuildClose = true/false do I follow the table order or do build the best spot near me?
--           BuildRelative = true/false are the build coordinates relative to the starting location or absolute coords?,
--           BuildStructures = { List of structure types and the order to build them.}
--       }
--   }
--}

EngineerBuilder = Class(PlatoonBuilder) {
    Create = function(self,brain,data, locationType)
        PlatoonBuilder.Create(self,brain,data, locationType)

        self.EconomyCost = { Mass = 0, Energy = 0 }

        return true
    end,

    FormDebug = function(self)
        if self.FormDebugFunction then
            self.FormDebugFunction()
        end
    end,
}

function CreateEngineerBuilder(brain, data, locationType)
    local builder = EngineerBuilder()
    if builder:Create(brain, data, locationType) then
        return builder
    end
    return false
end

