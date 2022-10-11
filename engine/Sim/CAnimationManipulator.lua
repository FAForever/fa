---@meta

---@class moho.AnimationManipulator : moho.manipulator_methods
local CAnimationManipulator = {}

---
---@return number
function CAnimationManipulator:GetAnimationDuration()
end

---
--  fraction = AnimationManipulator:GetAnimationFraction()
function CAnimationManipulator:GetAnimationFraction()
end

---
--  time = AnimationManipulator:GetAnimationTime()
function CAnimationManipulator:GetAnimationTime()
end

---
--  rate = AnimationManipulator:GetRate()
function CAnimationManipulator:GetRate()
end

---
--  AnimManipulator:PlayAnim(entity, animName, looping=false)
function CAnimationManipulator:PlayAnim(entity,  animName,  looping)
end

---
--  AnimationManipulator:SetAnimationFraction(fraction)
function CAnimationManipulator:SetAnimationFraction(fraction)
end

---
--  AnimationManipulator:SetAnimationTime(fraction)
function CAnimationManipulator:SetAnimationTime(fraction)
end

---
--  AnimationManipulator:SetBoneEnabled(bone, value, include_decscendants=true)
function CAnimationManipulator:SetBoneEnabled(bone,  value,  include_decscendants)
end

---
--  AnimationManipulator:SetDirectionalAnim(bool)
function CAnimationManipulator:SetDirectionalAnim(bool)
end

---
--  AnimationManipulator:SetDisableOnSignal(bool)
function CAnimationManipulator:SetDisableOnSignal(bool)
end

---
--  AnimationManipulator:SetOverwriteMode(bool)
function CAnimationManipulator:SetOverwriteMode(bool)
end

---
--  AnimationManipulator:SetRate(rate)Set the relative rate at which this anim plays; 1.0 is normal speed.Rate can be negative to play backwards or 0 to pause.
function CAnimationManipulator:SetRate(rate)
end

return CAnimationManipulator

