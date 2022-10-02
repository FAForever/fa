---@meta

---@class moho.CAiAttackerImpl_methods
local CAiAttackerImpl = {}

---@class AITarget
---@field Type string

--- Returns if the attacker has any weapon that is currently attacking any enemies
---@return boolean
function CAiAttackerImpl:AttackerWeaponsBusy()
end

--- Loop through the weapons to see if the target can be attacked
---@param target AITarget
---@return boolean
function CAiAttackerImpl:CanAttackTarget(target)
end

--- Find the best enemy target for a weapon
---@param range number
---@return Entity | Unit
function CAiAttackerImpl:FindBestEnemy(range)
end

--- Force to engage enemy target
function CAiAttackerImpl:ForceEngage()
end

--- Get the desired target
---@return AITarget
function CAiAttackerImpl:GetDesiredTarget()
end

--- Loop through the weapons to find the weapon with the longest range that is not manual fire
---@return number
function CAiAttackerImpl:GetMaxWeaponRange()
end

--- Loop through the weapons to find our primary weapon
---@return number
function CAiAttackerImpl:GetPrimaryWeapon()
end

--- Loop through the weapons to find one that we can use to attack target
---@param target AITarget
---@return Unit
function CAiAttackerImpl:GetTargetWeapon(target)
end

--- Returns the unit this attacker is bound to
---@return Unit
function CAiAttackerImpl:GetUnit()
end

--- Return the count of weapons
---@return number
function CAiAttackerImpl:GetWeaponCount()
end

--- Check if the attack has a slaved weapon that currently has a target
---@return boolean
function CAiAttackerImpl:HasSlavedTarget()
end

--- Check if the target is exempt from being attacked
---@return boolean
function CAiAttackerImpl:IsTargetExempt()
end

--- Check if the target is too close to our weapons
---@return boolean
function CAiAttackerImpl:IsTooClose()
end

--- Check if the target is within any weapon range
---@param weaponIndex number
---@param target AITarget | Vector
---@return boolean
---@overload fun(target: AITarget | Vector): boolean
function CAiAttackerImpl:IsWithinAttackRange(weaponIndex, target)
end

--- Reset reporting state
function CAiAttackerImpl:ResetReportingState()
end

--- Set the desired target
---@param target AITarget
function CAiAttackerImpl:SetDesiredTarget(target)
end


--- Ceases all firing upon enemies or ground positions. However, the weapons can still pick up
--- enemies and begin firing on their own. Same as `SetDesiredTarget(nil)`
function CAiAttackerImpl:Stop()
end

return CAiAttackerImpl
