---@meta

---@class moho.SlideManipulator : moho.manipulator_methods
local CSlideManipulator = {}

---
---@return boolean
function CSlideManipulator:BeenDestroyed()
end

---@param acc number
function CSlideManipulator:SetAcceleration(acc)
end

---@param dec number
function CSlideManipulator:SetDeceleration(dec)
end

---@param x number
---@param y number
---@param z number
---@return self
function CSlideManipulator:SetGoal(x, y, z)
end

---@param speed number
function CSlideManipulator:SetSpeed(speed)
end

---@param bool boolean
function CSlideManipulator:SetWorldUnits(bool)
end

return CSlideManipulator
