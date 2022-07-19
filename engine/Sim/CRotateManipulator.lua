---@declare-global
---@class moho.RotateManipulator : moho.manipulator_methods
local CRotateManipulator = {}

---
function CRotateManipulator:ClearFollowBone()
end

---
--  RotateManipulator:ClearGoal()
function CRotateManipulator:ClearGoal()
end

---
--  RotateManipulator:GetCurrentAngle()
function CRotateManipulator:GetCurrentAngle()
end

---
--  RotateManipulator:SetAccel(degrees_per_second_squared)
function CRotateManipulator:SetAccel(degrees_per_second_squared)
end

---
--  RotateManipulator:SetCurrentAngle(angle)
function CRotateManipulator:SetCurrentAngle(angle)
end

---
--  RotateManipulator:SetFollowBone(bone)
function CRotateManipulator:SetFollowBone(bone)
end

---
--  RotateManipulator:SetGoal(self, degrees)
function CRotateManipulator:SetGoal(self,  degrees)
end

---
--  RotateManipulator:SetSpeed(self, degrees_per_second)
function CRotateManipulator:SetSpeed(self,  degrees_per_second)
end

---
--  RotateManipulator:SetSpinDown(self, flag)
function CRotateManipulator:SetSpinDown(self,  flag)
end

---
--  RotateManipulator:SetTargetSpeed(degrees_per_second)
function CRotateManipulator:SetTargetSpeed(degrees_per_second)
end

return CRotateManipulator

