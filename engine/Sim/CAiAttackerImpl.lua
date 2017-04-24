--- Class CAiAttackerImpl
-- @classmod Sim.CAiAttackerImpl

---
--  Loop through the weapons to see if the target can be attacked
function CAiAttackerImpl:CanAttackTarget()
end

---
--  Find the best enemy target for a weapon
function CAiAttackerImpl:FindBestEnemy()
end

---
--  Force to engage enemy target
function CAiAttackerImpl:ForceEngage()
end

---
--  Get the desired target
function CAiAttackerImpl:GetDesiredTarget()
end

---
--  Loop through the weapons to find the weapon with the longest range that is not manual fire
function CAiAttackerImpl:GetMaxWeaponRange()
end

---
--  Loop through the weapons to find our primary weapon
function CAiAttackerImpl:GetPrimaryWeapon()
end

---
--  Loop through the weapons to find one that we can use to attack target
function CAiAttackerImpl:GetTargetWeapon()
end

---
--  Returns the unit this attacker is bound to.
function CAiAttackerImpl:GetUnit()
end

---
--  Return the count of weapons
function CAiAttackerImpl:GetWeaponCount()
end

---
--  Check if the attack has a slaved weapon that currently has a target
function CAiAttackerImpl:HasSlavedTarget()
end

---
--  Check if the target is exempt from being attacked
function CAiAttackerImpl:IsTargetExempt()
end

---
--  Check if the target is too close to our weapons
function CAiAttackerImpl:IsTooClose()
end

---
--  Check if the target is within any weapon range
function CAiAttackerImpl:IsWithinAttackRange()
end

---
--  Reset reporting state
function CAiAttackerImpl:ResetReportingState()
end

---
--  Set the desired target
function CAiAttackerImpl:SetDesiredTarget()
end

---
--  Stop the attacker
function CAiAttackerImpl:Stop()
end

---
--
function CAiAttackerImpl:moho.CAiAttackerImpl_methods()
end

