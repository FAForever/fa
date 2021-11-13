#*****************************************************************************
#* File: lua/modules/EnhanceTask.lua
#*
#* Copyright Š 2008 Gas Powered Games, Inc.  All rights reserved.
#*****************************************************************************
local unit_methodsGetNavigator = moho.unit_methods.GetNavigator
local unit_methodsSetPaused = moho.unit_methods.SetPaused
local ScriptTask_MethodsGetUnit = moho.ScriptTask_Methods.GetUnit
local unit_methodsGetBuildRate = moho.unit_methods.GetBuildRate
local unit_methodsIsMobile = moho.unit_methods.IsMobile
local ScriptTask_MethodsSetAIResult = moho.ScriptTask_Methods.SetAIResult
local SecondsPerTick = SecondsPerTick
local unit_methodsSetWorkProgress = moho.unit_methods.SetWorkProgress
local unit_methodsIsPaused = moho.unit_methods.IsPaused
local unit_methodsGetResourceConsumed = moho.unit_methods.GetResourceConsumed

local ScriptTask = import('/lua/sim/ScriptTask.lua').ScriptTask
local TASKSTATUS = import('/lua/sim/ScriptTask.lua').TASKSTATUS
local AIRESULT = import('/lua/sim/ScriptTask.lua').AIRESULT

EnhanceTask = Class(ScriptTask) {
    OnCreate = function(self,commandData)
        ScriptTask.OnCreate(self,commandData)
        ScriptTask_MethodsGetUnit(self):SetWorkProgress(0.0)
        ScriptTask_MethodsGetUnit(self):SetUnitState('Enhancing',true)
        ScriptTask_MethodsGetUnit(self):SetUnitState('Upgrading',true)
        self.LastProgress = 0
        ChangeState(self, self.Stopping)
    end,

    OnDestroy = function(self)
        ScriptTask_MethodsGetUnit(self):SetUnitState('Enhancing',false)
        ScriptTask_MethodsGetUnit(self):SetUnitState('Upgrading',false)
        ScriptTask_MethodsGetUnit(self):SetWorkProgress(0.0)
        if self.Success then
            ScriptTask_MethodsSetAIResult(self, AIRESULT.Success)
        else
            ScriptTask_MethodsSetAIResult(self, AIRESULT.Fail)
            ScriptTask_MethodsGetUnit(self):OnWorkFail(self.CommandData.Enhancement)
        end
    end,

    Stopping = State {
        TaskTick = function(self)
            local unit = ScriptTask_MethodsGetUnit(self)

            if unit_methodsIsMobile(unit) and unit:IsMoving() then
                unit_methodsGetNavigator(unit):AbortMove()
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
            local unit = ScriptTask_MethodsGetUnit(self)
            local current = unit.WorkProgress

            if not unit_methodsIsPaused(unit) then
                local obtained = unit_methodsGetResourceConsumed(unit)
                if obtained > 0 then
                    local frac = (1 / (unit.WorkItemBuildTime / unit_methodsGetBuildRate(unit))) * obtained * SecondsPerTick()
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
            unit_methodsSetWorkProgress(unit, current)

            if(current < 1.0) then
                return TASKSTATUS.Wait
            end

            unit:OnWorkEnd(self.CommandData.Enhancement)

            if unit_methodsIsPaused(unit) then
                unit_methodsSetPaused(unit, false)
            end

            self.Success = true

            return TASKSTATUS.Done
        end,
    },
}
