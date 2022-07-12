---@declare-global
---@class UserUnit
local UserUnit = {}

---@class MissileInfo
---@field nukeSiloBuildCount number
---@field nukeSiloMaxStorageCount number
---@field nukeSiloStorageCount number
---@field tacticalSiloBuildCount number
---@field tacticalSiloMaxStorageCount number
---@field tacticalSiloStorageCount number

---@class EconData
---@field energyConsumed number
---@field energyProduced number
---@field energyRequested number
---@field massConsumed number
---@field massProduced number
---@field massRequested number

---
---@param target UserUnit
---@param rangeCheck boolean
function UserUnit:CanAttackTarget(target, rangeCheck)
end

--- Return the army index
---@return number
function UserUnit:GetArmy()
end

---
---@retrun UnitBluepritn
function UserUnit:GetBlueprint()
end

--- Return current unit build rate
---@return number
function UserUnit:GetBuildRate()
end

--- Return table of commands
---@return OrderInfo[]
function UserUnit:GetCommandQueue()
end

--- Return the unit's creator, or nil
---@return UserUnit | nil
function UserUnit:GetCreator()
end

--- Get the current custom name, nil if none
---@return string | nil
function UserUnit:GetCustomName()
end

--- Return a table of economy data
---@return EconData
function UserUnit:GetEconData()
end

---
---@return string
function UserUnit:GetEntityId()
end

--- Return the unit this unit is currently focused on, or nil
---@return UserUnit | nil
function UserUnit:GetFocus()
end

---
---@return {SizeX: number, SizeZ: number}
function UserUnit:GetFootPrintSize()
end

---
---@return number
function UserUnit:GetFuelRatio()
end

--- Return the unit's guard target, or nil
---@return UserUnit | nil
function UserUnit:GetGuardedEntity()
end

--- Return current health
---@return number
function UserUnit:GetHealth()
end

--- Return max health
---@return number
function UserUnit:GetMaxHealth()
end

--- Return a table of the missile info for this unit
---@return MissileInfo
function UserUnit:GetMissileInfo()
end

--- Return the current world position of the unit
---@return Position
function UserUnit:GetPosition()
end

--- Get table of all selection sets unit belongs to
---@return string[]
function UserUnit:GetSelectionSets()
end

---
---@return number
function UserUnit:GetShieldRatio()
end

---
---@param name string
---@param defaultVal? any
---@return any
function UserUnit:GetStat(name, defaultVal)
end

---
---@return string
function UserUnit:GetUnitId()
end

---
---@return number
function UserUnit:GetWorkProgress()
end

--- See if a unit belongs to a given selection set
---@param selSet string
---@return boolean
function UserUnit:HasSelectionSet(selSet)
end

--- See if this unit already has an unload from transport queued up
---@return boolean
function UserUnit:HasUnloadCommandQueuedUp()
end

---
---@return boolean
function UserUnit:IsAutoMode()
end

---
---@return boolean
function UserUnit:IsAutoSurfaceMode()
end

--- Return true if the unit has been destroyed
---@return boolean
function UserUnit:IsDead()
end

--- Return true if the unit is idle
---@return boolean
function UserUnit:IsIdle()
end

---
---@param category moho.EntityCategory
---@return boolean
function UserUnit:IsInCategory(category)
end

--- Return current overcharge paused status
---@return boolean
function UserUnit:IsOverchargePaused()
end

---
---@return boolean
function UserUnit:IsRepeatQueue()
end

---
---@return boolean
function UserUnit:IsStunned()
end

---
---@param command string
---@param value string
function UserUnit:ProcessInfo(command, value)
end

--- Remove a selection set name from a unit
---@param selSet string
function UserUnit:RemoveSelectionSet(selSet)
end

--- Set a custom name for the unit
---@param name string
function UserUnit:SetCustomName(name)
end

return UserUnit
