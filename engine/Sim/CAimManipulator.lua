---@meta

---@class moho.AimManipulator : moho.manipulator_methods
local CAimManipulator = {}

--- Returns the heading and pitch of the manipulator
---@return number
---@return number
function CAimManipulator:GetHeadingPitch()
end

--- Returns true when the manipulator is considered to be on target
--  AimManipulator:OnTarget()
function CAimManipulator:OnTarget()
end

--- Defines the heading offset when the manipulator is trying to lead the target
---@param offset Vector
function CAimManipulator:SetAimHeadingOffset(offset)
end

--- Enables or disables the manipulator
---@param enabled boolean
function CAimManipulator:SetEnabled(enabled)
end

--- Defines the firing arc of the weapon which defines in what area the weapon can look for targets.
---@param minHeading number
---@param maxHeading number
---@param headingMaxSlew number
---@param minPitch number
---@param maxPitch number
---@param pitchMaxSlew number
function CAimManipulator:SetFiringArc(minHeading, maxHeading, headingMaxSlew, minPitch, maxPitch, pitchMaxSlew)
end

--- Defines the heading and pitch of the 
---@param heading number
---@param pitch number
function CAimManipulator:SetHeadingPitch(heading, pitch)
end

--- Defines the time taken for the manipulator to reset to the idle pose
---@param resetTime number
function CAimManipulator:SetResetPoseTime(resetTime)
end

return CAimManipulator
