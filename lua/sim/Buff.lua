--#****************************************************************************
--#**
--#**  File     :  /lua/sim/buff.lua
--#**
--#**  Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
--#****************************************************************************

--# The Unit's BuffTable for applied buffs looks like this:
--#
--# Unit.Buffs = {
--#    Affects = {
--#        <AffectType (Regen/MaxHealth/etc)> = {
--#            BuffName = {
--#                Count = i,
--#                Add = X,
--#                Mult = X,
--#            }
--#        }
--#    }
--#    BuffTable = {
--#        <BuffType (LEVEL/CATEGORY)> = {
--#            BuffName = {
--#                Count = i,
--#                Trash = trashbag,
--#            }
--#        }
--#    }

--Function to apply a buff to a unit.
--This function is a fire-and-forget.  Apply this and it'll be applied over time if there is a duration.
function ApplyBuff(unit, buffName, instigator)
    if unit.Dead then
        return
    end

    instigator = instigator or unit

    --buff = table of buff data
    local def = Buffs[buffName]
    if not def then
        error("*ERROR: Tried to add a buff that doesn\'t exist! Name: ".. buffName, 2)
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

    if def.Stacks == 'IGNORE' and ubt[def.BuffType] and table.getsize(ubt[def.BuffType]) > 0 then
        return
    end

    local data = ubt[def.BuffType][buffName]
    if not data then
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
        for k,v in def.Affects do
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

--Function to do work on the buff.  Apply it over time and in pulses.
function BuffWorkThread(unit, buffName, instigator)
    local buffTable = Buffs[buffName]

    --Non-Pulsing Buff
    local totPulses = buffTable.DurationPulse

    if not totPulses then
        WaitSeconds(buffTable.Duration)
    else
        local pulse = 0
        local pulseTime = buffTable.Duration / totPulses

        while pulse <= totPulses and not unit.Dead do
            WaitSeconds(pulseTime)
            BuffAffectUnit(unit, buffName, instigator, false)
            pulse = pulse + 1
        end
    end

    RemoveBuff(unit, buffName)
end

