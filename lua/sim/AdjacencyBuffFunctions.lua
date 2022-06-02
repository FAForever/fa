--****************************************************************************
--**
--**  File     :  /lua/sim/AdjacencyBuffFunctions.lua
--**
--**  Copyright � 2008 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

------------------------------------------------------------------------------------------------------------------------------------
---- DEFAULT FUNCTIONS FOR ADJACENCY
------------------------------------------------------------------------------------------------------------------------------------

DefaultBuffRemove = function(buff, unit, instigator)
    unit:DestroyAdjacentEffects(instigator)
end

DefaultBuffAffect = function(buff, unit, instigator)
    unit:CreateAdjacentEffect(instigator)
end



-- Energy Build Bonus - Energy Active Consumption

EnergyBuildBuffCheck = function(buff, unit)
    local bp = unit:GetBlueprint()
    if bp.Economy.BuildableCategory and table.getn(bp.Economy.BuildableCategory) > 0 then
        return true
    end
    if EntityCategoryContains(categories.SILO, unit) and EntityCategoryContains(categories.STRUCTURE, unit) then
        return true
    end
    return false
end

EnergyBuildBuffRemove = function(buff, unit, instigator)
    DefaultBuffRemove(buff, unit, instigator)
end

EnergyBuildBuffAffect = function(buff, unit, instigator)
    DefaultBuffAffect(buff, unit, instigator)
end



-- Mass Build Bonus - Mass Active Consumption

MassBuildBuffCheck = function(buff, unit)
    local bp = unit:GetBlueprint()
    if bp.Economy.BuildableCategory and table.getn(bp.Economy.BuildableCategory) > 0 then
        return true
    end
    if EntityCategoryContains(categories.SILO, unit) and EntityCategoryContains(categories.STRUCTURE, unit) then
        return true
    end
    return false
end

MassBuildBuffRemove = function(buff, unit, instigator)
    DefaultBuffRemove(buff, unit, instigator)
end

MassBuildBuffAffect = function(buff, unit, instigator)
    DefaultBuffAffect(buff, unit, instigator)
end



-- Energy Maintenance Bonus

EnergyMaintenanceBuffCheck = function(buff, unit)
    local bp = unit:GetBlueprint()
    if bp.Economy.MaintenanceConsumptionPerSecondEnergy or unit.EnergyMaintenanceConsumptionOverride then
        return true
    end
    return false
end

EnergyMaintenanceBuffRemove = function(buff, unit, instigator)
    DefaultBuffRemove(buff, unit, instigator)
end

EnergyMaintenanceBuffAffect = function(buff, unit, instigator)
    DefaultBuffAffect(buff, unit, instigator)
end



-- Energy Weapon Bonus

EnergyWeaponBuffCheck = function(buff, unit)
    for i = 1, unit:GetWeaponCount() do
        local wep = unit:GetWeapon(i)
        if wep:WeaponUsesEnergy() then
            return true
        end
    end
    return false
end

EnergyWeaponBuffRemove = function(buff, unit, instigator)
    DefaultBuffRemove(buff, unit, instigator)
end

EnergyWeaponBuffAffect = function(buff, unit, instigator)
    DefaultBuffAffect(buff, unit, instigator)
end



-- Weapon Rate of Fire

RateOfFireBuffCheck = function(buff, unit)
    if unit:GetWeaponCount() > 0 then
        return true
    end
    return false
end

RateOfFireBuffRemove = function(buff, unit, instigator)
    DefaultBuffRemove(buff, unit, instigator)
end

RateOfFireBuffAffect = function(buff, unit, instigator)
    DefaultBuffAffect(buff, unit, instigator)
end



-- Energy Production

EnergyProductionBuffCheck = function(buff, unit)
    local bp = unit:GetBlueprint()
    if bp.Economy.ProductionPerSecondEnergy and bp.Economy.ProductionPerSecondEnergy > 0 then
        return true
    end
    return false
end

EnergyProductionBuffRemove = function(buff, unit, instigator)
    DefaultBuffRemove(buff, unit, instigator)
end

EnergyProductionBuffAffect = function(buff, unit, instigator)
    DefaultBuffAffect(buff, unit, instigator)
end



-- Mass Production

MassProductionBuffCheck = function(buff, unit)
    local bp = unit:GetBlueprint()
    if bp.Economy.ProductionPerSecondMass and bp.Economy.ProductionPerSecondMass > 0 then
        return true
    end
    return false
end

MassProductionBuffRemove = function(buff, unit, instigator)
    DefaultBuffRemove(buff, unit, instigator)
end

MassProductionBuffAffect = function(buff, unit, instigator)
    DefaultBuffAffect(buff, unit, instigator)
end

