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
   -- 'rate' here is how fast we build relative to a unit with build rate of 1
   local rate = builder:GetBuildRate()
   
   local buildtime = targetData.BuildTime or 0.1
   local mass = targetData.BuildCostMass or 0
   local energy = targetData.BuildCostEnergy or 0
   
   if upgradeBaseData and targetData.DifferentialUpgradeCostCalculation then
      -- We cant make a differential on buildtime. Not sure why but if we do it yields incorrect
      -- results. So just mass and energy.
      mass = math.max(mass - upgradeBaseData.BuildCostMass, 0)
      energy = math.max(energy - upgradeBaseData.BuildCostEnergy, 0)
   end

   -- apply penalties/bonuses to effective buildtime
   local time_mod = builder.BuildTimeModifier or 0
   buildtime = math.max(buildtime * (100 + time_mod) * 0.01, 0.1)

   -- apply penalties/bonuses to effective energy cost
   local energy_mod = builder.EnergyModifier or 0
   energy = math.max(energy * (100 + energy_mod) * 0.01, 0)
   
   -- apply penalties/bonuses to effective mass cost
   local mass_mod = builder.MassModifier or 0
   mass = math.max(mass * (100 + mass_mod) * 0.01, 0)

   return buildtime / rate, energy, mass
end

-- table with restrictions/expressions ('categories.TECH1 * UEF') set: 
-- 1 in UnitsManager (ScenarioInfo.Options.RestrictedCategories) or 
-- 2 in Scenario script (MapName_script.lua) a set of EntityCategory set representing the banned units for this game.
local restrictions =  {}
-- table with cached evaluation of restricted units
local evaluatedUnits = {}

--- adds game restriction of units with Entity categories, e.g. 'categories.TECH1 * categories.UEF - '
--- NOTE do not call this function to set build restriction on an unit (e.g. factories/carriers)
function AddRestriction(categories)
    
    if type(categories) ~= 'userdata' then
        WARN('Game.AddRestriction() called with invalid argument type: ' .. type(categories))
    end
    -- reset units cache every time new restriction is added
    evaluatedUnits = {} 
    --LOG('Game.Restrictions adding ' .. tostring(categorySet)) 
     
    -- save unique new restricted categories with previously added restrictions
    local key = repr(categories)
    if not restrictions[key] then 
        restrictions[key] = categories
    end 
end
-- returns true if the given unitID is banned from this game
-- otherwise returns false (unit not restricted)
function UnitRestricted(unit)
    if not restrictions then
        return false
    end
    if not unit then
        WARN('Game.UnitRestricted(Unit) called with nil argument.')
        return false
    end
    local unitID = unit:GetUnitId() 
    if unitID == nil then
        WARN('Game.UnitRestricted(Unit) called without unit class argument.')
        return false
    end
    
    local isBanned = false
    if evaluatedUnits[unitID] ~= nil then
        isBanned =  evaluatedUnits[unitID]
        --LOG('Game.UnitRestricted: ' .. tostring(isBanned) .. ' - unitID ' .. unitID .. ' - cached' ) 
        return isBanned
    end
    --table.print(restrictions, 'Game.Restrictions')
    for key, categories in restrictions do
        -- checks for intersection of this unit's categories with restricted categories
        isBanned = EntityCategoryContains(categories * ParseEntityCategory(unitID), unit)
        --LOG('Game.UnitRestricted: ' .. tostring(isBanned) .. ' - unitID ' .. unitID  .. ' - '  .. key) 
        if isBanned then break end 
    end
    evaluatedUnits[unitID] = isBanned     
    --LOG('Game.UnitRestricted: ' .. tostring(isBanned) .. ' - unitID ' .. unitID ) 
    return isBanned
end 