--Function to affect the unit.  Everytime you want to affect a new part of unit, add it in here.
--afterRemove is a bool that defines if this buff is affecting after the removal of a buff.
--We reaffect the unit to make sure that buff type is recalculated accurately without the buff that was on the unit.
--However, this doesn't work for stunned units because it's a fire-and-forget type buff, not a fire-and-keep-track-of type buff.
function BuffAffectUnit(unit, buffName, instigator, afterRemove)
    local buffDef = Buffs[buffName]

    local buffAffects = buffDef.Affects

    if buffDef.OnBuffAffect and not afterRemove then
        buffDef:OnBuffAffect(unit, instigator)
    end

    for atype, vals in buffAffects do
        if atype == 'Health' then
            --Note: With health we don't actually look at the unit's table because it's an instant happening.  We don't want to overcalculate something as pliable as health.

            local health = unit:GetHealth()
            local val = ((buffAffects.Health.Add or 0) + health) * (buffAffects.Health.Mult or 1)
            local healthadj = val - health

            if healthadj < 0 then
                -- fixme: DoTakeDamage shouldn't be called directly
                local data = {
                    Instigator = instigator,
                    Amount = -1 * healthadj,
                    Type = buffDef.DamageType or 'Spell',
                    Vector = VDiff(instigator:GetPosition(), unit:GetPosition()),
                }
                unit:DoTakeDamage(data)
            else
                unit:AdjustHealth(instigator, healthadj)
            end
        elseif atype == 'MaxHealth' then
            -- With this type of buff, the idea is to adjust the Max Health of a unit.
            -- The DoNotFill flag is set when we want to adjust the max ONLY and not have the
            --     rest of the unit's HP affected to match. If it's not flagged, the unit's HP
            --     will be adjusted by the same amount and direction as the max
            local unitbphealth = unit:GetBlueprint().Defense.MaxHealth or 1
            local val = BuffCalculate(unit, buffName, 'MaxHealth', unitbphealth)

            local oldmax = unit:GetMaxHealth()
            local difference = oldmax - unit:GetHealth()

            unit:SetMaxHealth(val)

            if not vals.DoNotFill and not unit.IsBeingTransferred then
                unit:SetHealth(unit, unit:GetMaxHealth() - difference)
            end
        elseif atype == 'Regen' then
            -- Adjusted to use a special case of adding mults and calculating the final value
            -- in BuffCalculate to fix bugs where adds and mults would clash or cancel
            local bpRegen = unit:GetBlueprint().Defense.RegenRate or 0
            local val = BuffCalculate(unit, nil, 'Regen', bpRegen)

            unit:SetRegen(val)
        elseif atype == 'Damage' then
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
        elseif atype == 'DamageRadius' then
            for i = 1, unit:GetWeaponCount() do

                local wep = unit:GetWeapon(i)
                local wepbp = wep:GetBlueprint()
                local weprad = wepbp.DamageRadius
                local val = BuffCalculate(unit, buffName, 'DamageRadius', weprad)

                wep:SetDamageRadius(val)
            end
        elseif atype == 'MaxRadius' then
            for i = 1, unit:GetWeaponCount() do

                local wep = unit:GetWeapon(i)
                local wepbp = wep:GetBlueprint()
                local weprad = wepbp.MaxRadius
                local val = BuffCalculate(unit, buffName, 'MaxRadius', weprad)

                wep:ChangeMaxRadius(val)
            end
        elseif atype == 'MoveMult' then
            local val = BuffCalculate(unit, buffName, 'MoveMult', 1)
            unit:SetSpeedMult(val)
            unit:SetAccMult(val)
            unit:SetTurnMult(val)
        elseif atype == 'Stun' and not afterRemove then
            unit:SetStunned(buffDef.Duration or 1, instigator)
            if unit.Anims then
                for k, manip in unit.Anims do
                    manip:SetRate(0)
                end
            end
        elseif atype == 'WeaponsEnable' then
            for i = 1, unit:GetWeaponCount() do
                local wep = unit:GetWeapon(i)
                local val, bool = BuffCalculate(unit, buffName, 'WeaponsEnable', 0, true)
                wep:SetWeaponEnabled(bool)
            end
        elseif atype == 'VisionRadius' then
            local val = BuffCalculate(unit, buffName, 'VisionRadius', unit:GetBlueprint().Intel.VisionRadius or 0)
            unit:SetIntelRadius('Vision', val)

        elseif atype == 'RadarRadius' then
            local val = BuffCalculate(unit, buffName, 'RadarRadius', unit:GetBlueprint().Intel.RadarRadius or 0)
            if not unit:IsIntelEnabled('Radar') then
                unit:InitIntel(unit:GetArmy(),'Radar', val)
                unit:EnableIntel('Radar')
            else
                unit:SetIntelRadius('Radar', val)
                unit:EnableIntel('Radar')
            end

            if val <= 0 then
                unit:DisableIntel('Radar')
            end
        elseif atype == 'OmniRadius' then
            local val = BuffCalculate(unit, buffName, 'OmniRadius', unit:GetBlueprint().Intel.OmniRadius or 0)
            if not unit:IsIntelEnabled('Omni') then
                unit:InitIntel(unit:GetArmy(),'Omni', val)
                unit:EnableIntel('Omni')
            else
                unit:SetIntelRadius('Omni', val)
                unit:EnableIntel('Omni')
            end

            if val <= 0 then
                unit:DisableIntel('Omni')
            end
        elseif atype == 'BuildRate' then
            local val = BuffCalculate(unit, buffName, 'BuildRate', unit:GetBlueprint().Economy.BuildRate or 1)
            unit:SetBuildRate(val)
        -------- ADJACENCY BELOW --------
        elseif atype == 'EnergyActive' then
            local val = BuffCalculate(unit, buffName, 'EnergyActive', 1)
            unit.EnergyBuildAdjMod = val
            unit:UpdateConsumptionValues()
        elseif atype == 'MassActive' then
            local val = BuffCalculate(unit, buffName, 'MassActive', 1)
            unit.MassBuildAdjMod = val
            unit:UpdateConsumptionValues()
        elseif atype == 'EnergyMaintenance' then
            local val = BuffCalculate(unit, buffName, 'EnergyMaintenance', 1)
            unit.EnergyMaintAdjMod = val
            unit:UpdateConsumptionValues()
        elseif atype == 'MassMaintenance' then
            local val = BuffCalculate(unit, buffName, 'MassMaintenance', 1)
            unit.MassMaintAdjMod = val
            unit:UpdateConsumptionValues()
        elseif atype == 'EnergyProduction' then
            local val = BuffCalculate(unit, buffName, 'EnergyProduction', 1)
            unit.EnergyProdAdjMod = val
            unit:UpdateProductionValues()
        elseif atype == 'MassProduction' then
            local val = BuffCalculate(unit, buffName, 'MassProduction', 1)
            unit.MassProdAdjMod = val
            unit:UpdateProductionValues()
        elseif atype == 'EnergyWeapon' then
            local val = BuffCalculate(unit, buffName, 'EnergyWeapon', 1)
            for i = 1, unit:GetWeaponCount() do
                local wep = unit:GetWeapon(i)
                if wep:WeaponUsesEnergy() then
                    wep.AdjEnergyMod = val
                end
            end
        elseif atype == 'RateOfFire' then
            local val = BuffCalculate(unit, buffName, 'RateOfFire', 1)

            for i = 1, unit:GetWeaponCount() do
                local wep = unit:GetWeapon(i)
                local bp = wep:GetBlueprint()
                -- Set new rate of fire based on blueprint rate of fire
                wep:ChangeRateOfFire(bp.RateOfFire / val)
                wep.AdjRoFMod = val
            end
        elseif atype ~= 'Stun' then
            WARN("*WARNING: Tried to apply a buff with an unknown affect type of " .. atype .. " for buff " .. buffName)
        end
    end
