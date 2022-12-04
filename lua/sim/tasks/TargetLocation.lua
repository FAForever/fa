--*****************************************************************************
--* File: lua/TargetLocation.lua
--*
--* Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************
local ScriptTask = import("/lua/sim/scripttask.lua").ScriptTask
local TASKSTATUS = import("/lua/sim/scripttask.lua").TASKSTATUS
local AIRESULT = import("/lua/sim/scripttask.lua").AIRESULT

---@class TargetLocation : ScriptTask
TargetLocation = Class(ScriptTask) {

    ---@param self TargetLocation
    ---@param commandData table
    OnCreate = function(self,commandData)
        ScriptTask.OnCreate(self,commandData)
        local unit = self:GetUnit():OnTargetLocation(commandData.Location)
    end,

    ---@param self TargetLocation
    ---@return number
    TaskTick = function(self)
        self:SetAIResult(AIRESULT.Success)
        return TASKSTATUS.Done
    end,

    ---@param self TargetLocation
    ---@return boolean
    IsInRange = function(self)
        return true
    end,
}