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
--  CBuilderArmManipulator:SetHeadingPitch(heading, pitch)
function CBuilderArmManipulator:SetHeadingPitch(heading,  pitch)
end

return CBuilderArmManipulator
