---@declare-global
---@class moho.navigator_methods
local CNavigator = {}

---
--
function CNavigator:AtGoal()
end

---
--  Broadcast event to resume any listening task that is currently suspended
function CNavigator:BroadcastResumeTaskEvent()
end

---
--
function CNavigator:CanPathToGoal()
end

---
--
function CNavigator:FollowingLeader()
end

---
--  This returns the current navigator target position for the unit
function CNavigator:GetCurrentTargetPos()
end

---
--  This returns the current goal position of our navigator
function CNavigator:GetGoalPos()
end

---
--
function CNavigator:GetStatus()
end

---
--
function CNavigator:HasGoodPath()
end

---
--
function CNavigator:IgnoreFormation()
end

---
--
function CNavigator:IsIgnorningFormation()
end

---
--  Set the navigator's destination as another unit (chase/follow)
function CNavigator:SetDestUnit()
end

---
--  Set the navigator's destination as a particular position
function CNavigator:SetGoal()
end

---
-- :Set flag in navigator so the unit will know whether to stop at final goal:or speed through it. This would be set to True during a patrol or a series:of waypoints in a complex path.
function CNavigator:SetSpeedThroughGoal()
end

return CNavigator