end

-- Calculates the buff from all the buffs of the same time the unit has.
function BuffCalculate(unit, buffName, affectType, initialVal, initialBool)

    local adds = 0
    local mults = 1.0
    local multsTotal = 0 -- Used only for regen buffs
    local bool = initialBool or false
    local floor = 0
    local ceil = 0
    -- Dynamic ceilings with fallback values for sera regen field
    local ceilings = {
        TECH1 = 10,
        TECH2 = 15,
        TECH3 = 25,
        TECH4 = 40
    }

    if not unit.Buffs.Affects[affectType] then return initialVal, bool end

    for k, v in unit.Buffs.Affects[affectType] do
        if v.Add and v.Add ~= 0 then
            adds = adds + (v.Add * v.Count)
        end

        if v.Floor then
            floor = v.Floor
        end

        if v.CeilT1 then
            ceilings['TECH1'] = v.CeilT1
        end
        if v.CeilT2 then
            ceilings['TECH2'] = v.CeilT2
        end
        if v.CeilT3 then
            ceilings['TECH3'] = v.CeilT3
        end
        if v.CeilT4 then
            ceilings['TECH4'] = v.CeilT4
        end

        ceil = ceilings[unit.techCategory]

        if v.Mult then
            if affectType == 'Regen' then
                -- Regen mults use MaxHp as base, so should always be <1

                -- If >1 it's probably deliberate, but silly, so let's bail. If it's THAT deliberate
                -- they will remove this
                if v.Mult > 1 then WARN('Regen mult too high, should be <1, for unit ' .. unit:GetUnitId() .. ' and buff ' .. buffName) return end

                -- GPG default for mult is 1. To avoid changing loads of scripts for now, let's do this
                if v.Mult ~= 1 then
                    local maxHealth = unit:GetBlueprint().Defense.MaxHealth
                    for i=1,v.Count do
                        multsTotal = multsTotal + math.min((v.Mult * maxHealth), ceil)
                    end
                end
            else
                for i=1,v.Count do
                    mults = mults * v.Mult
                end
            end
        end

        if not v.Bool then
            bool = false
        else
            bool = true
        end
    end

    -- Adds are calculated first, then the mults.
    local returnVal = math.max((initialVal + adds + multsTotal) * mults, floor)

    return returnVal, bool
end

--Removes buffs
function RemoveBuff(unit, buffName, removeAllCounts, instigator)
    local def = Buffs[buffName]
    local unitBuff = unit.Buffs.BuffTable[def.BuffType][buffName]
    if not unitBuff.Count or unitBuff.Count <= 0 then
        -- This buff wasn't previously applied to the unit
        return
    end

    for atype,_ in def.Affects do
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
        table.removeByValue(newTable,buffName)
        unit.Sync.Buffs = table.copy(newTable)
    end

    BuffAffectUnit(unit, buffName, unit, true)
end

function HasBuff(unit, buffName)
    local def = Buffs[buffName]
    if not def then
        return false
    end
    return unit.Buffs.BuffTable[def.BuffType][buffName] ~= nil
end

function PlayBuffEffect(unit, buffName, trsh)
    local def = Buffs[buffName]
    if not def.Effects then
        return
    end

    for k, fx in def.Effects do
        local bufffx = CreateAttachedEmitter(unit, 0, unit:GetArmy(), fx)
        if def.EffectsScale then
            bufffx:ScaleEmitter(def.EffectsScale)
        end
        trsh:Add(bufffx)
        unit.Trash:Add(bufffx)
    end
end

--
-- DEBUG FUNCTIONS
--
_G.PrintBuffs = function()
    local selection = DebugGetSelection()
    for k,unit in selection do
        if unit.Buffs then
            LOG('Buffs = ', repr(unit.Buffs))
        end
    end
end
