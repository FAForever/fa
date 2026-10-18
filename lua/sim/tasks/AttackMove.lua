--*****************************************************************************
--* File: lua/sim/tasks/AttackMove.lua
--*
--* Dummy task for the Attack Move button
--*****************************************************************************

local ScriptTask = import("/lua/sim/scripttask.lua").ScriptTask
local TASKSTATUS = import("/lua/sim/scripttask.lua").TASKSTATUS
local AIRESULT = import("/lua/sim/scripttask.lua").AIRESULT

---@class AttackMoveTaskParams : ScriptTaskParams
---@field TaskName "AttackMove"

--- Does nothing. The `AttackMove` sim callback checks that the unit's last order is a script order with a target,
--- which proves the player clicked to give it, then issues an attack move to that target
---@class AttackMoveTask : ScriptTask
---@field CommandData AttackMoveTaskParams
AttackMove = Class(ScriptTask) {

    -- Called by the engine every tick. Function must return a value in TaskStatus
    ---@param self AttackMoveTask
    ---@return ScriptTaskStatus
    TaskTick = function(self)
        self:SetAIResult(AIRESULT.Success)
        return TASKSTATUS.Done
    end,
}
