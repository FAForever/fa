-----------------------------------------------------------------
-- File     : /lua/game.lua
-- Authors  : John Comes, HUSSAR
-- Summary  : Script full of overall game functions
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

---@class UnitRestrictions
---@field Global table<BlueprintId, boolean>
---@field PerArmy table<BlueprintId, boolean>[]



-- This file is used by both sim and UI code. It should therefore at
-- no moment use logic that is not available in both. Any pull request that 
-- introduces logic that is not functional in both the ui and the sim will 
-- be rejected.

FireState = {
    RETURN_FIRE = 0,
    HOLD_FIRE = 1,
    GROUND_FIRE = 2,
}

VeteranDefault = {
    Level1 = 25,
    Level2 = 100,
    Level3 = 250,
    Level4 = 500,
    Level5 = 1000,
}

--- Return the total time (in seconds), energy, and mass it will take for the given
--- builder to create a unit of type target_bp.
--- targetData may also be an "Enhancement" section of a units blueprint rather than
--- a full blueprint.
---
--- Modified to calculate the cost of an upgrade. The third argument is the economy section of
--- the unit that is currently upgrading into the new unit. We subtract that cost from the cost
--- of the unit that is being built
---
--- In order to keep backwards compatibility, there is a new option in the blueprint economy section.
--- if DifferentialUpgradeCostCalculation is set to true, the base upgrade cost will be subtracted
---@param builder Builder
---@param targetData table
---@param upgradeBaseData UnitBlueprintEconomy
---@return number time
---@return number energy
---@return number mass
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

    -- Apply penalties/bonuses to effective costs
    local time_mod = builder.BuildTimeModifier or 0
    local energy_mod = builder.EnergyModifier or 0
    local mass_mod = builder.MassModifier or 0

    buildtime = math.max(buildtime * (100 + time_mod) * 0.01, 0.1)
    energy = math.max(energy * (100 + energy_mod) * 0.01, 0)
    mass = math.max(mass * (100 + mass_mod) * 0.01, 0)

    return buildtime / rate, energy, mass
end

-- Re-structured and improved performance of checking for restricted units by
-- storing tables with ids of restricted units instead of evaluating an unit
-- each time against restricted categories

-- Table with presently restricted Unit IDs
local restrictions =  {
    Global = {}, -- Set via UnitsManager (ScenarioInfo.Options.RestrictedCategories)
    PerArmy = {}, -- Set in ScenarioName_Script.lua
}

-- Stores info about blueprints using Unit IDs
local bps = {
    upgradeable = {}, -- Table with blueprints that can be upgraded, e.g. T2 shields
    ids = {}, -- Table with identifiers of all blueprints, e.g. xab1401 - Aeon Paragon
    Ignored = false, -- Set by map scripts to ignore restrictions temporarily
}

-- Function for converting categories to string
local ToString = import("/lua/sim/categoryutils.lua").ToString

-- Gets army index for specified army name
-- e.g. GetArmyIndex('ARMY_1') -> 1
---@param army Army
---@return number
function GetArmyIndex(army)
    local armyType = type(army)
    if armyType == 'number' then
        return army
    elseif armyType == 'string' then
        local armySetup = ScenarioInfo.ArmySetup[army]
        if armySetup then
            army = armySetup.ArmyIndex
            if army then
                return army
            end
        end
    end
    error('ERROR cannot find army index for army name: "' .. tostring(army) ..'"')
end

--- Adds restriction of units with specified Entity categories, e.g. 'categories.TECH2 * categories.AIR'
--- e.g. AddRestriction(categories.TECH2, 1) -> restricts all T2 units for army 1
--- e.g. AddRestriction(categories.TECH2) -> restricts all T2 units for all armies
---@param cats EntityCategory
---@param army Army
function AddRestriction(cats, army)
    if type(cats) ~= 'userdata' then
        WARN('Game.AddRestriction() called with invalid categories "' .. ToString(cats) .. '" '
          .. 'instead of category expression, e.g. categories.LAND ')
        return
    end

    if army then -- Convert army name to army index
       army = GetArmyIndex(army)
    end

    ResolveRestrictions(true, cats, army)
end

--- Removes restriction of units with specified Entity categories, e.g. 'categories.TECH1 * categories.UEF'
--- e.g. RemoveRestriction(categories.TECH2, 1) -> removes all T2 units restriction for army 1
--- e.g. RemoveRestriction(categories.TECH2) -> removes all T2 units restriction for all armies
---@param cats EntityCategory
---@param army Army
function RemoveRestriction(cats, army)
    if type(cats) ~= 'userdata' then
        WARN('Game.RemoveRestriction() called with invalid categories "' .. ToString(cats) .. '" '
          .. 'instead of category expression, e.g. categories.LAND ')
        return
    end

    if army then -- Convert army name to army index
       army = GetArmyIndex(army)
    end

    ResolveRestrictions(false, cats, army)
