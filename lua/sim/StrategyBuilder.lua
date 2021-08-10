--***************************************************************************
--*
--**  File     :  /lua/sim/StrategyBuilder.lua
--**
--**  Summary  : Strategy Builder class
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AIUtils = import('/lua/ai/aiutilities.lua')
local Builder = import('/lua/sim/Builder.lua').Builder


-- StrategyBuilderSpec
-- This is the spec to have analyzed by the StrategyManager
--{
--   BuilderData = {
--       Some stuff could go here, eventually.
--   }
--}

StrategyBuilder = Class(Builder) {
    Create = function(self,brain,data,locationType)
        Builder.Create(self,brain,data,locationType)
        self:SetStrategyActive(false)
        return true
    end,

    SetStrategyActive = function(self, bool)
        if bool then
            self.Active = true
            if Builders[self.BuilderName].OnStrategyActivate then
                Builders[self.BuilderName]:OnStrategyActivate(self.Brain)
            end
        else
            self.Active = false
            if Builders[self.BuilderName].OnStrategyDeactivate then
                Builders[self.BuilderName]:OnStrategyDeactivate(self.Brain)
            end
        end
    end,

    IsStrategyActive = function(self)
        return self.Active
    end,

    GetActivateBuilders = function(self)
        if Builders[self.BuilderName].AddBuilders then
            return Builders[self.BuilderName].AddBuilders
        end
        return false
    end,

    GetRemoveBuilders = function(self)
        if Builders[self.BuilderName].RemoveBuilders then
            return Builders[self.BuilderName].RemoveBuilders
        end
        return false
    end,

    GetStrategyTime = function(self)
        if Builders[self.BuilderName].StrategyTime then
            return Builders[self.BuilderName].StrategyTime
        end
        return false
    end,

    IsInterruptStrategy = function(self)
        if Builders[self.BuilderName].InterruptStrategy then
            return true
        end
        return false
    end,

    GetStrategyType = function(self)
        if Builders[self.BuilderName].StrategyType then
            return Builders[self.BuilderName].StrategyType
        end
        return false
    end,

    CalculatePriority = function(self, builderManager)
        self.PriorityAltered = false
        -- Builders can have a function to update the priority
        if Builders[self.BuilderName].PriorityFunction then
            local newPri = Builders[self.BuilderName]:PriorityFunction(self.Brain)
            if newPri > 100 then
                newPri = 100
            elseif newPri < 0 then
                newPri = 0
            end
            if newPri != self.Priority then
                self.Priority = newPri
                self.SetByStrat = true
                self.PriorityAltered = true
            end
        end

        -- Returns true if a priority change happened
        local returnVal = self.PriorityAltered
        return returnVal
    end,
}

function CreateStrategy(brain, data, locationType)
    local builder = StrategyBuilder()
    if builder:Create(brain, data, locationType) then
        return builder
    end
    return false
end
