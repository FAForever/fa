--*****************************************************************************
--* File: lua/sim/tasks/AttackMove.lua
--*
--* Dummy task for the Attack Move button
--*****************************************************************************
local ScriptTask = import("/lua/sim/scripttask.lua").ScriptTask
local TASKSTATUS = import("/lua/sim/scripttask.lua").TASKSTATUS
local AIRESULT = import("/lua/sim/scripttask.lua").AIRESULT

---@class AttackMove : ScriptTask
AttackMove = Class(ScriptTask) {

    ---@param self AttackMove
    ---@return integer
    TaskTick = function(self)
        self:SetAIResult(AIRESULT.Success)
        return TASKSTATUS.Done
    end,
}