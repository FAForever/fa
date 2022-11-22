---@declare-global
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
----        <AffectType (Regen/MaxHealth/etc)> = {
----            BuffName = {
----                Count = i,
----                Add = X,
----                Mult = X,
----            }
----        }
----    }
----    BuffTable = {
----        <BuffType (LEVEL/CATEGORY)> = {
----            BuffName = {
----                Count = i,
----                Trash = trashbag,
----            }
----        }
----    }

---@alias BuffAffectType
---| "BuildRate"
---| "Damage"
---| "DamageRadius"
---| "EnergyActive"
---| "EnergyWeapon"
---| "EnergyMaintenance"
---| "EnergyProduction"
---| "Health"
---| "MassActive"
---| "MassMaintenance"
---| "MaxHealth"
---| "MaxRadius"
---| "MoveMult"
---| "MassProduction"
---| "OmniRadius"
---| "RadarRadius"
---| "RateOfFire"
---| "Regen"
---| "Stun"
---| "StunAlt"
---| "VisionRadius"
---| "WeaponsEnable"


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


---@alias EnhancementBuffType
---| ACUEnhancementBuffType
---| SCUEnhancementBuffType

---@alias ACUEnhancementBuffType
---| "ACUBUILDRATE"
---| "ACUCLOAKBONUS"
---| "ACUSTEALTHBONUS"
---| "ACUUPGRADEDMG"
---| "COMMANDERAURA"
---| "COMMANDERAURAFORSELF"
---| "DamageStabilization"

---@alias SCUEnhancementBuffType
---| "SCUBUILDRATE"
---| "SCUCLOAKBONUS"
---| "SCUREGENERATEBONUS"
---| "SCUREGENRATE"
---| "SCUUPGRADEDMG"


-- These are only created when needed
---@alias EnhancementBuffName
---| ACUEnhancementBuffName
---| SCUEnhancementBuffName

---@alias ACUEnhancementBuffName
---| AeonACUEnhancementBuffName
---| CybranACUEnhancementBuffName
---| UEFACUEnhancementBuffName
---| SeraphimACUEnhancementBuffName

---@alias SCUEnhancementBuffName
---| AeonSCUEnhancementBuffName
---| CybranSCUEnhancementBuffName
--| UEFSCUEnhancementBuffName # there are none
---| SeraphimSCUEnhancementBuffName


---@alias UniqueBuffType
---| SelenBuffType

---@alias UniqueBuffName
---| SelenBuffName





