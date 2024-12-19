--*****************************************************************************
--* File: lua/sim/tasks/AttackMove.lua
--*
--* Dummy task for the Attack Move button
--*****************************************************************************
local ScriptTask = import("/lua/sim/scripttask.lua").ScriptTask
local TASKSTATUS = import("/lua/sim/scripttask.lua").TASKSTATUS
local AIRESULT = import("/lua/sim/scripttask.lua").AIRESULT

---@class AttackMoveTask : ScriptTask
---@field CommandData { TaskName: "AttackMove" }
AttackMove = Class(ScriptTask) {

    -- Called by the engine every tick. Function must return a value in TaskStatus
    ---@param self AttackMoveTask
    ---@return ScriptTaskStatus
    TaskTick = function(self)
        self:SetAIResult(AIRESULT.Success)
        return TASKSTATUS.Done
    end,
}