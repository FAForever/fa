--*****************************************************************************
--* File: lua/modules/ScriptTask.lua
--*
--* Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

-- Task status values returned from TaskTick(). Note that an integer cast to
-- ETaskStatus means to wait that many ticks before returning. TASKSTATUS_Repeat
-- is equivalent to waiting 0 ticks. Do not modify this as this is a reflection of
-- the internal task codes used by the engine.
TASKSTATUS = {
    -- Task has completed and can be removed from the task stack; it will be
    -- popped and deleted automatically. Execution will immediately continue
    -- with the task's parent.
    -- You can also use TASKSTATUS_Done to do a tail call, by first pushing
    -- the task to switch to and then returning TASKSTATUS_Done.
    Done = -1,

    -- move task's thread onto >ed list; some external event will
    -- reactivate it.
    Suspend = -2,

    -- kill all tasks on this thread
    Abort = -3,

    -- reschedule the ticking of this task until the rest of the tasks have been
    -- ticked (puts it at the end of the list)
    Delay = -4,

    -- task needs to repeat execution immediately, usually caused by a change
    -- in the task stack
    Repeat = 0,

    -- Task is done with its execution for this tick, but should be called back
    -- on the next tick.
    Wait = 1,
    
    -- Returning a number greater than TASKSTATUS_Wait incdicates an additional
    -- number of ticks to wait. For example:
    --    return TASKSTATUS_Wait + 3
    -- This indicates a wait of 4 ticks.
}

AIRESULT = {
    -- Command in progress; result has not been set yet
    Unknown=0,

    -- Successfully carried out the order.
    Success=1,

    -- Failed to carry out the order.
    Fail=2,

    -- The order made no sense for this type of unit, and was ignored.
    Ignored=3,
}

---@class ScriptTask : moho.ScriptTask_Methods
ScriptTask = Class(moho.ScriptTask_Methods) {

    -- Called immediately when task is created
    ---@param self ScriptTask
    ---@param commandData any
    OnCreate = function(self,commandData)
        self.CommandData = commandData
    end,

    -- Called by the engine every tick. Function must return a value in TaskStatus
    ---@param self ScriptTask
    ---@return integer
    TaskTick = function(self)
        LOG('tick')
        self:SetAIResult(AIRESULT.Fail)
        error('ScriptTask.TaskTick called. Did you forget to add TaskName to your command lua param table?')
        return TASKSTATUS.Done
    end,

    -- Called by the engine when the task is destroyed. This could be it naturally going away after completion or because it was cancelled by another task.
    ---@param self ScriptTask
    OnDestroy = function(self)
    end,
}