--- Function to apply a buff to a unit.
--- This function is a fire-and-forget. Apply this and it'll be applied over time if there is a duration.
---@param unit Unit
---@param buffName string
---@param instigator Unit
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
    local buff = Buffs[buffName]
    if not buff then
        error("*ERROR: Tried to add a buff that doesn\'t exist! Name: " .. buffName, 2)
        return
    end

    if buff.EntityCategory then
        local cat = ParseEntityCategory(buff.EntityCategory)
        if not EntityCategoryContains(cat, unit) then
            return
        end
    end

    if buff.BuffCheckFunction and not buff:BuffCheckFunction(unit) then
        return
    end

    local unitBuffs = unit.Buffs.BuffTable
    local buffType = buff.BuffType
    local unitBuffsOfType = unitBuffs[buffType]

    if buff.Stacks == "REPLACE" and unitBuffsOfType then
        -- Check for existing buffs that replace this one due to a higher replacement priority
        local priority = buff.ReplacePriority
        for _, existingBuff in unitBuffsOfType do
            local existingPri = existingBuff.ReplacePriority
            -- Don't add the buff if it has a priority when we don't, or when its is higher
            if existingPri and (not priority or existingPri > priority) then
                return
            end
        end
        -- Otherwise, replace any existing buffs
        for key in unitBuffsOfType do
            RemoveBuff(unit, key, true)
        end
    end

    if buff.Stacks == 'IGNORE' and not table.empty(unitBuffsOfType) then
        return
    end

    -- If adding this buff to the list of buffs the unit has be careful of stacking buffs
    if not unitBuffsOfType then
        unitBuffsOfType = {}
        unitBuffs[buffType] = unitBuffsOfType
    end

    local buffData = unitBuffsOfType[buffName]
    if not buffData then
        -- This is a new buff (as opposed to an additional one being stacked)
        buffData = {
            Count = 1,
            Trash = TrashBag(),
            BuffName = buffName,
        }
        unitBuffsOfType[buffName] = buffData
    else
        -- This buff is already on the unit so stack another by incrementing the
        -- counts. data.Count is how many times the buff has been applied
        buffData.Count = buffData.Count + 1
    end

    -- link the buff to the each affect
    -- TODO we really don't need to duplicate the data from the buff -> affect lookup and affect -> buff lookup
    local unitAffects = unit.Buffs.Affects
    if buff.Affects then
        for affectType, buffAffect in buff.Affects do
            -- Don't save off 'instant' type affects like health and energy
            if affectType == 'Health' or affectType == 'Energy' then
                continue
            end

            local uAffect = unitAffects[affectType]
            if not uAffect then
                uAffect = {}
                unitAffects[affectType] = uAffect
            end

            local affectData = uAffect[buffName]
            if not affectData then
                -- This is a new affect
                affectData = {
                    BuffName = buffName,
                    Count = 1,
                }
                for buffkey, buffval in buffAffect do
                    affectData[buffkey] = buffval
                end
                uAffect[buffName] = affectData
            else
                -- This affect is already there, increment the count
                affectData.Count = affectData.Count + 1
            end
        end
    end

    -- If the buff has a duration, then
    if buff.Duration and buff.Duration > 0 then
        local thread = ForkThread(BuffWorkThread, unit, buffName, instigator)
        unit.Trash:Add(thread)
        buffData.Trash:Add(thread)
    end

    -- note that Effects are different from Affects
    PlayBuffEffect(unit, buffName, buffData.Trash)

    unitBuffsOfType[buffName] = buffData

    if buff.OnApplyBuff then
        buff:OnApplyBuff(unit, instigator)
    end

    BuffAffectUnit(unit, buffName, instigator, false)
end

--- Function to do work on the buff. Apply it over time and in pulses.
---@param unit Unit
---@param buffName string
---@param instigator Unit
function BuffWorkThread(unit, buffName, instigator)
    local buffTable = Buffs[buffName]

    -- Non-Pulsing Buff
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