end

--- Noggles whether or not to ignore all restrictions
--- Note, this function is useful when trying to transfer restricted units between armies
---@param isIgnored boolean
function IgnoreRestrictions(isIgnored)
    bps.Ignored = isIgnored
end

--- Checks whether or not a given blueprint ID is restricted by
--- global restrictions (set in UnitsManager) or by
--- army restrictions (set in Scenario Script)
--- e.g. IsRestricted('xab1401', 1) -> checks if Aeon Paragon is restricted for army with index 1
--- Note that global restrictions take precedence over restrictions set on specific armies
---@param unitId UnitId
---@param army number
---@return boolean
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

--- Gets a table with ids of restricted units {Global = {}, PerArmy = {}}
---@return UnitRestrictions
function GetRestrictions()
    return restrictions
end

--- Sets a table with ids of restricted units {Global = {}, PerArmy = {}}
---@param blueprintIDs UnitRestrictions
function SetRestrictions(blueprintIDs)
    restrictions = blueprintIDs
end

--- Sorts unit blueprints based on build priority
---@param bp1 UnitBlueprint
---@param bp2 UnitBlueprint
---@return boolean
local function SortUnits(bp1, bp2)
    local v1 = bp1.BuildIconSortPriority or bp1.StrategicIconSortPriority
    local v2 = bp2.BuildIconSortPriority or bp2.StrategicIconSortPriority
    if v1 >= v2 then
        return false
    else
        return true
    end
end

-- Checks for valid unit blueprints (not projectiles/effects)
local IsValidUnit = import("/lua/ui/lobby/unitsanalyzer.lua").IsValidUnit

--- Gets blueprints that can be upgraded, e.g. MEX, Shield, Radar structures
---@return UnitBlueprint[]
local function GetUnitsUpgradable()
    local units = {}

    if not bps.ids then
        WARN('ERROR - Trying to fetch upgradable units from an empty list. That is impossible!')
    end

    for _, id in bps.ids do
        local bp = __blueprints[id]

        -- Check for valid/upgradeable blueprints
        if bp and bp.General and IsValidUnit(bp, id) and
            bp.General.UpgradesFrom ~= '' and
            bp.General.UpgradesFrom ~= 'none' then

            if not bp.CategoriesHash['BUILTBYTIER1ENGINEER'] and
               not bp.CategoriesHash['BUILTBYTIER2ENGINEER'] and
               not bp.CategoriesHash['BUILTBYTIER3ENGINEER'] and
               not bp.CategoriesHash['BUILTBYTIER3COMMANDER'] then

               local unit = table.deepcopy(bp)
               unit.id = id -- Save id for a reference
               table.insert(units, unit)
            end
        end
    end

    -- Ensure units are sorted in increasing order of upgrades
    -- This increase performance when checking for breaks in upgrade-chain
    table.sort(units, SortUnits)

    return units
end

-- Gets ids of valid units
local function GetUnitsIds()
    local units = {}
    for id, bp in __blueprints do
        if IsValidUnit(bp, id) then
            table.insert(units, id)
        end
    end
    return units
end

--- Resolves category restrictions to a table with ids of restricted units
--- e.g. restrictions = {categories.TECH1} ->
---@param toggle boolean
---@param cats EntityCategory
---@param army number
function ResolveRestrictions(toggle, cats, army)
    -- Initialize blueprints info only once
    if table.empty(bps.ids) or table.empty(bps.upgradeable) then
        bps.ids = GetUnitsIds()
        bps.upgradeable = GetUnitsUpgradable()
    end

    -- Find ids of units restricted by global categories
    if not toggle or not army then
        local ids = EntityCategoryFilterDown(cats, bps.ids)
        for _, id in ids do
            restrictions.Global[id] = toggle
        end
    end

    if army then
        -- Find ids of units restricted for each army
        if not restrictions.PerArmy[army] then
           restrictions.PerArmy[army] = {}
        end

        local ids = EntityCategoryFilterDown(cats, bps.ids)
        for _, id in ids do
           restrictions.PerArmy[army][id] = toggle
        end
    end

    -- Check for breaks in upgrade-chain of upgradeable units,
    -- e.g. T2 MEX restriction should also restrict T3 MEX
    -- We only want to do this when restricting, not releasing.
    if toggle then
        for _, bp in bps.upgradeable do
            local from = bp.General.UpgradesFrom

            -- Check if source blueprint is restricted by global restriction
            if restrictions.Global[from] then
               restrictions.Global[bp.id] = toggle
            end

            -- Check if source blueprint is restricted by army restriction
            if restrictions.PerArmy[army][from] then
               restrictions.PerArmy[army][bp.id] = toggle
            end
        end
    end
end