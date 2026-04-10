--*****************************************************************************
--* File: lua/TargetLocation.lua
--*
--* Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local ScriptTask = import("/lua/sim/scripttask.lua").ScriptTask
local TASKSTATUS = import("/lua/sim/scripttask.lua").TASKSTATUS
local AIRESULT = import("/lua/sim/scripttask.lua").AIRESULT

---@class TargetLocationTask : ScriptTask
---@field CommandData { TaskName: "TargetLocation", UserValidated: boolean, Location: Vector } # LuaParams table from `UserScriptCommand`. This table is shared by all units ordered the task from one command.
---@field GetUnit fun(self: TargetLocationTask): RemoteViewingUnit
TargetLocation = Class(ScriptTask) {

    --- Called immediately when task is created
    ---@param self TargetLocationTask
    ---@param commandData { TaskName: "TargetLocation", UserValidated: boolean, Location: Vector } # LuaParams table from `UserScriptCommand`. This table is shared by all units ordered the task from one command.
    OnCreate = function(self, commandData)
        ScriptTask.OnCreate(self, commandData)
        self:GetUnit():OnTargetLocation(commandData.Location)
    end,

    --- Called by the engine at an interval determined by the returned TaskStatus value
    ---@param self TargetLocationTask
    ---@return ScriptTaskStatus
    TaskTick = function(self)
        self:SetAIResult(AIRESULT.Success)
        return TASKSTATUS.Done
    end,

    ---@param self TargetLocationTask
    ---@return true
    IsInRange = function(self)
        return true
    end,
}
