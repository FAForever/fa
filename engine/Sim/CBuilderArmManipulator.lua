---@declare-global
---@class moho.BuilderArmManipulator
local CBuilderArmManipulator = {}

---
--  BuilderArmManipulator:SetAimingArc(minHeading, maxHeading, headingMaxSlew, minPitch, maxPitch, pitchMaxSlew)
function CBuilderArmManipulator:SetAimingArc(minHeading,  maxHeading,  headingMaxSlew,  minPitch,  maxPitch,  pitchMaxSlew)
end

---
--  CBuilderArmManipulator:SetHeadingPitch(heading, pitch)
function CBuilderArmManipulator:SetHeadingPitch(heading,  pitch)
end

---
--  derived from IAniManipulator
function CBuilderArmManipulator:base()
end

return CBuilderArmManipulator