--- Functions to affect the unit. Everytime you want to affect a new part of unit, add it in here.
--- `afterRemove` is a bool that defines if this buff is affecting after the removal of a buff.
--- We reaffect the unit to make sure that buff type is recalculated accurately without the buff
--- that was on the unit. However, this doesn't work for stunned units because it's a
--- fire-and-forget type buff, not a fire-and-keep-track-of type buff.
BuffEffects = {

    -- most dont use the last two args, so most don't have them. This is fine.
    Stun = function(buffDef, buffValues, unit, buffName, instigator, afterRemove)
        if unit.ImmuneToStun or afterRemove then return end
        unit:SetStunned(buffDef.Duration or 1, instigator)
        if unit.Anims then
            for _, manip in unit.Anims do
                manip:SetRate(0)
            end
        end
    end,

    --- Quite confident that this one is broken
    Health = function(buffDef, buffValues, unit, buffName, instigator)
        --Note: With health we don't actually look at the unit's table because it's an instant happening.  We don't want to overcalculate something as pliable as health.
        local health = unit:GetHealth()
        local affectsHealth = buffDef.Affects.Health
        local newhealth = ((affectsHealth.Add or 0) + health) * (affectsHealth.Mult or 1)
        local healthadj = newhealth - health

        if healthadj < 0 then
            -- fixme: DoTakeDamage shouldn't be called directly
            unit:DoTakeDamage(instigator, -healthadj, buffDef.DamageType or 'Spell', VDiff(instigator:GetPosition(), unit:GetPosition()))
        else
            unit:AdjustHealth(instigator, healthadj)
        end
    end,

    MaxHealth = function(buffDef, buffValues, unit, buffName)
        -- With this type of buff, the idea is to adjust the Max Health of a unit.
        -- The DoNotFill flag is set when we want to adjust the max ONLY and not have the
        -- rest of the unit's HP affected to match. If it's not flagged, the unit's HP
        -- will be adjusted by the same amount and direction as the max
        local baseHealth = unit.Blueprint.Defense.MaxHealth or 1
        local newmax = BuffCalculate(unit, buffName, 'MaxHealth', baseHealth)

        if buffValues.DoNotFill or unit.IsBeingTransferred then
            unit:SetMaxHealth(newmax)
        else
            local difference = unit:GetMaxHealth() - unit:GetHealth()
            unit:SetMaxHealth(newmax)
            unit:SetHealth(unit, newmax - difference)
        end
    end,

    Regen = function(buffDef, buffValues, unit, buffName)
        -- Adjusted to use a special case of adding mults and calculating the final value
        -- in BuffCalculate to fix bugs where adds and mults would clash or cancel
        local bpRegen = unit:GetBlueprint().Defense.RegenRate or 0
        local val = BuffCalculate(unit, nil, 'Regen', bpRegen)

        unit:SetRegen(val)
    end,

    Damage = function(buffDef, buffValues, unit, buffName)
        for i = 1, unit:GetWeaponCount() do
            local wep = unit:GetWeapon(i)
            if wep.Label ~= 'DeathWeapon' and wep.Label ~= 'DeathImpact' then
                local wepbp = wep:GetBlueprint()
                local wepdam = wepbp.Damage
                local val = BuffCalculate(unit, buffName, 'Damage', wepdam)

                if val >= math.abs(val) + 0.5 then
                    val = math.ceil(val)
                else
                    val = math.floor(val)
                end

                wep:ChangeDamage(val)
            end
        end
    end,

    DamageRadius = function(buffDef, buffValues, unit, buffName)
        for i = 1, unit:GetWeaponCount() do
            local wep = unit:GetWeapon(i)
            local wepbp = wep:GetBlueprint()
            local weprad = wepbp.DamageRadius
            local val = BuffCalculate(unit, buffName, 'DamageRadius', weprad)

            wep:SetDamageRadius(val)
        end
    end,

    MaxRadius = function(buffDef, buffValues, unit, buffName)
        for i = 1, unit:GetWeaponCount() do
            local wep = unit:GetWeapon(i)
            local wepbp = wep:GetBlueprint()
            local weprad = wepbp.MaxRadius
            local val = BuffCalculate(unit, buffName, 'MaxRadius', weprad)

            wep:ChangeMaxRadius(val)
        end
    end,

    MoveMult = function(buffDef, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'MoveMult', 1)
        unit:SetSpeedMult(val)
        unit:SetAccMult(val)
        unit:SetTurnMult(val)
    end,

    WeaponsEnable = function(buffDef, buffValues, unit, buffName)
        for i = 1, unit:GetWeaponCount() do
            local wep = unit:GetWeapon(i)
            local _, bool = BuffCalculate(unit, buffName, 'WeaponsEnable', 0, true)
            wep:SetWeaponEnabled(bool)
        end
    end,

    VisionRadius = function(buffDef, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'VisionRadius', unit:GetBlueprint().Intel.VisionRadius or 0)
        unit:SetIntelRadius('Vision', val)
    end,

    RadarRadius = function(buffDef, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'RadarRadius', unit:GetBlueprint().Intel.RadarRadius or 0)
        if not unit:IsIntelEnabled('Radar') then
            unit:InitIntel(unit.Army,'Radar', val)
            unit:EnableIntel('Radar')
        else
            unit:SetIntelRadius('Radar', val)
            unit:EnableIntel('Radar')
        end

        if val <= 0 then
            unit:DisableIntel('Radar')
        end
    end,

    OmniRadius = function(buffDef, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'OmniRadius', unit:GetBlueprint().Intel.OmniRadius or 0)
        if not unit:IsIntelEnabled('Omni') then
            unit:InitIntel(unit.Army,'Omni', val)
            unit:EnableIntel('Omni')
        else
            unit:SetIntelRadius('Omni', val)
            unit:EnableIntel('Omni')
        end

        if val <= 0 then
            unit:DisableIntel('Omni')
        end
    end,

    BuildRate = function(buffDef, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'BuildRate', unit:GetBlueprint().Economy.BuildRate or 1)
        unit:SetBuildRate(val)
    end,

    -------- ADJACENCY BELOW --------
    EnergyActive = function(buffDef, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'EnergyActive', 1)
        unit.EnergyBuildAdjMod = val
        unit:UpdateConsumptionValues()
    end,

    MassActive = function(buffDef, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'MassActive', 1)
        unit.MassBuildAdjMod = val
        unit:UpdateConsumptionValues()
    end,

    EnergyMaintenance = function(buffDef, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'EnergyMaintenance', 1)
        unit.EnergyMaintAdjMod = val
        unit:UpdateConsumptionValues()
    end,

    MassMaintenance = function(buffDef, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'MassMaintenance', 1)
        unit.MassMaintAdjMod = val
        unit:UpdateConsumptionValues()
    end,

    EnergyProduction = function(buffDef, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'EnergyProduction', 1)
        unit.EnergyProdAdjMod = val
        unit:UpdateProductionValues()
    end,

    MassProduction = function(buffDef, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'MassProduction', 1)
        unit.MassProdAdjMod = val
        unit:UpdateProductionValues()
    end,

    EnergyWeapon = function(buffDef, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'EnergyWeapon', 1)
        for i = 1, unit:GetWeaponCount() do
            local wep = unit:GetWeapon(i)
            if wep:WeaponUsesEnergy() then
                wep.AdjEnergyMod = val
            end
        end
    end,

    RateOfFire = function(buffDef, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'RateOfFire', 1)

        for i = 1, unit:GetWeaponCount() do
            local wep = unit:GetWeapon(i)
            local bp = wep:GetBlueprint()
            -- Set new rate of fire based on blueprint rate of fire
            wep:ChangeRateOfFire(bp.RateOfFire / val)
            wep.AdjRoFMod = val
        end
    end,

}

