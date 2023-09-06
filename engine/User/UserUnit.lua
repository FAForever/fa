---@meta

---@class UserUnit: InternalObject
---@field ThreadUnpause? thread
---@field ThreadUnpauseCandidates? table<EntityId, boolean>
local UserUnit = {}

---@alias UserUnitCommand 
--- | 'UNITCOMMAND_BuildFactory' 
--- | 'UNITCOMMAND_BuildSilo'
--- | 'UNITCOMMAND_DestroySelf'
--- | 'UNITCOMMAND_KillSelf'
--- | 'UNITCOMMAND_AssistCommander'
--- | 'UNITCOMMAND_Upgrade'
--- | 'UNITCOMMAND_Land'
--- | 'UNITCOMMAND_Stop'
--- | 'UNITCOMMAND_Dive'
--- | 'UNITCOMMAND_OverCharge'
--- | 'UNITCOMMAND_Sacrifice'
--- | 'UNITCOMMAND_Capture'
--- | 'UNITCOMMAND_Dock'
--- | 'UNITCOMMAND_Repair'
--- | 'UNITCOMMAND_Reclaim'
--- | 'UNITCOMMAND_Guard'
--- | 'UNITCOMMAND_BuildMobile'
--- | 'UNITCOMMAND_BuildAssist'
--- | 'UNITCOMMAND_Teleport'
--- | 'UNITCOMMAND_Ferry'
--- | 'UNITCOMMAND_AssistMove'
--- | 'UNITCOMMAND_DetachFromTransport'
--- | 'UNITCOMMAND_TransportUnloadSpecificUnits'
--- | 'UNITCOMMAND_TransportUnloadUnits'
--- | 'UNITCOMMAND_TransportReverseLoadUnits'
--- | 'UNITCOMMAND_TransportLoadUnits'
--- | 'UNITCOMMAND_FormPatrol'
--- | 'UNITCOMMAND_Patrol'
--- | 'UNITCOMMAND_CoordinatedMove'
--- | 'UNITCOMMAND_FormMove'
--- | 'UNITCOMMAND_Move'
--- | 'UNITCOMMAND_Nuke'
--- | 'UNITCOMMAND_FormAggressiveMove'
--- | 'UNITCOMMAND_AggressiveMove'
--- | 'UNITCOMMAND_Script'
--- | 'UNITCOMMAND_Tactical'
--- | 'UNITCOMMAND_FormAttack'
--- | 'UNITCOMMAND_Retaliate'
--- | 'UNITCOMMAND_Attack'

---@alias UserUnitBlueprintCommand
--- | 'UNITCOMMAND_Upgrade'
--- | 'UNITCOMMAND_BuildFactory'

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

--- Returns the army index
---@return number
function UserUnit:GetArmy()
end

---
---@return UnitBlueprint
function UserUnit:GetBlueprint()
end

--- Returns current unit build rate
---@return number
function UserUnit:GetBuildRate()
end

--- Returns a table of commands
---@return OrderInfo[]
function UserUnit:GetCommandQueue()
end

--- Returns the unit's creator, or `nil` if none
---@return UserUnit | nil
function UserUnit:GetCreator()
end

--- Returns the current custom name, `nil` if none
---@return string | nil
function UserUnit:GetCustomName()
end

--- Returns a table of economy data
---@return EconData
function UserUnit:GetEconData()
end

---
---@return EntityId
function UserUnit:GetEntityId()
end

--- Returns the unit this unit is currently focused on, or `nil`
---@return UserUnit | nil
function UserUnit:GetFocus()
end

---
---@return {SizeX: number, SizeZ: number}
function UserUnit:GetFootPrintSize()
end

--- Returns the unit's fuel level, as a decimal between `0.0` and `1.0`
---@return number
function UserUnit:GetFuelRatio()
end

--- Returns the unit's guard target, or nil
---@return UserUnit | nil
function UserUnit:GetGuardedEntity()
end

--- Returns current health
---@return number
function UserUnit:GetHealth()
end

--- Returns max health
---@return number
function UserUnit:GetMaxHealth()
end

--- Returns a table of the missile info for this unit
---@return MissileInfo
function UserUnit:GetMissileInfo()
end

--- Returns the current world position of the unit
---@return Vector
function UserUnit:GetPosition()
end

--- Gets a table of all selection sets the unit belongs to
---@return string[]
function UserUnit:GetSelectionSets()
end

--- Returns the unit's shield level, as a decimal between `0.0` and `1.0`
---@return number
function UserUnit:GetShieldRatio()
end

--- Retrieves a statistic that is assigned to a unit by the sim call `unit:UpdateStat`. Returns the default
--- when the value does not exist
---@param name string
---@param defaultVal? number
---@return {Value: number}
function UserUnit:GetStat(name, defaultVal)
end

--- Returns the unit's ID (e.g. `"UAL0305"`)
---@return string
function UserUnit:GetUnitId()
end

--- Gets the progress of the unit's current work, as a decimal between `0.0` and `1.0`
---@return number
function UserUnit:GetWorkProgress()
end

--- Returns if a unit belongs to a given selection set
---@param selSet string
---@return boolean
function UserUnit:HasSelectionSet(selSet)
end

--- Returns if this unit already has an unload from transport queued up
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

--- Returns if the unit has been destroyed
---@return boolean
function UserUnit:IsDead()
end

--- Returns if the unit is idle
---@return boolean
function UserUnit:IsIdle()
end

---
---@param category CategoryName
---@return boolean
function UserUnit:IsInCategory(category)
end

--- Returns current overcharge paused status
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

---@param command 'SetAutoMode' | 'SetFireState' | 'SetAutoSurfaceMode' | 'SetRepeatQueue' | 'SetPaused' | 'CustomName' | 'ToggleScriptBit' | 'PlayNoStagingPlatformsVO' | 'PlayBusyStagingPlatformsVO' 
---@param value boolean | string
function UserUnit:ProcessInfo(command, value)
end

--- Removes a selection set name from a unit
---@param selSet string
function UserUnit:RemoveSelectionSet(selSet)
end

--- Sets a custom name for the unit
---@param name string
function UserUnit:SetCustomName(name)
end

return UserUnit
