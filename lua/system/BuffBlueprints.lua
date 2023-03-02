---@declare-global
--****************************************************************************
--**
--**  File     :  /lua/system/BuffBlueprints.lua
--**
--**  Summary  :  Global buff table and blueprint methods
--**
--**  Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

-- Global list of all buffs found in the system.
---@type table<string, BlueprintBuff>
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

---@alias BuffEffectName
---| "Health"
---| "MaxHealth"
---| "Regen"
---| "Damage"
---| "DamageRadius"
---| "MaxRadius"
---| "MoveMult"
---| "WeaponsEnable"
---| "VisionRadius"
---| "RadarRadius"
---| "OmniRadius"
---| "BuildRate"
---| "EnergyActive"
---| "MassActive"
---| "EnergyMaintenance"
---| "MassMaintenance"
---| "EnergyProduction"
---| "MassProduction"
---| "EnergyWeapon"
---| "RateOfFire"

---@class BlueprintBuff.Effect
---@field Add number
---@field Floor number -- defaults to 0
---@field BPCeilings table<string, number> -- Take regen values from bp, keys have to match techCategory options
---@field Mult number
---@field DoNotFill boolean -- DoNotFill flag is set when we want to adjust the max health ONLY and not have the rest of the unit's HP affected to match. If it's not flagged, the unit's HP will be adjusted by the same amount and direction as the max

---@class BlueprintBuff
---@field name string
---@field DisplayName string
---@field BuffType string
---@field Stacks "ALWAYS"|"REPLACE"
---@field Duration number -- -1 for infinite duration
---@field EntityCategory CategoryName
---@field BuffCheckFunction fun(self: BlueprintBuff, unit: Unit): boolean
---@field OnBuffAffect fun(self: BlueprintBuff, unit: Unit, instigator: Unit)
---@field OnBuffRemove fun(self: BlueprintBuff, unit: Unit, instigator: Unit)
---@field Affects table<BuffEffectName, BlueprintBuff.Effect>
BuffDefMeta = {}
BuffDefMeta.__index = BuffDefMeta
BuffDefMeta.__call = function(...)
    if type(arg[2]) ~= 'table' then
        --LOG('Invalid BuffDefinition: ', repr(arg))
        return
    end

    if not arg[2].Name then
        --LOG('Missing name for buff definition: ',repr(arg))
        return
    end

    if InitialRegistration and Buffs[arg[2].Name] then
        WARN('Duplicate buff detected: ', arg[2].Name)
    end

    if not Buffs[arg[2].Name] then
        Buffs[arg[2].Name] = {}
    end

    --SPEW('Buff Registered: ', arg[2].Name)

    Buffs[arg[2].Name] = arg[2]
    return arg[2].Name
end

---@type fun(bp: BlueprintBuff): string
BuffBlueprint = {}
setmetatable(BuffBlueprint, BuffDefMeta)
