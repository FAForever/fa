#*****************************************************************************
#* File: lua/TargetLocation.lua
#*
#* Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
#*****************************************************************************
local ScriptTask_MethodsGetUnit = moho.ScriptTask_Methods.GetUnit
local ScriptTask_MethodsSetAIResult = moho.ScriptTask_Methods.SetAIResult

local ScriptTask = import('/lua/sim/ScriptTask.lua').ScriptTask
local TASKSTATUS = import('/lua/sim/ScriptTask.lua').TASKSTATUS
local AIRESULT = import('/lua/sim/ScriptTask.lua').AIRESULT

TargetLocation = Class(ScriptTask) {
    
    OnCreate = function(self,commandData)
        ScriptTask.OnCreate(self,commandData)
        local unit = ScriptTask_MethodsGetUnit(self):OnTargetLocation(commandData.Location)
    end,
    
    TaskTick = function(self)
        ScriptTask_MethodsSetAIResult(self, AIRESULT.Success)
        return TASKSTATUS.Done
    end,

    IsInRange = function(self)
        return true
    end,
}
