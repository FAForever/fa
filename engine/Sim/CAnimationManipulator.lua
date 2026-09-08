---@meta

---@class moho.AnimationManipulator : moho.manipulator_methods
local CAnimationManipulator = {}

--- Returns 0 for an invalid animation.
---@return number
function CAnimationManipulator:GetAnimationDuration()
end

---@return number fraction 0-1
function CAnimationManipulator:GetAnimationFraction()
end

---@return number time
function CAnimationManipulator:GetAnimationTime()
end

---@return number rate
function CAnimationManipulator:GetRate()
end

---@param animName FileName Must be a full file path.
---@param looping boolean? Defaults to `false`
---@return self
function CAnimationManipulator:PlayAnim(animName, looping)
end

---@param fraction number 0-1
function CAnimationManipulator:SetAnimationFraction(fraction)
end

---@param fraction number
function CAnimationManipulator:SetAnimationTime(fraction)
end

---@param bone Bone
---@param value boolean
---@param include_decscendants? boolean Defaults to `true`
function CAnimationManipulator:SetBoneEnabled(bone, value, include_decscendants)
end

---@param bool boolean
function CAnimationManipulator:SetDirectionalAnim(bool)
end

---@param bool boolean
function CAnimationManipulator:SetDisableOnSignal(bool)
end

---@param bool boolean
function CAnimationManipulator:SetOverwriteMode(bool)
end

---Set the relative rate at which this anim plays
---1.0 is normal speed. Rate can be negative to play backwards or 0 to pause.
---@param rate number
---@return self
function CAnimationManipulator:SetRate(rate)
end

return CAnimationManipulator

