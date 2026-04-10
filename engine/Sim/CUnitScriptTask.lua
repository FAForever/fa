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

return CUnitScriptTask
