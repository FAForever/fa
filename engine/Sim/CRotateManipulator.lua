---@meta

---@class moho.RotateManipulator : moho.manipulator_methods
local CRotateManipulator = {}

---
function CRotateManipulator:ClearFollowBone()
end

---
function CRotateManipulator:ClearGoal()
end

---
---@return number
function CRotateManipulator:GetCurrentAngle()
end

---
---@param degreesPerSecondSquared number
function CRotateManipulator:SetAccel(degreesPerSecondSquared)
end

---
---@param angle number
function CRotateManipulator:SetCurrentAngle(angle)
end

---
---@param bone Bone
function CRotateManipulator:SetFollowBone(bone)
end

---
---@param degrees number
function CRotateManipulator:SetGoal(degrees)
end

---
---@param degreesPerSecond number
function CRotateManipulator:SetSpeed(degreesPerSecond)
end

---
---@param spinDown boolean
function CRotateManipulator:SetSpinDown(spinDown)
end

---
---@param degreesPerSecond number
function CRotateManipulator:SetTargetSpeed(degreesPerSecond)
end

return CRotateManipulator
