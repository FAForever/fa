---@declare-global
--****************************************************************************
--**
--**  File     :  /lua/system/BuffBlueprints.lua
--**
--**  Summary  :  Global buff table and blueprint methods
--**
--**  Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

--- Global list of all buffs found in the system
---@type table<BuffName, BlueprintBuff>
Buffs = {}

-- Buff blueprints are created by invoking BuffBlueprint() with a table
-- as the buff data. Buffs can be defined in any module at any time.
-- e.g.
--
-- BuffBlueprint {
--    Name = HealingOverTime1,
--    DisplayName = 'Healing Over Time',
--    [...]
--    Affects = {
--        Health = {
--            Add = 10,
--        },
--    },
-- }

---@alias BuffAffectName
---| "BuildRate"
---| "Damage"
---| "DamageRadius"
---| "EnergyActive"
---| "EnergyMaintenance"
---| "EnergyWeapon"
---| "EnergyProduction"
---| "Health"
---| "MassActive"
---| "MassMaintenance"
---| "MassProduction"
---| "MaxHealth"
---| "MaxRadius"
---| "MoveMult"
---| "MassProduction"
---| "OmniRadius"
---| "RadarRadius"
---| "RateOfFire"
---| "Regen"
---| "Stun"
--| "StunAlt" # upcoming
---| "VisionRadius"
---| "WeaponsEnable"

---@alias BuffStackType "ALWAYS" | "REPLACE" | "IGNORE"


--- An "affect" a buff can have. This might more correctly have been called an "effect", however
--- that would have created a naming inconsistency with the buff blueprint field and caused
--- confusion with its "effects" (as in visual effects).
--- Better to leave "affect" meaning buff effect and "effect" meaning visual effect.
---@class BlueprintBuffAffect
---@field Add? number
--- List of ceilings to use depending on the `techCategory` of the unit. Takes precedence over
--- `Ceil` but falls back on it if no ceiling for the teach category is found.
---@field BPCeilings? table<string, number>
--- List of floors to use depending on the `techCategory` of the unit. Takes precedence over `Floor`
--- but falls back on it if no floor for the teach category is found.
---@field BPFloors? table<string, number>
---@field Ceil? number
---@field Floor? number
---@field Mult? number
--- if we don't want unit properties connected the affect type to also change (e.g. changing
--- `MaxHealth` also increases `Health` unless this flag is set)
---@field DoNotFill? boolean

--- The blueprint definition of a buff, as stored in `Buffs` (with the buff name as the key).
---
--- Generally, adding a buff to a unit will apply a certain number of buff effects (that we call
--- "Affects", to not be confused with "Effects" meaning visual effects) that change a property of
--- the unit based on the affect type by some measure. The exact result depends on two sets of
--- stacking rules:
---  * One determines if the buff is applied based on its stacking properties and the other buffs of
--- the same buff type (not to be confused with a buff's affects' types) already present on the unit
---  * The other sums together all affects of the same affect type from each buff based on each
--- affects combining properties
---@class BlueprintBuff
---@field Name BuffName
---@field DamageType? DamageType defaults to `"Spell"`
---@field DisplayName string
---@field BuffType BuffType
---@field Stacks? BuffStackType treated as `"ALWAYS"` if absent
--- when to remove the buff (non-positive or absent for infinite duration)
---@field Duration? number
--- when using `Duration`, the interval that the buff is applied again over
---@field DurationPulse? number
--- if present, only units of this will be affected
---@field EntityCategory? UnparsedCategory
--- If present, this function will be called to determine if the buff should be applied for a unit.
---@field BuffCheckFunction? fun(self: BlueprintBuff, unit: Unit): boolean
---@field OnBuffAffect? fun(self: BlueprintBuff, unit: Unit, instigator: Unit)
---@field OnBuffRemove? fun(self: BlueprintBuff, unit: Unit, instigator: Unit)
--- table of how the buff will affect the units (not VFX)
---@field Affects? table<BuffAffectName, BlueprintBuffAffect>
--- table of VFX (not the how the buff affects units)
---@field Effects? FileName[]
---@field EffectsScale? number
BuffDefMeta = {}
BuffDefMeta.__index = BuffDefMeta
BuffDefMeta.__call = function(...)
    local buffDef = arg[2] --[[@as BlueprintBuff]]
    if type(buffDef) ~= 'table' then
        --WARN('Invalid BuffDefinition: ', repr(arg))
        return
    end

    local buffName = buffDef.Name
    if not buffName then
        --WARN('Missing name for buff definition: ', repr(arg))
        return
    end

    if InitialRegistration and Buffs[buffName] then
        WARN('Duplicate buff detected: ', buffName)
    end

    --SPEW('Buff Registered: ', buffName)

    Buffs[buffName] = buffDef
    return buffName
end

---@type fun(bp: BlueprintBuff): BuffName
BuffBlueprint = {}
setmetatable(BuffBlueprint, BuffDefMeta)
