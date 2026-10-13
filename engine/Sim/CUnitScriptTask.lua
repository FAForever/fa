---@meta

---@class moho.ScriptTask_Methods
local CUnitScriptTask = {}

--- Set the AI result, success (1) or fail (2)
---@param result
---| 1 # Success: Successfully carried out the order.
---| 2 # Fail: Failed to carry out the order.
function CUnitScriptTask:SetAIResult(result)
end

--- Get the unit this task was ordered to.
---@return Unit
function CUnitScriptTask:GetUnit()
end

--- Called by the engine after the task is constructed, with the LuaParams table of the order.
---@type nil | fun(self: ScriptTask, commandData: table)
CUnitScriptTask.OnCreate = nil

--- Called by the engine when the task is destroyed, after it completes or when another order cancels it.
---@type nil | fun(self: ScriptTask)
CUnitScriptTask.OnDestroy = nil

--- Called by the engine to run the task. The returned status sets when the engine calls it again.
---@type nil | fun(self: ScriptTask): ScriptTaskStatus
CUnitScriptTask.TaskTick = nil

return CUnitScriptTask
