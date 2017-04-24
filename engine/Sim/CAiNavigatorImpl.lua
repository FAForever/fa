--- Class CAiNavigatorImpl
-- @classmod Sim.CAiNavigatorImpl

---
--
function CAiNavigatorImpl:AtGoal()
end

---
--  Broadcast event to resume any listening task that is currently suspended
function CAiNavigatorImpl:BroadcastResumeTaskEvent()
end

---
--
function CAiNavigatorImpl:CanPathToGoal()
end

---
--
function CAiNavigatorImpl:FollowingLeader()
end

---
--  This returns the current navigator target position for the unit
function CAiNavigatorImpl:GetCurrentTargetPos()
end

---
--  This returns the current goal position of our navigator
function CAiNavigatorImpl:GetGoalPos()
end

---
--
function CAiNavigatorImpl:GetStatus()
end

---
--
function CAiNavigatorImpl:HasGoodPath()
end

---
--
function CAiNavigatorImpl:IgnoreFormation()
end

---
--
function CAiNavigatorImpl:IsIgnorningFormation()
end

---
--  Set the navigator's destination as another unit (chase/follow)
function CAiNavigatorImpl:SetDestUnit()
end

---
--  Set the navigator's destination as a particular position
function CAiNavigatorImpl:SetGoal()
end

---
-- :Set flag in navigator so the unit will know whether to stop at final goal:or speed through it. This would be set to True during a patrol or a series:of waypoints in a complex path.
function CAiNavigatorImpl:SetSpeedThroughGoal()
end

---
--
function CAiNavigatorImpl:moho.navigator_methods()
end

