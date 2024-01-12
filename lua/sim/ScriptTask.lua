--******************************************************************************************************
--** Copyright (c) 2024 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

--- Task status values returned from TaskTick(). Do not modify this as this is a reflection of
--- the internal task codes used by the engine.
---@alias ScriptedTaskStatus
--- Done; Task has completed and can be removed from the task stack; it will be
--- popped and deleted automatically. Execution will immediately continue
--- with the task's parent.
--- You can also use TASKSTATUS_Done to do a tail call, by first pushing
--- the task to switch to and then returning TASKSTATUS_Done.
--- | -1
--- | -2 # Suspend (not functional)
--- Abort; Destroy all tasks on this thread
--- | -3
--- Delay; Reschedule the ticking of this task until the rest of the tasks have been
--- ticked (puts it at the end of the list)
--- | -4
--- Repeat; Task needs to repeat execution immediately, usually caused by a change
--- in the task stack
--- | 0
--- Wait; Task is done with its execution for this tick, but should be called back
--- on the next tick. Returning a number greater than TASKSTATUS_Wait incdicates an additional
--- number of ticks to wait. For example:
---    `return TASKSTATUS_Wait + 3`
--- This indicates a wait of 4 ticks.
--- | 1+ # Wait the given number of ticks
--- | number

---@alias ScriptedTaskResult
--- | 0 # Unknown; the unit is performing the task.
--- | 1 # Success; the unit succesfully completed the task.
--- | 2 # Failed; the unit failed to carry out the order.
--- | 4 # Ignored; the unit is unable to carry out the order.

--- Task status values returned from TaskTick(). Do not modify this as this is a reflection of
--- the internal task codes used by the engine.
TASKSTATUS = {
    --- The tasks completes. It can be removed from the task stack; it will be
    --- popped and deleted automatically. Execution will immediately continue
    --- with the task's parent.
    ---
    --- You can also use TASKSTATUS_Done to do a tail call, by first pushing
    --- the task to switch to and then returning TASKSTATUS_Done.
    Done = -1,

    --- The tasks suspends. Not implemented, usage will crash the game.
    Suspend = -2,

    --- The tasks aborts. Not implemented, usage will cause the unit to be stuck on the command.
    Abort = -3,

    --- The task delays. It pushes the task to the very end of the task list and is executed after all other tasks.
    Delay = -4,

    --- The task repeats. It is executed immediately again.
    ---
    --- You can use this right after changing the state of a task.
    Repeat = 0,

    --- The task waits. It is called again after waiting the number of ticks. For example, the value `3` means the task waits for three ticks.
    Wait = 1,
}

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
---@field CommandData table
ScriptTask = Class(moho.ScriptTask_Methods) {

    -- Called immediately when the task is created
    ---@param self ScriptTask
    ---@param commandData table
    OnCreate = function(self, commandData)
        self.CommandData = commandData
    end,

    -- Called by the engine when the task is destroyed. This could be it naturally going away after completion or because it was cancelled by another task.
    ---@param self ScriptTask
    OnDestroy = function(self)
    end,

    -- Called by the engine in an interval. Function must return a value in TaskStatus
    ---@param self ScriptTask
    ---@return ScriptedTaskStatus
    TaskTick = function(self)
        self:SetAIResult(AIRESULT.Fail)
        error('ScriptTask.TaskTick called. Did you forget to add TaskName to your command lua param table?')
        return TASKSTATUS.Done
    end,
}
