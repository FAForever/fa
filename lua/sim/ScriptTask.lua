--*****************************************************************************
--* File: lua/modules/ScriptTask.lua
--*
--* Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

-- Task status values returned from TaskTick(). Do not modify this as this is a reflection of the internal task codes used by the engine.
---@alias ScriptTaskStatus
---| -1 # Done: The task is destroyed and then the unit proceeds to the next command.
---| -2 # Suspend: the thread is suspended but there is no way implemented to resume it?
---| -3 # Abort: "kill all tasks on this thread". Not implemented, usage will cause the unit to be stuck on the command.
---| -4 # Delay: move task to end of this tick's task queue. There is no way to have multiple tasks per tick?
---| 0 # Repeat execution immediately.
---| 1+ # 1+: The task waits the given number of ticks. For example, the value `3` means the task waits for three ticks.
---| number

--- Task status values returned from TaskTick(). Do not modify this as this is a reflection of the internal task codes used by the engine.
TASKSTATUS = {
    ---"Task has completed and can be removed from the task stack; it will be
    --- popped and deleted automatically. Execution will immediately continue
    --- with the task's parent.
    --- You can also use TASKSTATUS_Done to do a tail call, by first pushing
    --- the task to switch to and then returning TASKSTATUS_Done." - Seems unimplemented.

    ---The task counts as completed and is destroyed by the engine. Then the unit proceeds to the next command in the command queue.
    Done = -1,

    --- The task's thread suspends, but there is no implementation to resume it?  
    --- The unit waits forever on the command but the command can be cleared manually to resume the unit.
    Suspend = -2,

    --- The task aborts: "kill all tasks on this thread".  
    --- Not implemented, usage will cause the unit to be stuck on the command.
    Abort = -3,

    --- The task delays: It is moved to the end of the this tick's task queue and is executed after all other tasks.  
    --- There is no way to have multiple tasks in 1 tick?
    Delay = -4,

    --- The task repeats and executes immediately again.  
    --- You can use this right after changing the state of a task.
    Repeat = 0,

    --- The task waits the given number of ticks. For example, the value `3` means the task waits for three ticks.
    Wait = 1,
}

---@alias ScriptTaskAIResult
---| 0 # Unknown: The unit is performing the task.
---| 1 # Success: The unit succesfully completed the task.
---| 2 # Fail: The unit failed to carry out the order.
---| 3 # Ignored: The unit is unable to carry out the order.

--- Task results for ScriptTask:SetAIResult(). Do not modify this as this is a reflection of
--- the internal task codes used by the engine.
AIRESULT = {
    -- The unit is performing the task.
    Unknown = 0,

    -- The unit succesfully completed the task.
    Success = 1,

    -- The unit failed to carry out the order.
    Fail = 2,

    -- The unit is unable to carry out the order.
    Ignored = 3,
}

---@class ScriptTask : moho.ScriptTask_Methods
---@field CommandData { TaskName: string } | table # LuaParams table from the user side. This table is shared by all units ordered the task from one command.
ScriptTask = Class(moho.ScriptTask_Methods) {

    --- Called immediately when task is created
    ---@param self ScriptTask
    ---@param commandData { TaskName: string } | table # LuaParams table from the user side. This table is shared by all units ordered the task from one command.
    OnCreate = function(self, commandData)
        self.CommandData = commandData
    end,

    --- Called by the engine at an interval determined by the returned TaskStatus value
    ---@param self ScriptTask
    ---@return ScriptTaskStatus
    TaskTick = function(self)
        LOG('tick')
        self:SetAIResult(AIRESULT.Fail)
        error('ScriptTask.TaskTick called. Did you forget to add TaskName to your command lua param table?')
        return TASKSTATUS.Done
    end,

    --- Called by the engine when the task is destroyed. This could be it naturally going away after completion or because it was cancelled by another task.
    ---@param self ScriptTask
    OnDestroy = function(self)
    end,
}
