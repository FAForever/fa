---@meta

---@class moho.SlideManipulator : moho.manipulator_methods
local CSlideManipulator = {}

---@return boolean
function CSlideManipulator:BeenDestroyed()
end

---@param acc number
---@return self
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
---@return self
function CSlideManipulator:SetSpeed(speed)
end

---@param bool boolean
---@return self
function CSlideManipulator:SetWorldUnits(bool)
end

return CSlideManipulator
