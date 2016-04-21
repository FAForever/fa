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

-- table with restricted categories/expressions, e.g. ('categories.TECH2 * categories.AIR') 
local restrictions =  {
    Global = {}, -- set via UnitsManager (ScenarioInfo.Options.RestrictedCategories)
    PerArmy = {}, -- set in ScenarioName_Script.lua
}
-- stores info about blueprints
local bps = {
    -- table with blueprints that can be upgraded, e.g. T2 shields
    upgradeable = {},
    -- table with identifiers of all blueprints, e.g. xab1401 - Aeon Paragon
    ids = {},
    Ignored = false,
}

-- function for converting categories to string
local ToString = import('/lua/sim/CategoryUtils.lua').ToString

-- gets army index for specified army name
-- e.g. GetArmyIndex('ARMY_1') -> 1
function GetArmyIndex(armyName)
    local index = nil
    if type(armyName) == 'number' then
        index = armyName
    elseif type(armyName) == 'string' then
        --table.print(ScenarioInfo.ArmySetup[armyName], armyName)
        if ScenarioInfo.ArmySetup[armyName] then
            index = ScenarioInfo.ArmySetup[armyName].ArmyIndex 
        end
    end
    
    if index == nil then
        error('ERROR cannot find army index for army name: "' .. tostring(armyName) ..'"')
    end
    return index
end

-- adds restriction of units with specified Entity categories, e.g. 'categories.TECH2 * categories.AIR'
-- e.g. AddRestriction(categories.TECH2, 1) -> restricts all T2 units for army 1
-- e.g. AddRestriction(categories.TECH2)    -> restricts all T2 units for all armies
function AddRestriction(cats, army)
    if type(cats) ~= 'userdata' then
        WARN('Game.AddRestriction() called with invalid categories "' .. ToString(cats) .. '" '
          .. 'instead of category expression, e.g. categories.LAND ' )
        return
    end

    if army then -- convert army name to army index
       army = GetArmyIndex(army)
    end

    ResolveRestrictions(true, cats, army)
end

-- removes restriction of units with specified Entity categories, e.g. 'categories.TECH1 * categories.UEF'
-- e.g. RemoveRestriction(categories.TECH2, 1) -> removes all T2 units restriction for army 1
-- e.g. RemoveRestriction(categories.TECH2)    -> removes all T2 units restriction for all armies
function RemoveRestriction(cats, army)
    if type(cats) ~= 'userdata' then
        WARN('Game.RemoveRestriction() called with invalid categories "' .. ToString(cats) .. '" '
          .. 'instead of category expression, e.g. categories.LAND ' )
        return
    end

    if army then -- convert army name to army index
       army = GetArmyIndex(army)
    end

    ResolveRestrictions(false, cats, army)
end

-- toggles whether or not to ignore all restrictions
-- note this function is useful when trying to transfer restricted units between armies
function IgnoreRestrictions(isIgnored)
    bps.Ignored = isIgnored
end

-- checks whether or not a given blueprint ID is restricted by
-- * global restrictions (set in UnitsManager) or by
-- * army restrictions (set in Scenario Script)
-- e.g. IsRestricted('xab1401', 1) -> checks if Aeon Paragon is restricted for army with index 1
-- note that global restrictions take precedence over restrictions set on specific armies
function IsRestricted(unitId, army)
    if bps.Ignored then 
        return false 
    end

    if restrictions.Global[unitId] then
       return true
    end
    
    if restrictions.PerArmy[army] then
       return restrictions.PerArmy[army][unitId] or false
    end

    return false 
end 
-- gets a table with ids of restricted units { Global = {}, PerArmy = {} }
function GetRestrictions()
    return restrictions
end
-- sets a table with ids of restricted units { Global = {}, PerArmy = {} }
function SetRestrictions(blueprintIDs)
    restrictions = blueprintIDs
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
-- check for valid unit blueprints (not projectiles/effects)
local function IsValidUnit(bp, id)
    if bp and (string.len(id) > 4) and not string.find(id, '/') then
        return true
    end
    return false
end
-- gets blueprints that can be upgraded, e.g. MEX, Shield, Radar structures
local function GetUnitsUpgradable()
    local units = {}  
    for id, bp in __blueprints or {} do 
        -- check for valid/upgradeable blueprints 
        if bp and bp.General and IsValidUnit(bp, id) and 
         ((bp.General.UpgradesFrom ~= '' and 
           bp.General.UpgradesFrom ~= 'none') or 
          (bp.General.UpgradesTo ~= '' and 
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
-- gets ids of valid units
local function GetUnitsIds()
    local units = {}
    for id, bp in __blueprints or {} do
        if IsValidUnit(bp, id) then
            table.insert(units, id)
        end
    end
    return units
end
-- resolves category restrictions to a table with ids of restricted units
-- e.g. restrictions = { categories.TECH1 } -> 
function ResolveRestrictions(toggle, cats, army)
    -- initialize blueprints info only once
    if table.getsize(bps.ids) == 0 or
       table.getsize(bps.upgradeable) == 0 then
        bps.ids = GetUnitsIds()
        bps.upgradeable = GetUnitsUpgradable()
    end
    
    -- find ids of units restricted by global categories
    if not toggle or not army then
        local ids = EntityCategoryFilterDown(cats, bps.ids)
        for _, id in ids do
           restrictions.Global[id] = toggle
        end
    end

    if army then
        -- find ids of units restricted for each army
        if not restrictions.PerArmy[army] then
           restrictions.PerArmy[army] = {}
        end
        local ids = EntityCategoryFilterDown(cats, bps.ids)
        for _, id in ids do
           restrictions.PerArmy[army][id] = toggle
        end
    end

    -- check for breaks in upgrade-chain of upgradeable units,
    -- e.g. T2 MEX restriction should also restrict T3 MEX
    -- We only want to do this when restricting, not releasing.
    if toggle then
        for _, bp in bps.upgradeable do
            local from = bp.General.UpgradesFrom
            -- check if source blueprint is restricted by global restriction
            if restrictions.Global[from] then
               restrictions.Global[bp.id] = toggle
            end
            -- check if source blueprint is restricted by army restriction
            if restrictions.PerArmy[army][from] then 
               restrictions.PerArmy[army][bp.id] = toggle
            end
        end
    end
end