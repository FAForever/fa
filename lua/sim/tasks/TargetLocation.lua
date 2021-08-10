--*****************************************************************************
--* File: lua/TargetLocation.lua
--*
--* Copyright � 2008 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************
local ScriptTask = import('/lua/sim/ScriptTask.lua').ScriptTask
local TASKSTATUS = import('/lua/sim/ScriptTask.lua').TASKSTATUS
local AIRESULT = import('/lua/sim/ScriptTask.lua').AIRESULT

TargetLocation = Class(ScriptTask) {
    
    OnCreate = function(self,commandData)
        ScriptTask.OnCreate(self,commandData)
        local unit = self:GetUnit():OnTargetLocation(commandData.Location)
    end,
    
    TaskTick = function(self)
        self:SetAIResult(AIRESULT.Success)
        return TASKSTATUS.Done
    end,

    IsInRange = function(self)
        return true
    end,
}
