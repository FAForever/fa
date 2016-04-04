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

local restriction =  {}
-- table with categories/expressions ('categories.TECH1 * categories.UEF') set: 
-- in UnitsManager (ScenarioInfo.Options.RestrictedCategories) or 
-- in Scenario Script, e.g. MapName_script.lua -> ScenarioFramework.AddRestriction(army, categories.TECH2) 
restriction.categories = {}
-- table with ids of restricted units that are resolved base on restriction.categories
restriction.blueprints = {}
-- flag for notifying whether or not execute the ResolveRestrictions() function
restriction.dirty = false

-- table with cached evaluation of restricted units
local evaluatedUnits = {}

--- adds game restriction of units with passed Entity categories, e.g. 'categories.TECH1 * categories.UEF'
--- NOTE do not call this function to set build restriction on an unit (e.g. factories/carriers)
function AddRestriction(categories)
    
    if type(categories) ~= 'userdata' then
        error('*ERROR: Game.AddRestriction() called with invalid argument: ' .. type(categories) .. ' type, '
           .. 'instead of userdata type, e.g. categories.LAND ' )
    end
    -- reset units cache every time new restriction is added
    evaluatedUnits = {}       
    -- save new restricted categories with an unique key
    -- in order to limit duplicated restrictions
    local key = repr(categories)
    if not restriction.categories[key] then 
        restriction.categories[key] = categories
        restriction.dirty = true
        ResolveRestrictions()
    end
end
-- removes game restriction of units with passed Entity categories, e.g. 'categories.TECH1 * categories.UEF'
function RemoveRestriction(categories)

    if type(categories) ~= 'userdata' then
        error('*ERROR: Game.RemoveRestriction() called with invalid argument: ' .. type(categories) .. ' type, '
           .. 'instead of userdata type, e.g. categories.LAND ' )
    end
    -- check for existing restriction
    local key = repr(categories)
    if restriction.categories[key] then 
       restriction.categories[key] = false
       restriction.dirty = true
       ResolveRestrictions()
    end
end
-- returns true if the given blueprint ID is restricted by UnitsManager or Scenario Script
-- otherwise returns false (blueprint not restricted)
function IsRestricted(blueprintID)
    return restriction.blueprints[blueprintID]
end
-- NOTE that above function is much quicker than commented out function below

-- returns true if the given unit is restricted by UnitsManager or Scenario Script
-- otherwise returns false (unit not restricted)
-- @param unit - is class object not an unit's blueprint or blueprint ID
--function IsRestricted(unit)
--    if not unit then
--        error('*ERROR: Game.UnitRestricted(Unit) called with nil argument.')
--    end
--    local unitID = unit:GetUnitId() 
--    if not unitID then
--        error('*ERROR: Game.UnitRestricted(Unit) called without unit class argument.')
--    end
--    local isBanned = false
--    if evaluatedUnits[unitID] ~= nil then
--        isBanned =  evaluatedUnits[unitID]
--        --LOG('Game.UnitRestricted: ' .. tostring(isBanned) .. ' - unitID ' .. unitID .. ' - cached' ) 
--        return isBanned
--    end
--    for key, categories in restriction.categories do
--        if categories then
--            -- checks for intersection of this unit's categories with restricted categories
--            isBanned = EntityCategoryContains(categories * ParseEntityCategory(unitID), unit)
--            --LOG('Game.UnitRestricted: ' .. tostring(isBanned) .. ' - unitID ' .. unitID  .. ' - '  .. key) 
--            if isBanned then break end 
--        end
--    end
--    evaluatedUnits[unitID] = isBanned     
--    --LOG('Game.UnitRestricted: ' .. tostring(isBanned) .. ' - unitID ' .. unitID ) 
--    return isBanned
--end  

-- gets a table with ids of restricted units
function GetRestrictions()
    return restriction.blueprints
end
-- sets a table with ids of restricted units
function SetRestrictions(blueprintIDs)
    LOG('Game.SetUnitRestrictions: ' .. table.getsize(restriction.blueprints) .. ' -> ' .. table.getsize(blueprintIDs)  ) 
    restriction.blueprints = blueprintIDs
end

local function SortUnits(bp1, bp2) 
    local v1 = bp1.BuildIconSortPriority or bp1.StrategicIconSortPriority
    local v2 = bp2.BuildIconSortPriority or bp2.StrategicIconSortPriority
    if v1 >= v2 then
        return false
    else
        return true
    end
end
-- gets blueprints of upgradeable units, e.g. MEX, Shield, Radar structures
local function GetUnitsUpgradable(blueprints)
    local units = {}  
    for id, bp in blueprints or {} do 
        -- check for valid/upgradeable blueprints 
        if bp ~= nil and bp.General and (string.len(id) > 4) and
         ((bp.General.UpgradesFrom and 
           bp.General.UpgradesFrom ~= 'none') or 
          (bp.General.UpgradesTo and 
           bp.General.UpgradesTo ~= 'none')) then

            local unit = table.deepcopy(bp)
            unit.id = id -- save id for a reference
            table.insert(units, unit) 
        end
    end
    -- ensure units are sorted in increasing order of upgrades
    -- this increase performance when checking for breaks in upgrade-chain
    table.sort(units, SortUnits)  
    return units
end
-- resolves category restrictions to a table with ids of restricted units
-- e.g. restrictions = { categories.TECH1 } -> 
function ResolveRestrictions()
 
    if not restriction.dirty then return end 
    restriction.dirty = false
    -- reset restriction of blueprints
    restriction.blueprints = {}
    local blueprintIDs = table.keys(__blueprints)

    for key, categories in restriction.categories do
        -- get ids of units restricted by the current categories 
        local ids = EntityCategoryFilterDown(categories, blueprintIDs)
        -- convert restricted units to lookup table
        for _, id in ids do
           restriction.blueprints[id] = true
        end 
    end         
    -- check for breaks in upgrade-chain, 
    -- e.g. T2 MEX restriction should also restrict T3 MEX
    local upgradeable = GetUnitsUpgradable(__blueprints)
    for id, bp in upgradeable do 
        if bp and restriction.blueprints[bp.General.UpgradesFrom] then 
           restriction.blueprints[bp.id] = true
        end
    end
end