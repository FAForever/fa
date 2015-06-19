-- ****************************************************************************
-- **
-- **  File     :  /lua/game.lua
-- **  Author(s): John Comes
-- **
-- **  Summary  : Script full of overall game functions
-- **
-- **  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

VeteranDefault = {
    Level1 = 25,
    Level2 = 100,
    Level3 = 250,
    Level4 = 500,
    Level5 = 1000,
}


local BuffFieldBlueprint = import('/lua/sim/BuffField.lua').BuffFieldBlueprint
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- -- SERAPHIM BUFF FIELDS
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

BuffFieldBlueprint {                         -- Seraphim ACU Restoration
    Name = 'SeraphimACURegenBuffField',
    AffectsUnitCategories = 'ALLUNITS',
    AffectsAllies = false,
    AffectsVisibleEnemies = false,
    AffectsOwnUnits = true,
    AffectsSelf = true,
    DisableInTransport = true,
    InitiallyEnabled = false,
    MaintenanceConsumptionPerSecondEnergy = 0,
    Radius = 15,
    Buffs = {
        'SeraphimACURegenAura',
    },
}

BuffFieldBlueprint {                         -- Seraphim ACU Advanced Restoration
    Name = 'SeraphimAdvancedACURegenBuffField',
    AffectsUnitCategories = 'ALLUNITS',
    AffectsAllies = false,
    AffectsVisibleEnemies = false,
    AffectsOwnUnits = true,
    AffectsSelf = true,
    DisableInTransport = true,
    InitiallyEnabled = false,
    MaintenanceConsumptionPerSecondEnergy = 0,
    Radius = 15,
    Buffs = {
        'SeraphimAdvancedACURegenAura',
    },
}



-- Return the total time (in seconds), energy, and mass it will take for the given
-- builder to create a unit of type target_bp.
-- 
-- targetData may also be an "Enhancement" section of a units blueprint rather than
-- a full blueprint.

-- 
-- Modified by Rienzilla 2/5/2013
-- 
-- Modified to calculate the cost of an upgrade. The third argument is the economy section of 
-- the unit that is currently upgrading into the new unit. We substract that cost from the cost 
-- of the unit that is being built
-- 
-- In order to keep backwards compatibility, there is a new option in the blueprint economy section.
-- if DifferentialUpgradeCostCalculation is set to true, the base upgrade cost will be substracted

function GetConstructEconomyModel(builder, targetData, upgradeBaseData)

   local builder_bp = builder:GetBlueprint()
   
   -- 'rate' here is how fast we build relative to a unit with build rate of 1
   local rate = builder:GetBuildRate()
   
   local buildtime = targetData.BuildTime or 0.1
   local mass = targetData.BuildCostMass or 0
   local energy = targetData.BuildCostEnergy or 0
   
   if upgradeBaseData and targetData.DifferentialUpgradeCostCalculation then

      --LOG("Doing differential upgrade cost calculation")
      --LOG(time, " ", mass, " ", energy)

      -- We cant make a differential on buildtime. Not sure why but if we do it yields incorrect results. So just mass and energy
      mass = mass - upgradeBaseData.BuildCostMass
      energy = energy - upgradeBaseData.BuildCostEnergy

      if mass < 0 then mass = 0 end
      if energy < 0 then energy = 0 end

      --LOG(time, " ", mass, " ", energy)
   end

   -- apply penalties/bonuses to effective buildtime
   local time_mod = builder.BuildTimeModifier or 0
   buildtime = buildtime * (100 + time_mod)*.01
   if buildtime<.1 then buildtime = .1 end
   
   -- apply penalties/bonuses to effective energy cost
   local energy_mod = builder.EnergyModifier or 0
   energy = energy * (100 + energy_mod)*.01
   if energy<0 then energy = 0 end
   
   -- apply penalties/bonuses to effective mass cost
   local mass_mod = builder.MassModifier or 0
   mass = mass * (100 + mass_mod)*.01
   if mass<0 then mass = 0 end
   
   return buildtime/rate, energy, mass
end

-- An EntityCategory set representing the banned units for this game.
local restrictedCategorySet

--- Returns true if the given unitId is banned from this game, true otherwise.
-- Dynamically created due to hotness. Default behaviour is nop - no restrictions.
UnitRestricted = function() return false end

function SetRestrictions(categorySet)
    local _UnitRestricted_cache = {}
    local restrictedCategorySet = categorySet

    UnitRestricted = function(unitId, unit)
        if _UnitRestricted_cache[unitId] ~= nil then
            return _UnitRestricted_cache[unitId]
        end

        -- Does the intersection of this unit's singleton category with the banned set contain the
        -- singleton category?
        local isBanned = EntityCategoryContains(restrictedCategorySet * ParseEntityCategory(unitId), unit)
        _UnitRestricted_cache[unitId] = isBanned

        return isBanned
    end
end
