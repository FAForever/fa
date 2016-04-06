-- ==========================================================================================
-- * File     : /lua/game.lua
-- * Authors  : John Comes, HUSSAR
-- * Summary  : Script full of overall game functions
-- * Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ==========================================================================================

VeteranDefault = {
    Level1 = 25,
    Level2 = 100,
    Level3 = 250,
    Level4 = 500,
    Level5 = 1000,
}

local BuffFieldBlueprint = import('/lua/sim/BuffField.lua').BuffFieldBlueprint

-- SERAPHIM BUFF FIELDS
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
-- the unit that is currently upgrading into the new unit. We subtract that cost from the cost 
-- of the unit that is being built
-- 
-- In order to keep backwards compatibility, there is a new option in the blueprint economy section.
-- if DifferentialUpgradeCostCalculation is set to true, the base upgrade cost will be subtracted
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

-- HUSSAR re-structured and improved performance of checking for restricted units by
-- storing tables with ids of restricted units instead of evaluating an unit 
-- each time against restricted categories 
local restricted =  {
-- tables with categories/expressions ('categories.TECH2 * categories.AIR') 
   Categories = { 
        Global = {}, -- set via UnitsManager (ScenarioInfo.Options.RestrictedCategories)
        Armies = {}  -- set in ScenarioName_Script.lua
   },
-- tables with units ids that are restricted globally and/or for specific army 
   Blueprints = { 
        Global = {}, --  auto-generated base on restricted.Categories.Global
        Armies = {}  --  auto-generated base on restricted.Categories.Armies
   }, 
}
local ToString = import('/lua/sim/CategoryUtils.lua').ToString

-- adds game restriction of units with passed Entity categories, e.g. 'categories.TECH2 * categories.AIR'
-- e.g. AddRestriction(categories.TECH2, 1) -> restricts all T2 units for army 1
-- e.g. AddRestriction(categories.TECH2)    -> restricts all T2 units for all armies
function AddRestriction(categories, army)

    if type(categories) ~= 'userdata' then
        WARN('Game.AddRestriction() called with invalid categories "' .. ToString(categories) .. '" '
          .. 'instead of category expression, e.g. categories.LAND ' )
        return
    end
    -- save new restricted categories with an unique key
    -- in order to limit duplicated restrictions
    local key = repr(categories)
    if army ~= nil then -- army restriction
        if restricted.Categories.Armies[army] == nil then
           restricted.Categories.Armies[army] = { }
        end
        restricted.Categories.Armies[army][key] = categories
    else -- global restriction
        restricted.Categories.Global[key] = categories 
    end
    
    ResolveRestrictions()
end
-- removes game restriction of units with passed Entity categories, e.g. 'categories.TECH1 * categories.UEF'
-- e.g. RemoveRestriction(categories.TECH2, 1) -> removes all T2 units restriction for army 1
-- e.g. RemoveRestriction(categories.TECH2)    -> removes all T2 units restriction for all armies
function RemoveRestriction(categories, army)

    if type(categories) ~= 'userdata' then
        WARN('Game.RemoveRestriction() called with invalid categories "' .. ToString(categories) .. '" '
          .. 'instead of category expression, e.g. categories.LAND ' )
        return
    end
    -- check for existing restriction
    local key = repr(categories)

    if army ~= nil then -- army restriction
        if restricted.Categories.Armies[army] then
           restricted.Categories.Armies[army][key] = false 
        end
    else -- global restriction
        restricted.Categories.Global[key] = false 
    end
    
    ResolveRestrictions()
end
-- checks whether or not a given blueprint ID is restricted by
-- * global restrictions (set in UnitsManager) or by
-- * army restrictions (set in Scenario Script)
-- e.g. IsRestricted('xab1401', 1) -> checks if Aeon Paragon is restricted for army with index 1
-- note that global restrictions take precedence over restrictions set on specific armies
function IsRestricted(unitId, armyIndex)

    if restricted.Blueprints.Global[unitId] then
       return true
    end
    
    if restricted.Blueprints.Armies[armyIndex] then
       return restricted.Blueprints.Armies[armyIndex][unitId] or false
    end

    return false 
end 
-- gets a table with ids of restricted units { Global = {}, Armies = {} }
function GetRestrictions()
    return restricted.Blueprints
end
-- sets a table with ids of restricted units { Global = {}, Armies = {} }
function SetRestrictions(blueprintIDs)
    restricted.Blueprints = blueprintIDs
end
-- sorts unit blueprints based on build priority
local function SortUnits(bp1, bp2) 
    local v1 = bp1.BuildIconSortPriority or bp1.StrategicIconSortPriority
    local v2 = bp2.BuildIconSortPriority or bp2.StrategicIconSortPriority
    if v1 >= v2 then
        return false
    else
        return true
    end
end
-- gets blueprints that can be upgraded, e.g. MEX, Shield, Radar structures
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
    -- reset restriction of blueprints
    restricted.Blueprints = { Global = {}, Armies = {} }
    local blueprintIDs = table.keys(__blueprints)
    local upgradeable = GetUnitsUpgradable(__blueprints)

    -- find ids of units restricted by global Categories
    for key, category in restricted.Categories.Global do
        local ids = EntityCategoryFilterDown(category, blueprintIDs)
        for _, id in ids do
           restricted.Blueprints.Global[id] = true
        end 
    end
    -- find ids of units restricted for each army 
    for index, categories in restricted.Categories.Armies do 
         
        if restricted.Blueprints.Armies[index] == nil then
           restricted.Blueprints.Armies[index] = { }
        end
        for key, category in categories do
            local ids = EntityCategoryFilterDown(category, blueprintIDs)
            for _, id in ids do
               restricted.Blueprints.Armies[index][id] = true
            end
        end 
    end
    -- check for breaks in upgrade-chain, 
    -- e.g. T2 MEX restriction should also restrict T3 MEX
    for _, bp in upgradeable do 
        local from = bp.General.UpgradesFrom

        if restricted.Blueprints.Global[from] then 
           restricted.Blueprints.Global[bp.id] = true
        end
        for index, army in restricted.Blueprints.Armies do
            if restricted.Blueprints.Armies[index][from] then 
               restricted.Blueprints.Armies[index][bp.id] = true
            end
        end
    end 
end