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

--- Parameters of a script order, issued from the sim or the UI.
--- All units given the order in one command share the same table.
--- Each task in `lua/sim/tasks/` declares a subclass with its own fields.
--- Like `SimCallback` arguments, the values come from player input and the UI can send anything:
--- the task must validate them. The sim only checks that the player controls the units.
--- Orders issued from the UI with `IssueCommand` and similar functions have no target, so their position in `GetCommandQueue` is 0, 0, 0.
--- A nonzero position shows that the player clicked to give the order
---@see moho.unit_methods.GetCommandQueue # Returns the target position of each queued order
---@see IssueScript # Issues the order from the sim
---@see IssueCommand # Issues the order from the UI to the selection, without a target
---@see IssueUnitCommand # Issues the order from the UI to the given units, without a target
---@see IssueUnitCommandToUnit # Issues the order from the UI to one unit, without a target
---@see VerifyScriptCommand # Returns the parameters of an order given with a target in command mode
---@see CommandModeDataOrderScript # Command mode data of an order given with a target
---@class ScriptTaskParams : table
--- The engine runs the class of this name from `/lua/sim/tasks/<TaskName>.lua`, or `ScriptTask` when it can't find it
---@field TaskName string

--- Called by the engine after the task is created, with the parameters of the order
---@see IssueScript # Issues the order from the sim
---@see IssueCommand # Issues the order from the UI to the selection, without a target
---@see IssueUnitCommand # Issues the order from the UI to the given units, without a target
---@see IssueUnitCommandToUnit # Issues the order from the UI to one unit, without a target
---@see VerifyScriptCommand # Returns the parameters of an order given with a target in command mode
---@type nil | fun(self: ScriptTask, commandData: ScriptTaskParams)
CUnitScriptTask.OnCreate = nil

--- Called by the engine when the task is destroyed, after it completes, or when another order cancels it
---@type nil | fun(self: ScriptTask)
CUnitScriptTask.OnDestroy = nil

--- Called by the engine to run a step of the task. The returned status tells the engine when to call it again,
--- or that the task is done
---@type nil | fun(self: ScriptTask): ScriptTaskStatus
CUnitScriptTask.TaskTick = nil

return CUnitScriptTask
