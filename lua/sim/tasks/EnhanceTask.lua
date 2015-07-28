#*****************************************************************************
#* File: lua/modules/EnhanceTask.lua
#*
#* Copyright Š 2008 Gas Powered Games, Inc.  All rights reserved.
#*****************************************************************************
local ScriptTask = import('/lua/sim/ScriptTask.lua').ScriptTask
local TASKSTATUS = import('/lua/sim/ScriptTask.lua').TASKSTATUS
local AIRESULT = import('/lua/sim/ScriptTask.lua').AIRESULT

EnhanceTask = Class(ScriptTask) {
    OnCreate = function(self,commandData)
        ScriptTask.OnCreate(self,commandData)
        self:GetUnit():SetWorkProgress(0.0)
        self:GetUnit():SetUnitState('Enhancing',true)
        self:GetUnit():SetUnitState('Upgrading',true)
        self.LastProgress = 0
        self.LastUnpause = 0
        ChangeState(self, self.Stopping)
    end,

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
                unit:OnWorkBegin(self.CommandData.Enhancement)
                ChangeState(self, self.Enhancing)
                return TASKSTATUS.Repeat
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
                    local frac = ( 1 / ( unit.WorkItemBuildTime / unit:GetBuildRate()) ) * obtained * SecondsPerTick()
                    current = current + frac
                    unit.WorkProgress = current
                end
            else
                local tick = GetGameTick()

                if self.LastUnpause + 5 < tick then
                    local guards = EntityCategoryFilterDown(categories.ENGINEER, unit:GetGuards())

                    for _, guard in guards do
                        if not (guard:IsMoving() or guard:GetFocusUnit()) then
                            self.LastUnpause = tick
                            unit:SetPaused(false)

                            ForkThread(function()
                                unit:SetPaused(true)
                            end)
                        end
                        break
                    end
                end
            end

            if( ( self.LastProgress < 0.25 and current >= 0.25 ) or
                ( self.LastProgress < 0.50 and current >= 0.50 ) or
                ( self.LastProgress < 0.75 and current >= 0.75 ) ) then
                    unit:OnBuildProgress(self.LastProgress,current)
            end

            self.LastProgress = current
            unit:SetWorkProgress(current)

            if( current < 1.0 ) then
                return TASKSTATUS.Wait
            end

            unit:OnWorkEnd(self.CommandData.Enhancement)
            self.Success = true

            return TASKSTATUS.Done
        end,
    },
}