local buffMissingWarnings = {}

---@param unit Unit
---@param buffName string
---@param instigator Unit
---@param afterRemove boolean
function BuffAffectUnit(unit, buffName, instigator, afterRemove)
    local buffDef = Buffs[buffName]
    local affects = buffDef.Affects

    if not afterRemove and buffDef.OnBuffAffect then
        buffDef:OnBuffAffect(unit, instigator)
    end

    local buffEffects = BuffEffects
    for atype, vals in affects do
        local effect = buffEffects[atype]
        if effect then
            effect(buffDef, vals, unit, buffName, instigator, afterRemove)
        elseif not buffMissingWarnings[atype] then
            buffMissingWarnings[atype] = true
            WARN('Missing buff effect function '..tostring(atype))
        end
    end
end

--- A buffName to function map for unique buffs
local UniqueBuffs = {}

--- Calculates the buff from all the buffs of the same time the unit has
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
    local bool = initialBool or false
    local affects = unit.Buffs.Affects[affectType]
    if not affects then
        return initialVal, bool
    end

    local adds = 0
    local mults = 1.0
    local maxCeil, minFloor

    for _, v in affects do
        local ceil, floor

        local add = v.Add
        if add and add ~= 0 then
            adds = adds + add * v.Count
        end

        local bpCeilings = v.BPCeilings
        if bpCeilings and bpCeilings[unit.techCategory] then
            ceil = bpCeilings[unit.techCategory]
        elseif v.Ceil then
            ceil = v.Ceil
        end

        local bpFloors = v.BPFloors
        if bpFloors and bpFloors[unit.techCategory] then
            floor = bpFloors[unit.techCategory]
        elseif v.Floor then
            floor = v.Floor
        end

        local multInterp = v.MultInterp
        if multInterp and multInterp ~= 0.0 then
            local upper = 1
            if affectType == "Regen" then
                upper = unit.Blueprint.Defense.MaxHealth
            end
            local chng = multInterp * upper * v.Count
            if chng > ceil then
                chng = ceil
            elseif chng < floor then
                chng = floor
            end
            adds = adds + chng
        end

        local mult = v.Mult
        if mult and mult ~= 1.0 then
            for _ = 1, v.Count do
                mults = mults * mult
            end
        end

        if not v.Bool then
            bool = false
        else
            bool = true
        end

        if ceil and (not maxCeil or ceil < maxCeil) then
            maxCeil = ceil
        end
        if floor and (not minFloor or floor < minFloor) then
            minFloor = floor
        end
    end

    -- Adds are calculated first, then the mults
    local returnVal = (initialVal + adds) * mults
    if maxCeil and returnVal > maxCeil then
        returnVal = maxCeil
    elseif minFloor and returnVal < minFloor then
        returnVal = minFloor
    end

    return returnVal, bool
