--- Class UserUnit
-- @classmod User.UserUnit

---
--  UserUnit:CanAttackTarget(target, rangeCheck)
function UserUnit:CanAttackTarget(target,  rangeCheck)
end

---
--  GetArmy() -- returns the army index
function UserUnit:GetArmy()
end

---
--  blueprint = UserUnit.Blueprint
function UserUnit.Blueprint
end

---
--  GetBuildRate() -- return current unit build rate
function UserUnit:GetBuildRate()
end

---
--  table GetCommandQueue() - returns table of commands
function UserUnit:GetCommandQueue()
end

---
--  GetCreator() -- returns the units creator, or nil
function UserUnit:GetCreator()
end

---
--  string GetCustomName() -- get the current custom name, nil if none
function UserUnit:GetCustomName()
end

---
--  GetEconData() - returns a table of economy data
function UserUnit:GetEconData()
end

---
--  Entity:GetEntityId()
function UserUnit:GetEntityId()
end

---
--  GetFocus() -- returns the unit this unit is currently focused on, or nil
function UserUnit:GetFocus()
end

---
--  UserUnit:GetFootPrintSize()
function UserUnit:GetFootPrintSize()
end

---
--  GetFuelRatio()
function UserUnit:GetFuelRatio()
end

---
--  GetGuardedEntity() -- returns the units guard target, or nil
function UserUnit:GetGuardedEntity()
end

---
--  GetHealth() -- return current health
function UserUnit:GetHealth()
end

---
--  GetMaxHealth() -- return max health
function UserUnit:GetMaxHealth()
end

---
--  table GetMissileInfo() - returns a table of the missile info for this unit
function UserUnit:GetMissileInfo()
end

---
--  VECTOR3 GetPosition() - returns the current world posititon of the unit
function UserUnit:GetPosition()
end

---
--  table GetSelectionSets() -- get table of all selection sets unit belongs to
function UserUnit:GetSelectionSets()
end

---
--  GetShieldRatio()
function UserUnit:GetShieldRatio()
end

---
--  GetStat(Name[,defaultVal])
function UserUnit:GetStat(Name[, defaultVal])
end

---
--  UserUnit:GetUnitId()
function UserUnit:GetUnitId()
end

---
--  GetWorkProgress()
function UserUnit:GetWorkProgress()
end

---
--  bool HasSelectionSet(string) -- see if a unit belongs to a given selection set
function UserUnit:HasSelectionSet(string)
end

---
--  See if this unit already has an unload from transport queued up
function UserUnit:HasUnloadCommandQueuedUp()
end

---
--  bool = UserUnit:IsAutoMode()
function UserUnit:IsAutoMode()
end

---
--  bool = UserUnit:IsAutoSurfaceMode()
function UserUnit:IsAutoSurfaceMode()
end

---
--  IsDead() -- return true if the unit has been destroyed
function UserUnit:IsDead()
end

---
--  IsIdle() -- return true if the unit is idle
function UserUnit:IsIdle()
end

---
--  bool = UserUnit:IsInCategory(category)
function UserUnit:IsInCategory(category)
end

---
--  IsOverchargePaused() -- return current overcharge paused status
function UserUnit:IsOverchargePaused()
end

---
--  bool = UserUnit:IsRepeatQueue()
function UserUnit:IsRepeatQueue()
end

---
--  flag = UserUnit:IsStunned()
function UserUnit:IsStunned()
end

---
--  UserUnit:ProcessInfoPair()
function UserUnit:ProcessInfo()
end

---
--  RemoveSelectionSet(string) -- remove a selection set name from a unit
function UserUnit:RemoveSelectionSet(string)
end

---
--  SetCustomName(string) -- Set a custom name for the unit
function UserUnit:SetCustomName(string)
end

