#***************************************************************************
#*
#**  File     :  /lua/sim/StrategyManager.lua
#**
#**  Summary  : Manage Skirmish Strategies
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved. All lefts reserved too.
#****************************************************************************

local BuilderManager = import('/lua/sim/BuilderManager.lua').BuilderManager
local AIUtils = import('/lua/ai/aiutilities.lua')
local Builder = import('/lua/sim/Builder.lua')
local StrategyBuilder = import('/lua/sim/StrategyBuilder.lua')
local AIBuildUnits = import('/lua/ai/aibuildunits.lua')
#local StrategyList = import('/lua/ai/SkirmishStrategyList.lua').StrategyList
local AIAddBuilderTable = import('/lua/ai/AIAddBuilderTable.lua')
local SUtils = import('/lua/AI/sorianutilities.lua')

StrategyManager = Class(BuilderManager) {
    Create = function(self, brain, lType, location, radius, useCenterPoint)
        BuilderManager.Create(self,brain)

        self.Location = location
        self.Radius = radius
        self.LocationType = lType

        self.LastChange = 0
        self.NextChange = 300
        self.LastStrategy = false
        self.OverallStrategy = false
        self.OverallPriority = 0

        self.UseCenterPoint = useCenterPoint or false

        self:AddBuilderType('Any')

        #self:LoadStrategies()
    end,

    AddBuilder = function(self, builderData, locationType, builderType)
        local newBuilder = StrategyBuilder.CreateStrategy(self.Brain, builderData, locationType)
        self:AddInstancedBuilder(newBuilder, builderType)
        return newBuilder
    end,

    # Load all strategies in the Strategy List table
    LoadStrategies = function(self)
        for i,v in StrategyList do
            self:AddBuilder(v)
        end
    end,

    ExecuteChanges = function(self, builder)
        local turnOff = builder:GetRemoveBuilders()
        local turnOn = builder:GetActivateBuilders()
        for mname, manager in turnOff do
            for _, bname in manager do
                local Managers = self.Brain.BuilderManagers[self.LocationType]
                Managers[mname]:SetBuilderPriority(bname, 0.1, true, true)
            end
        end
        for mname, manager in turnOn do
            for _, bname in manager do
                local Managers = self.Brain.BuilderManagers[self.LocationType]
                local newPriority = Managers[mname]:GetActivePriority(bname)
                Managers[mname]:SetBuilderPriority(bname, newPriority)
            end
        end
        builder:SetStrategyActive(true)
    end,

    UndoChanges = function(self, builder)
        local turnOn = builder:GetRemoveBuilders()
        local turnOff = builder:GetActivateBuilders()
        for mname, manager in turnOff do
            for _, bname in manager do
                local Managers = self.Brain.BuilderManagers[self.LocationType]
                Managers[mname]:SetBuilderPriority(bname, 0)
            end
        end
        for mname, manager in turnOn do
            for _, bname in manager do
                local Managers = self.Brain.BuilderManagers[self.LocationType]
                Managers[mname]:ResetBuilderPriority(bname)
            end
        end
        builder:SetStrategyActive(false)
    end,

    ManagerLoopBody = function(self,builder,bType)
        BuilderManager.ManagerLoopBody(self,builder,bType)

        if builder.Priority >= 70 and builder:GetBuilderStatus() and not builder:IsStrategyActive() then
            #LOG('*AI DEBUG: '..self.Brain.Nickname..' '..SUtils.TimeConvert(GetGameTimeSeconds())..' Activating Strategy: '..builder.BuilderName..' Priority: '..builder.Priority)
            self:ExecuteChanges(builder)
        elseif (builder.Priority < 70 or not builder:GetBuilderStatus()) and builder:IsStrategyActive() then
            #LOG('*AI DEBUG: '..self.Brain.Nickname..' '..SUtils.TimeConvert(GetGameTimeSeconds())..' Deactivating Strategy: '..builder.BuilderName..' Priority: '..builder.Priority)
            self:UndoChanges(builder)
        end
    end,
}

function CreateStrategyManager(brain, lType, location, radius, useCenterPoint)
    local stratman = StrategyManager()
    stratman:Create(brain, lType, location, radius, useCenterPoint)
    return stratman
end
