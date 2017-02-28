--*****************************************************************************
--* File: lua/sim/tasks/AttackMove.lua
--*
--* Dummy task for the Attack Move button
--*****************************************************************************
local ScriptTask = import('/lua/sim/ScriptTask.lua').ScriptTask
local TASKSTATUS = import('/lua/sim/ScriptTask.lua').TASKSTATUS
local AIRESULT = import('/lua/sim/ScriptTask.lua').AIRESULT

AttackMove = Class(ScriptTask) {
    
    OnCreate = function(self,commandData)
        ScriptTask.OnCreate(self,commandData)
    end,
    
    TaskTick = function(self)
        self:SetAIResult(AIRESULT.Success)
        return TASKSTATUS.Done
    end,

    IsInRange = function(self)
        return true
    end,
}