end

--- Removes buffs
---@param unit Unit
---@param buffName string
---@param removeAllCounts boolean
---@param instigator Unit
function RemoveBuff(unit, buffName, removeAllCounts, instigator)
    local buff = Buffs[buffName]
    local buffTable = unit.Buffs.BuffTable[buff.BuffType]
    local unitBuff = buffTable[buffName]
    local unitBuffCount = unitBuff.Count
    if not unitBuffCount or unitBuffCount <= 0 then
        -- This buff wasn't previously applied to the unit
        return
    end

    for atype,_ in buff.Affects do
        local affects = unit.Buffs.Affects[atype]
        if not affects then continue end
        local data = affects[buffName]
        if not data then continue end

        -- If we're removing all buffs of this name, only remove as
        -- many affects as there are buffs since other buffs may have
        -- added these same affects.
        if removeAllCounts then
            data.Count = data.Count - unitBuffCount
        else
            data.Count = data.Count - 1
        end

        if data.Count <= 0 then
            affects[buffName] = nil
        end
    end

    unitBuffCount = unitBuffCount - 1
    unitBuff.Count = unitBuffCount

    if removeAllCounts or unitBuffCount <= 0 then
        -- unit:PlayEffect('RemoveBuff', buffName)
        unitBuff.Trash:Destroy()
        buffTable[buffName] = nil
    end

    if buff.OnBuffRemove then
        buff:OnBuffRemove(unit, instigator)
    end

    -- FIXME: This doesn't work because the magic sync table doesn't detect
    -- the change. Need to give all child tables magic meta tables too.
    if buff.Icon then
        -- If the user layer was displaying an icon, remove it from the sync table
        local newTable = unit.Sync.Buffs
        table.removeByValue(newTable,buffName)
        unit.Sync.Buffs = table.copy(newTable)
    end

    BuffAffectUnit(unit, buffName, unit, true)
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

---@param unit Unit
---@param buffName string
---@param trsh TrashBag
function PlayBuffEffect(unit, buffName, trsh)
    local buff = Buffs[buffName]
    if not buff.Effects then
        return
    end

    for _, fx in buff.Effects do
        local buffFx = CreateAttachedEmitter(unit, 0, unit.Army, fx)
        if buff.EffectsScale then
            buffFx:ScaleEmitter(buff.EffectsScale)
        end
        trsh:Add(buffFx)
        unit.Trash:Add(buffFx)
    end
end

--
-- DEBUG FUNCTIONS
--
_G.PrintBuffs = function()
    local selection = DebugGetSelection()
    for _, unit in selection do
        if unit.Buffs then
            LOG('Buffs = ', repr(unit.Buffs))
        end
    end
end
