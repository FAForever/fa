--****************************************************************************
--**
--**  File     :  /lua/sim/AdjacencyBuffFunctions.lua
--**
--**  Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

------------------------------------------------------------------------------------------------------------------------------------
---- DEFAULT FUNCTIONS FOR ADJACENCY
------------------------------------------------------------------------------------------------------------------------------------

local TableGetn = table.getn

---@param buff BlueprintBuff
---@param unit StructureUnit
---@param instigator StructureUnit
DefaultBuffRemove = function(buff, unit, instigator)
    unit:DestroyAdjacentEffects(instigator)
end

---@param buff BlueprintBuff
---@param unit StructureUnit
---@param instigator StructureUnit
DefaultBuffAffect = function(buff, unit, instigator)
    unit:CreateAdjacentEffect(instigator)
end

-- Energy Build Bonus - Energy Active Consumption
---@param buff BlueprintBuff
---@param unit StructureUnit
---@return boolean
EnergyBuildBuffCheck = function(buff, unit)
    local bp = unit:GetBlueprint()
    if bp.Economy.BuildableCategory and TableGetn(bp.Economy.BuildableCategory) > 0 then
        return true
    end
    if EntityCategoryContains(categories.SILO, unit) and EntityCategoryContains(categories.STRUCTURE, unit) then
        return true
    end
    return false
end

---@param buff BlueprintBuff
---@param unit StructureUnit
---@param instigator StructureUnit
EnergyBuildBuffRemove = function(buff, unit, instigator)
    DefaultBuffRemove(buff, unit, instigator)
end

---@param buff BlueprintBuff
---@param unit StructureUnit
---@param instigator StructureUnit
EnergyBuildBuffAffect = function(buff, unit, instigator)
    DefaultBuffAffect(buff, unit, instigator)
end

-- Mass Build Bonus - Mass Active Consumption
---@param buff BlueprintBuff
---@param unit StructureUnit
---@return boolean
MassBuildBuffCheck = function(buff, unit)
    local bp = unit:GetBlueprint()
    if bp.Economy.BuildableCategory and TableGetn(bp.Economy.BuildableCategory) > 0 then
        return true
    end
    if EntityCategoryContains(categories.SILO, unit) and EntityCategoryContains(categories.STRUCTURE, unit) then
        return true
    end
    return false
end

---@param buff BlueprintBuff
---@param unit StructureUnit
---@param instigator StructureUnit
MassBuildBuffRemove = function(buff, unit, instigator)
    DefaultBuffRemove(buff, unit, instigator)
end

---@param buff BlueprintBuff
---@param unit StructureUnit
---@param instigator StructureUnit
MassBuildBuffAffect = function(buff, unit, instigator)
    DefaultBuffAffect(buff, unit, instigator)
end

-- Energy Maintenance Bonus
---@param buff BlueprintBuff
---@param unit StructureUnit
---@return boolean
EnergyMaintenanceBuffCheck = function(buff, unit)
    local bp = unit:GetBlueprint()
    if bp.Economy.MaintenanceConsumptionPerSecondEnergy or unit.EnergyMaintenanceConsumptionOverride then
        return true
    end
    return false
end

---@param buff BlueprintBuff
---@param unit StructureUnit
---@param instigator StructureUnit
EnergyMaintenanceBuffRemove = function(buff, unit, instigator)
    DefaultBuffRemove(buff, unit, instigator)
end

---@param buff BlueprintBuff
---@param unit StructureUnit
---@param instigator StructureUnit
EnergyMaintenanceBuffAffect = function(buff, unit, instigator)
    DefaultBuffAffect(buff, unit, instigator)
end

---@param buff BlueprintBuff
---@param unit StructureUnit
---@return boolean
MassActiveBuffCheck = function(buff, unit)
    local bp = unit:GetBlueprint()
    if bp.Economy.BuildableCategory and not table.empty(bp.Economy.BuildableCategory) then
        return true
    end
    if EntityCategoryContains(categories.SILO, unit) and EntityCategoryContains(categories.STRUCTURE, unit) then
        return true
    end
    return false
end

EnergyActiveBuffCheck = MassActiveBuffCheck

-- Energy Weapon Bonus
---@param buff BlueprintBuff
---@param unit StructureUnit
---@return boolean
EnergyWeaponBuffCheck = function(buff, unit)
    for i = 1, unit:GetWeaponCount() do
        local wep = unit:GetWeapon(i)
        if wep:WeaponUsesEnergy() then
            return true
        end
    end
    return false
end

---@param buff BlueprintBuff
---@param unit StructureUnit
---@param instigator StructureUnit
EnergyWeaponBuffRemove = function(buff, unit, instigator)
    DefaultBuffRemove(buff, unit, instigator)
end

---@param buff BlueprintBuff
---@param unit StructureUnit
---@param instigator StructureUnit
EnergyWeaponBuffAffect = function(buff, unit, instigator)
    DefaultBuffAffect(buff, unit, instigator)
end

-- Weapon Rate of Fire
---@param buff BlueprintBuff
---@param unit StructureUnit
---@return boolean
RateOfFireBuffCheck = function(buff, unit)
    if unit:GetWeaponCount() > 0 then
        return true
    end
    return false
end

---@param buff BlueprintBuff
---@param unit StructureUnit
---@param instigator StructureUnit
RateOfFireBuffRemove = function(buff, unit, instigator)
    DefaultBuffRemove(buff, unit, instigator)
end

---@param buff BlueprintBuff
---@param unit StructureUnit
---@param instigator StructureUnit
RateOfFireBuffAffect = function(buff, unit, instigator)
    DefaultBuffAffect(buff, unit, instigator)
end

-- Energy Production
---@param buff BlueprintBuff
---@param unit StructureUnit
---@return boolean
EnergyProductionBuffCheck = function(buff, unit)
    local bp = unit:GetBlueprint()
    if bp.Economy.ProductionPerSecondEnergy and bp.Economy.ProductionPerSecondEnergy > 0 then
        return true
    end
    return false
end

---@param buff BlueprintBuff
---@param unit StructureUnit
---@param instigator StructureUnit
EnergyProductionBuffRemove = function(buff, unit, instigator)
    DefaultBuffRemove(buff, unit, instigator)
end

---@param buff BlueprintBuff
---@param unit StructureUnit
---@param instigator StructureUnit
EnergyProductionBuffAffect = function(buff, unit, instigator)
    DefaultBuffAffect(buff, unit, instigator)
end

-- Mass Production
---@param buff BlueprintBuff
---@param unit StructureUnit
---@return boolean
MassProductionBuffCheck = function(buff, unit)
    local bp = unit:GetBlueprint()
    if bp.Economy.ProductionPerSecondMass and bp.Economy.ProductionPerSecondMass > 0 then
        return true
    end
    return false
end

---@param buff BlueprintBuff
---@param unit StructureUnit
---@param instigator StructureUnit
MassProductionBuffRemove = function(buff, unit, instigator)
    DefaultBuffRemove(buff, unit, instigator)
end

---@param buff BlueprintBuff
---@param unit StructureUnit
---@param instigator StructureUnit
MassProductionBuffAffect = function(buff, unit, instigator)
    DefaultBuffAffect(buff, unit, instigator)
end