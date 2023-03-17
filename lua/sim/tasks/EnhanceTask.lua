--*****************************************************************************
--* File: lua/modules/EnhanceTask.lua
--*
--* Copyright Š 2008 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************
local ScriptTask = import("/lua/sim/scripttask.lua").ScriptTask
local TASKSTATUS = import("/lua/sim/scripttask.lua").TASKSTATUS
local AIRESULT = import("/lua/sim/scripttask.lua").AIRESULT

---@class EnhanceTask : ScriptTask
EnhanceTask = Class(ScriptTask) {

    ---@param self EnhanceTask
    ---@param commandData any
    OnCreate = function(self,commandData)
        ScriptTask.OnCreate(self,commandData)
        self:GetUnit():SetWorkProgress(0.0)
        self:GetUnit():SetUnitState('Enhancing',true)
        self:GetUnit():SetUnitState('Upgrading',true)
        self.LastProgress = 0
        ChangeState(self, self.Stopping)
    end,

    ---@param self EnhanceTask
    OnDestroy = function(self)
        self:GetUnit():SetUnitState('Enhancing',false)
        self:GetUnit():SetUnitState('Upgrading',false)
        self:GetUnit():SetWorkProgress(0.0)
        if self.Success then
            self:SetAIResult(AIRESULT.Success)
        else
            self:SetAIResult(AIRESULT.Fail)
            self:GetUnit():OnWorkFail(self.CommandData.Enhancement)
        end
    end,

    Stopping = State {
        TaskTick = function(self)
            local unit = self:GetUnit()

            if unit:IsMobile() and unit:IsMoving() then
                unit:GetNavigator():AbortMove()
                return TASKSTATUS.Wait
            else
                -- check if enhancement was started (not restricted and met prerequisite)
                local workStarted = unit:OnWorkBegin(self.CommandData.Enhancement)
                if not workStarted then
                    self.Success = false   -- required for AI notification
                    return TASKSTATUS.Done -- not using Abort because it will freeze the unit
                else
                    ChangeState(self, self.Enhancing)
                    return TASKSTATUS.Repeat
                end
            end
        end,
    },

    Enhancing = State {
        TaskTick = function(self)
            local unit = self:GetUnit()
            local current = unit.WorkProgress

            if not unit:IsPaused() then
                local obtained = unit:GetResourceConsumed()
                if obtained > 0 then
                    local frac = (1 / (unit.WorkItemBuildTime / unit:GetBuildRate())) * obtained * SecondsPerTick()
                    current = current + frac
                    unit.WorkProgress = current
                end
            end

            if((self.LastProgress < 0.25 and current >= 0.25) or
                (self.LastProgress < 0.50 and current >= 0.50) or
                (self.LastProgress < 0.75 and current >= 0.75)) then
                    unit:OnBuildProgress(self.LastProgress,current)
            end

            self.LastProgress = current
            unit:SetWorkProgress(current)

            if(current < 1.0) then
                return TASKSTATUS.Wait
            end

            unit:OnWorkEnd(self.CommandData.Enhancement)

            if unit:IsPaused() then
                unit:SetPaused(false)
            end

            self.Success = true

            return TASKSTATUS.Done
        end,
    },
}