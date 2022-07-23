---@declare-global
---@class moho.BuilderArmManipulator : moho.manipulator_methods
local CBuilderArmManipulator = {}

---
---@return number
function CBuilderArmManipulator:GetHeadingPitch()
end

---
--  BuilderArmManipulator:SetAimingArc(minHeading, maxHeading, headingMaxSlew, minPitch, maxPitch, pitchMaxSlew)
function CBuilderArmManipulator:SetAimingArc(minHeading,  maxHeading,  headingMaxSlew,  minPitch,  maxPitch,  pitchMaxSlew)
end

---
---@param minHeading number
---@param maxHeading number
---@param headingMaxSlew number
---@param minPitch number
---@param maxPitch number
---@param pitchMaxSlew number
function CBuilderArmManipulator:SetAimingArc(minHeading, maxHeading, headingMaxSlew, minPitch, maxPitch, pitchMaxSlew)
end

---
---@param heading number
---@param pitch number
function CBuilderArmManipulator:SetHeadingPitch(heading, pitch)
end

return CBuilderArmManipulator
