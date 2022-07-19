---@declare-global
---@class moho.AimManipulator : moho.manipulator_methods
local CAimManipulator = {}

---
---@return number
function CAimManipulator:GetHeadingPitch()
end

---
--  AimManipulator:OnTarget()
function CAimManipulator:OnTarget()
end

---
---@param offset Vector
function CAimManipulator:SetAimHeadingOffset(offset)
end

---
---@param enabled boolean
function CAimManipulator:SetEnabled(enabled)
end

---
---@param minHeading number
---@param maxHeading number
---@param headingMaxSlew number
---@param minPitch number
---@param maxPitch number
---@param pitchMaxSlew number
function CAimManipulator:SetFiringArc(minHeading, maxHeading, headingMaxSlew, minPitch, maxPitch, pitchMaxSlew)
end

---
---@param heading number
---@param pitch number
function CAimManipulator:SetHeadingPitch(heading, pitch)
end

---
---@param resetTime number
function CAimManipulator:SetResetPoseTime(resetTime)
end

return CAimManipulator
