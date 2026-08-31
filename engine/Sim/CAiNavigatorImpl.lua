---@meta

---@class moho.navigator_methods
local CNavigator = {}

---
function CNavigator:AbortMove()
end

---@return boolean
function CNavigator:AtGoal()
end

---Broadcast event to resume any listening task that is currently suspended
function CNavigator:BroadcastResumeTaskEvent()
end

---@return boolean
function CNavigator:CanPathToGoal()
end

---@return boolean
function CNavigator:FollowingLeader()
end

---This returns the current navigator target position for the unit
---@return Vector?
function CNavigator:GetCurrentTargetPos()
end

---This returns the current goal position of our navigator
---@return Vector #Its not verified if nil can be returned here.
function CNavigator:GetGoalPos()
end

---@return unknown
function CNavigator:GetStatus()
end

---@return boolean
function CNavigator:HasGoodPath()
end

---@param bool boolean
function CNavigator:IgnoreFormation(bool)
end

---@return boolean
function CNavigator:IsIgnorningFormation()
end

---Set the navigator's destination as another unit (chase/follow)
---@param target Unit
function CNavigator:SetDestUnit(target)
end

---Set the navigator's destination as a particular position
---@param goal Vector
function CNavigator:SetGoal(goal)
end

---Set flag in navigator so the unit will know whether to stop at final goal:or speed through it.
---This would be set to True during a patrol or a series:of waypoints in a complex path.
---@param flag boolean
function CNavigator:SetSpeedThroughGoal(flag)
end

return CNavigator

