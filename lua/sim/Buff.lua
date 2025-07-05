----****************************************************************************
----**
----**  File     :  /lua/sim/buff.lua
----**
----**  Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************

---- The Unit's BuffTable for applied buffs looks like this:
----
---- Unit.Buffs = {
----    Affects = {
----        <AffectType> = {
----            <BuffName> = {
----                Count = i,
----                Add = X,
----                Mult = X,
----            }
----        }
----    }
----    BuffTable = {
----        <BuffType> = {
----            <BuffName> = {
----                Count = i,
----                Trash = trashbag,
----            }
----        }
----    }

---@alias BuffType
---| AdjacencyBuffType
---| CheatBuffType
---| EnhancementBuffType
---| OpBuffType
---| UniqueBuffType
---| VeterancyBuffType
---@alias BuffName
---| AdjacencyBuffName
---| CheatBuffName
---| EnhancementBuffName
---| OpBuffName
---| UniqueBuffName
---| VeterancyBuffName

---@alias UniqueBuffType
---| SelenBuffType
---@alias UniqueBuffName
---| SelenBuffName

--#region Buff stacking calculations

-- A key -> function table for buffs, uses the buffName parameter
local UniqueBuffs = {}

-- Dynamic ceilings with fallback values for sera regen field
local regenAuraDefaultCeilings = {
    TECH1 = 10,
    TECH2 = 15,
    TECH3 = 25,
    EXPERIMENTAL = 40,
    SUBCOMMANDER = 30
}

--- Calculates regen for a unit using mults as a multiplier of the unit's HP that is then added to the final regen value.
---@param unit Unit
---@param buffName BuffName
---@param affectBp BlueprintBuffAffectState
---@return number add
---@return number mult
local function regenAuraCalculate(unit, buffName, affectBp)
    local adds = 0

    if affectBp.Add and affectBp.Add ~= 0 then
        adds = adds + (affectBp.Add * affectBp.Count)
    end

    -- Take regen values from bp, keys have to match techCategory options
    local bpCeilings = affectBp.BPCeilings --[[@as table<TechCategory, number>]]

    local techCat = unit.Blueprint.TechCategory
    local ceil = bpCeilings[techCat] or regenAuraDefaultCeilings[techCat]

    local mult = affectBp.Mult
    if mult then
        local maxHealth = unit.Blueprint.Defense.MaxHealth
        for i = 1, affectBp.Count do
            local multHp = mult * maxHealth
            if ceil and multHp > ceil then multHp = ceil end
            adds = adds + multHp
        end
    end

    return adds, 1
end

--- A function that calculates buff add and mult values for a buff contributing to an "affect".
---@alias AffectCalculation fun(unit: Unit, affectBuffName: BuffName, affectBp: BlueprintBuffAffectState): add: number, mult: number

---@type table<BuffName, table<BuffName, AffectCalculation>>
UniqueAffectCalculation = {
    SeraphimACURegenAura = { Regen = regenAuraCalculate },
    SeraphimACUAdvancedRegenAura = { Regen = regenAuraCalculate },
}

--- Calculates the affect values from all the buffs a unit has for a given affect type.
---@param unit Unit
---@param buffName string
---@param affectType string
---@param initialVal number
---@param initialBool? boolean
---@return number, boolean
function BuffCalculate(unit, buffName, affectType, initialVal, initialBool)

    -- Check if we have a separate buff calculation system
    local uniqueBuff = UniqueBuffs[buffName]
    if uniqueBuff then
        return uniqueBuff(unit, buffName, affectType, initialVal, initialBool)
    end

    -- if not, do the typical buff computation

    local adds = 0
    local mults = 1.0
    local bool = initialBool or false
    local floor = 0

    if not unit.Buffs.Affects[affectType] then return initialVal, bool end

    for originBuffName, affectBp in unit.Buffs.Affects[affectType] do
        if affectBp.Floor then
            floor = affectBp.Floor
        end

        if not affectBp.Bool then
            bool = false
        else
            bool = true
        end

        local uniqueCalculation = UniqueAffectCalculation[originBuffName][affectType]
        if uniqueCalculation then
            local add, mult = uniqueCalculation(unit, originBuffName, affectBp)
            adds = adds + add
            mults = mults * mult
        else
            local add = affectBp.Add
            if add and add ~= 0 then
                adds = adds + (add * affectBp.Count)
            end

            local mult = affectBp.Mult
            if mult then
                for i = 1, affectBp.Count do
                    mults = mults * mult
                end
            end
        end
    end

    -- Adds are calculated first, then the mults.
    local returnVal = math.max((initialVal + adds) * mults, floor)

    return returnVal, bool
end

--#endregion

--#region Buff Effect functions

-- Function to affect the unit. Every time you want to affect a new part of unit, add it in here.
-- afterRemove is a bool that defines if this buff is affecting after the removal of a buff.
-- We reaffect the unit to make sure that buff type is recalculated accurately without the buff
-- that was on the unit. However, this doesn't work for stunned units because it's a fire-and-forget
-- type buff, not a fire-and-keep-track-of type buff.
BuffEffects = {
    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    ---@param instigator Unit # can be the unit itself
    ---@param afterRemove boolean
    Stun = function(buffDefinition, buffValues, unit, buffName, instigator, afterRemove) -- most dont use the last two args, so most don't have them. This is fine.
        if unit.ImmuneToStun or afterRemove then return end
        unit:SetStunned(buffDefinition.Duration or 1)
        if unit.Anims then
            for k, manip in unit.Anims do
                manip:SetRate(0)
            end
        end
    end,

    --- Quite confident that this one is broken
    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    ---@param instigator Unit # can be the unit itself
    Health = function(buffDefinition, buffValues, unit, buffName, instigator)
        -- Note: With health we don't actually look at the unit's table because it's an instant
        -- happening. We don't want to overcalculate something as pliable as health.
        local health = unit:GetHealth()
        local val = ((buffDefinition.Affects.Health.Add or 0) + health) * (buffDefinition.Affects.Health.Mult or 1)
        local healthadj = val - health

        if healthadj < 0 then
            -- fixme: DoTakeDamage shouldn't be called directly
            local data = {
                Instigator = instigator,
                Amount = -1 * healthadj,
                Type = buffDefinition.DamageType or 'Spell',
                Vector = VDiff(instigator:GetPosition(), unit:GetPosition()),
            }
            unit:DoTakeDamage(data)
        else
            unit:AdjustHealth(instigator, healthadj)
        end
    end,

    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    MaxHealth = function(buffDefinition, buffValues, unit, buffName)
        -- With this type of buff, the idea is to adjust the Max Health of a unit.
        -- The DoNotFill flag is set when we want to adjust the max ONLY and not have the
        --     rest of the unit's HP affected to match. If it's not flagged, the unit's HP
        --     will be adjusted by the same amount and direction as the max
        local unitbphealth = unit:GetBlueprint().Defense.MaxHealth or 1
        local val = BuffCalculate(unit, buffName, 'MaxHealth', unitbphealth)

        local oldmax = unit:GetMaxHealth()
        local difference = oldmax - unit:GetHealth()

        unit:SetMaxHealth(val)

        if not buffValues.DoNotFill and not unit.IsBeingTransferred then
            unit:SetHealth(unit, unit:GetMaxHealth() - difference)
        end
    end,

    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    Regen = function(buffDefinition, buffValues, unit, buffName)
        -- Adjusted to use a special case of adding mults and calculating the final value
        -- in BuffCalculate to fix bugs where adds and mults would clash or cancel
        local bpRegen = unit:GetBlueprint().Defense.RegenRate or 0
        local val = BuffCalculate(unit, buffName, 'Regen', bpRegen)

        unit:SetRegen(val)
    end,

    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    Damage = function(buffDefinition, buffValues, unit, buffName)
        for i = 1, unit:GetWeaponCount() do
            local wep = unit:GetWeapon(i)
            if wep.Label ~= 'DeathWeapon' and wep.Label ~= 'DeathImpact' then
                local wepbp = wep:GetBlueprint()
                local wepdam = wepbp.Damage
                local val = BuffCalculate(unit, buffName, 'Damage', wepdam)

                if val >= (math.abs(val) + 0.5) then
                    val = math.ceil(val)
                else
                    val = math.floor(val)
                end

                wep:ChangeDamage(val)
            end
        end
    end,

    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    DamageRadius = function(buffDefinition, buffValues, unit, buffName)
        for i = 1, unit:GetWeaponCount() do
            local wep = unit:GetWeapon(i)
            local wepbp = wep:GetBlueprint()
            local weprad = wepbp.DamageRadius
            local val = BuffCalculate(unit, buffName, 'DamageRadius', weprad)

            wep:SetDamageRadius(val)
        end
    end,

    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    MaxRadius = function(buffDefinition, buffValues, unit, buffName)
        for i = 1, unit:GetWeaponCount() do
            local wep = unit:GetWeapon(i)
            local wepbp = wep:GetBlueprint()
            local weprad = wepbp.MaxRadius
            local val = BuffCalculate(unit, buffName, 'MaxRadius', weprad)

            wep:ChangeMaxRadius(val)
        end
    end,

    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    MoveMult = function(buffDefinition, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'MoveMult', 1)
        unit:SetSpeedMult(val)
        unit:SetAccMult(val)
        unit:SetTurnMult(val)
    end,

    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    WeaponsEnable = function(buffDefinition, buffValues, unit, buffName)
        for i = 1, unit:GetWeaponCount() do
            local wep = unit:GetWeapon(i)
            local val, bool = BuffCalculate(unit, buffName, 'WeaponsEnable', 0, true)
            wep:SetWeaponEnabled(bool)
        end
    end,

    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    VisionRadius = function(buffDefinition, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'VisionRadius', unit:GetBlueprint().Intel.VisionRadius or 0)
        unit:SetIntelRadius('Vision', val)
    end,

    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    RadarRadius = function(buffDefinition, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'RadarRadius', unit:GetBlueprint().Intel.RadarRadius or 0)
        if not unit:IsIntelEnabled('Radar') then
            unit:InitIntel(unit.Army, 'Radar', val)
            unit:EnableIntel('Radar')
        else
            unit:SetIntelRadius('Radar', val)
            unit:EnableIntel('Radar')
        end

        if val <= 0 then
            unit:DisableIntel('Radar')
        end
    end,

    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    OmniRadius = function(buffDefinition, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'OmniRadius', unit:GetBlueprint().Intel.OmniRadius or 0)
        if not unit:IsIntelEnabled('Omni') then
            unit:InitIntel(unit.Army, 'Omni', val)
            unit:EnableIntel('Omni')
        else
            unit:SetIntelRadius('Omni', val)
            unit:EnableIntel('Omni')
        end

        if val <= 0 then
            unit:DisableIntel('Omni')
        end
    end,

    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    BuildRate = function(buffDefinition, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'BuildRate', unit:GetBlueprint().Economy.BuildRate or 1)
        unit:SetBuildRate(val)
    end,

    --#region Adjacency Buffs

    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    EnergyActive = function(buffDefinition, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'EnergyActive', 1)
        unit.EnergyBuildAdjMod = val
        unit:UpdateConsumptionValues()
    end,

    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    MassActive = function(buffDefinition, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'MassActive', 1)
        unit.MassBuildAdjMod = val
        unit:UpdateConsumptionValues()
    end,

    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    EnergyMaintenance = function(buffDefinition, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'EnergyMaintenance', 1)
        unit.EnergyMaintAdjMod = val
        unit:UpdateConsumptionValues()
    end,

    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    MassMaintenance = function(buffDefinition, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'MassMaintenance', 1)
        unit.MassMaintAdjMod = val
        unit:UpdateConsumptionValues()
    end,

    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    EnergyProduction = function(buffDefinition, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'EnergyProduction', 1)
        unit.EnergyProdAdjMod = val
        unit:UpdateProductionValues()
    end,

    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    MassProduction = function(buffDefinition, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'MassProduction', 1)
        unit.MassProdAdjMod = val
        unit:UpdateProductionValues()
    end,

    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    EnergyWeapon = function(buffDefinition, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'EnergyWeapon', 1)
        for i = 1, unit:GetWeaponCount() do
            local wep = unit:GetWeapon(i)
            if wep:WeaponUsesEnergy() then
                wep.AdjEnergyMod = val
            end
        end
    end,

    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    RateOfFire = function(buffDefinition, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'RateOfFire', 1)

        for i = 1, unit:GetWeaponCount() do
            local wep = unit:GetWeapon(i)
            local bp = wep:GetBlueprint()
            -- Set new rate of fire based on blueprint rate of fire
            wep:ChangeRateOfFire(bp.RateOfFire / val)
            wep.AdjRoFMod = val
        end
    end,

    --#endregion
}

local buffMissingWarnings = {}

--#endregion

--#region Functions for applying, removing, and checking buffs

---@param unit Unit
---@param buffName string
---@param instigator Unit
---@param afterRemove boolean
function BuffAffectUnit(unit, buffName, instigator, afterRemove)
    local buffDef = Buffs[buffName]

    local buffAffects = buffDef.Affects

    if buffDef.OnBuffAffect and not afterRemove then
        buffDef:OnBuffAffect(unit, instigator)
    end

    for atype, vals in buffAffects do
        if BuffEffects[atype] then
            BuffEffects[atype](buffDef, vals, unit, buffName, instigator, afterRemove)
        elseif not buffMissingWarnings[atype] then
            buffMissingWarnings[atype] = true
            WARN('Missing buff effect function ' .. tostring(atype))
        end
    end
end

--Removes buffs
---@param unit Unit
---@param buffName string
---@param removeAllCounts? boolean
---@param instigator? Unit
function RemoveBuff(unit, buffName, removeAllCounts, instigator)
    local def = Buffs[buffName]
    local unitBuff = unit.Buffs.BuffTable[def.BuffType][buffName]
    if not unitBuff.Count or unitBuff.Count <= 0 then
        -- This buff wasn't previously applied to the unit
        return
    end

    for atype, _ in def.Affects do
        local list = unit.Buffs.Affects[atype]
        if list and list[buffName] then
            -- If we're removing all buffs of this name, only remove as
            -- many affects as there are buffs since other buffs may have
            -- added these same affects.
            if removeAllCounts then
                list[buffName].Count = list[buffName].Count - unitBuff.Count
            else
                list[buffName].Count = list[buffName].Count - 1
            end

            if list[buffName].Count <= 0 then
                list[buffName] = nil
            end
        end
    end

    unitBuff.Count = unitBuff.Count - 1

    if removeAllCounts or unitBuff.Count <= 0 then
        -- unit:PlayEffect('RemoveBuff', buffName)
        unitBuff.Trash:Destroy()
        unit.Buffs.BuffTable[def.BuffType][buffName] = nil
    end

    if def.OnBuffRemove then
        def:OnBuffRemove(unit, instigator)
    end

    -- FIXME: This doesn't work because the magic sync table doesn't detect
    -- the change. Need to give all child tables magic meta tables too.
    if def.Icon then
        -- If the user layer was displaying an icon, remove it from the sync table
        local newTable = unit.Sync.Buffs
        table.removeByValue(newTable, buffName)
        unit.Sync.Buffs = table.copy(newTable)
    end

    BuffAffectUnit(unit, buffName, unit, true)
end

--Function to do work on the buff.  Apply it over time and in pulses.
---@param unit Unit
---@param buffName string
---@param instigator Unit
function BuffWorkThread(unit, buffName, instigator)
    local buffDef = Buffs[buffName]

    --Non-Pulsing Buff
    local totPulses = buffDef.DurationPulse

    if not totPulses then
        WaitSeconds(buffDef.Duration)
    else
        local pulse = 0
        local pulseTime = buffDef.Duration / totPulses

        while pulse <= totPulses and not unit.Dead do
            WaitSeconds(pulseTime)
            BuffAffectUnit(unit, buffName, instigator, false)
            pulse = pulse + 1
        end
    end

    RemoveBuff(unit, buffName)
end

---@param unit Unit
---@param buffName string
---@param trsh TrashBag
function PlayBuffEffect(unit, buffName, trsh)
    local def = Buffs[buffName]
    if not def.Effects then
        return
    end

    for k, fx in def.Effects do
        local bufffx = CreateAttachedEmitter(unit, 0, unit.Army, fx)
        if def.EffectsScale then
            bufffx:ScaleEmitter(def.EffectsScale)
        end
        trsh:Add(bufffx)
        unit.Trash:Add(bufffx)
    end
end

--- Function to apply a buff to a unit. This function is a fire-and-forget.
--- Apply this and it'll be applied over time if there is a duration.
---@param unit Unit
---@param buffName BuffName
---@param instigator? Unit
function ApplyBuff(unit, buffName, instigator)

    -- do not buff dead units
    if unit.Dead then
        return
    end

    -- do not buff insignificant / dummy units
    if EntityCategoryContains(categories.INSIGNIFICANTUNIT, unit) then
        return
    end

    instigator = instigator or unit

    --buff = table of buff data
    local def = Buffs[buffName]
    if not def then
        error("*ERROR: Tried to add a buff that doesn\'t exist! Name: " .. buffName, 2)
        return
    end

    if def.EntityCategory then
        local cat = ParseEntityCategory(def.EntityCategory)
        if not EntityCategoryContains(cat, unit) then
            return
        end
    end

    if def.BuffCheckFunction then
        if not def:BuffCheckFunction(unit) then
            return
        end
    end

    local ubt = unit.Buffs.BuffTable

    -- We're going to need some naughty, hard-coded stuff here for a regen aura edge case where
    -- we need the advanced version to take precedence over the lower version, but not vice versa.
    if buffName == 'SeraphimACURegenAura' and ubt['COMMANDERAURA_AdvancedRegenAura']['SeraphimACUAdvancedRegenAura'] then return end

    if buffName == 'SeraphimACUAdvancedRegenAura' and ubt['COMMANDERAURA_RegenAura']['SeraphimACURegenAura'] then
        for key, bufftbl in ubt['COMMANDERAURA_RegenAura'] do
            RemoveBuff(unit, key, true)
        end
    end

    if def.Stacks == 'REPLACE' and ubt[def.BuffType] then
        for key, bufftbl in ubt[def.BuffType] do
            RemoveBuff(unit, key, true)
        end
    end

    -- If add this buff to the list of buffs the unit has becareful of stacking buffs.
    if not ubt[def.BuffType] then
        ubt[def.BuffType] = {}
    end

    if def.Stacks == 'IGNORE' and ubt[def.BuffType] and not table.empty(ubt[def.BuffType]) then
        return
    end

    local data = ubt[def.BuffType][buffName]
    if not data then
        --- Container for buff state on a unit.
        ---@class BuffData
        ---@field Count integer
        ---@field Trash TrashBag
        ---@field BuffName BuffName

        -- This is a new buff (as opposed to an additional one being stacked)
        data = {
            Count = 1,
            Trash = TrashBag(),
            BuffName = buffName,
        }
        ubt[def.BuffType][buffName] = data
    else
        -- This buff is already on the unit so stack another by incrementing the
        -- counts. data.Count is how many times the buff has been applied
        data.Count = data.Count + 1

    end

    local uaffects = unit.Buffs.Affects
    if def.Affects then
        for k, v in def.Affects do
            -- Don't save off 'instant' type affects like health and energy
            if k ~= 'Health' and k ~= 'Energy' then
                if not uaffects[k] then
                    uaffects[k] = {}
                end

                if not uaffects[k][buffName] then
                    -- This is a new affect.
                    local affectdata = {
                        BuffName = buffName,
                        Count = 1,
                    }
                    for buffkey, buffval in v do
                        affectdata[buffkey] = buffval
                    end
                    uaffects[k][buffName] = affectdata
                else
                    -- This affect is already there, increment the count
                    uaffects[k][buffName].Count = uaffects[k][buffName].Count + 1
                end
            end
        end
    end

    -- If the buff has a duration, then
    if def.Duration and def.Duration > 0 then
        local thread = ForkThread(BuffWorkThread, unit, buffName, instigator)
        unit.Trash:Add(thread)
        data.Trash:Add(thread)
    end

    PlayBuffEffect(unit, buffName, data.Trash)

    ubt[def.BuffType][buffName] = data

    if def.OnApplyBuff then
        def:OnApplyBuff(unit, instigator)
    end

    BuffAffectUnit(unit, buffName, instigator, false)
end

---@param unit Unit
---@param buffName string
---@return boolean
function HasBuff(unit, buffName)
    local def = Buffs[buffName]
    if not def then
        return false
    end
    return unit.Buffs.BuffTable[def.BuffType][buffName] ~= nil
end

--#endregion

--#region Debug functions

--- Prints the `Buffs` table of the currently selected units
_G.PrintBuffs = function()
    local selection = DebugGetSelection()
    for k, unit in selection do
        if unit.Buffs then
            LOG('Buffs = ', repr(unit.Buffs))
        end
    end
end

--#endregion
