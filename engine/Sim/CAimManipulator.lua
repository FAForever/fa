--- Class CAimManipulator
-- @classmod Sim.CAimManipulator

---
--  AimManipulator:OnTarget()
function CAimManipulator:OnTarget()
end

---
--  AimManipulator:SetAimHeadingOffset(offset)
function CAimManipulator:SetAimHeadingOffset(offset)
end

---
--  AimManipulator:SetEnabled(flag)
function CAimManipulator:SetEnabled(flag)
end

---
--  AimManipulator:SetFiringArc(minHeading, maxHeading, headingMaxSlew, minPitch, maxPitch, pitchMaxSlew)
function CAimManipulator:SetFiringArc(minHeading,  maxHeading,  headingMaxSlew,  minPitch,  maxPitch,  pitchMaxSlew)
end

---
--  AimManipulator:SetHeadingPitch(heading, pitch)
function CAimManipulator:SetHeadingPitch(heading,  pitch)
end

---
--  AimManipulator:SetResetPoseTime(resetTime)
function CAimManipulator:SetResetPoseTime(resetTime)
end

---
--  derived from IAniManipulator
function CAimManipulator:base()
end

---
--
function CAimManipulator:moho.AimManipulator()
end

