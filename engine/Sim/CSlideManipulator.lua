---@meta

---@class moho.SlideManipulator : moho.manipulator_methods
local CSlideManipulator = {}

---
---@return boolean
function CSlideManipulator:BeenDestroyed()
end

---
--  CSlideManipulator:SetAcceleration(acc)
function CSlideManipulator:SetAcceleration(acc)
end

---
--  CSlideManipulator:SetDeceleration(dec)
function CSlideManipulator:SetDeceleration(dec)
end

---
--  CSlideManipulator:SetGoal(goal_x, goal_y, goal_z)
function CSlideManipulator:SetGoal(goal_x,  goal_y,  goal_z)
end

---
--  CSlideManipulator:SetSpeed(speed)
function CSlideManipulator:SetSpeed(speed)
end

---
--  CSlideManipulator:SetWorldUnits(bool)
function CSlideManipulator:SetWorldUnits(bool)
end

return CSlideManipulator
