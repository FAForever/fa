#****************************************************************************
#**
#**  File     :  /lua/sim/buff.lua
#**
#**  Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

# The Unit's BuffTable for applied buffs looks like this:
#
# Unit.Buffs = {
#    Affects = {
#        <AffectType (Regen/MaxHealth/etc)> = {
#            BuffName = {
#                Count = i,
#                Add = X,
#                Mult = X,
#            }
#        }
#    }
#    BuffTable = {
#        <BuffType (LEVEL/CATEGORY)> = {
#            BuffName = {
#                Count = i,
#                Trash = trashbag,
#            }
#        }
#    }

#Function to apply a buff to a unit.
#This function is a fire-and-forget.  Apply this and it'll be applied over time if there is a duration.
function ApplyBuff(unit, buffName, instigator)

    if unit:IsDead() then 
        return 
    end
    
    instigator = instigator or unit

    #buff = table of buff data
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

    if def.Stacks == 'REPLACE' and ubt[def.BuffType] then
        for key, bufftbl in unit.Buffs.BuffTable[def.BuffType] do
            RemoveBuff(unit, key, true)
        end
    end

    
    #If add this buff to the list of buffs the unit has becareful of stacking buffs.
    if not ubt[def.BuffType] then
        ubt[def.BuffType] = {}
    end
    
    if def.Stacks == 'IGNORE' and ubt[def.BuffType] and table.getsize(ubt[def.BuffType]) > 0 then
        return
    end
    
    local data = ubt[def.BuffType][buffName]
    if not data then
        # This is a new buff (as opposed to an additional one being stacked)
        data = {
            Count = 1,
            Trash = TrashBag(),
            BuffName = buffName,
        }
        ubt[def.BuffType][buffName] = data
    else
        # This buff is already on the unit so stack another by incrementing the
        # counts. data.Count is how many times the buff has been applied
        data.Count = data.Count + 1
        
    end
    
    local uaffects = unit.Buffs.Affects
    if def.Affects then
        for k,v in def.Affects do
            # Don't save off 'instant' type affects like health and energy
            if k != 'Health' and k != 'Energy' then
                if not uaffects[k] then
                    uaffects[k] = {}
                end
                
                if not uaffects[k][buffName] then
                    # This is a new affect.
                    local affectdata = { 
                        BuffName = buffName, 
                        Count = 1, 
                    }
                    for buffkey, buffval in v do
                        affectdata[buffkey] = buffval
                    end
                    uaffects[k][buffName] = affectdata
                else
                    # This affect is already there, increment the count
                    uaffects[k][buffName].Count = uaffects[k][buffName].Count + 1
                end
            end
        end
    end
    
    #If the buff has a duration, then 
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
    
    #LOG('*DEBUG: Applying buff :',buffName, ' to unit ',unit:GetUnitId())
    #LOG('Buff = ',repr(ubt[def.BuffType][buffName]))
    #LOG('Affects = ',repr(uaffects))
    BuffAffectUnit(unit, buffName, instigator, false)
end

#Function to do work on the buff.  Apply it over time and in pulses.
function BuffWorkThread(unit, buffName, instigator)
    
    local buffTable = Buffs[buffName]
    
    #Non-Pulsing Buff
    local totPulses = buffTable.DurationPulse
    
    if not totPulses then
        WaitSeconds(buffTable.Duration)
    else
        local pulse = 0
        local pulseTime = buffTable.Duration / totPulses
    
        while pulse <= totPulses and not unit:IsDead() do
    
            WaitSeconds(pulseTime)
            BuffAffectUnit(unit, buffName, instigator, false)
            pulse = pulse + 1
    
        end
    end

    RemoveBuff(unit, buffName)
end

#Function to affect the unit.  Everytime you want to affect a new part of unit, add it in here.
#afterRemove is a bool that defines if this buff is affecting after the removal of a buff.  
#We reaffect the unit to make sure that buff type is recalculated accurately without the buff that was on the unit.
#However, this doesn't work for stunned units because it's a fire-and-forget type buff, not a fire-and-keep-track-of type buff.
function BuffAffectUnit(unit, buffName, instigator, afterRemove)
    
    local buffDef = Buffs[buffName]
    
    local buffAffects = buffDef.Affects
    
    if buffDef.OnBuffAffect and not afterRemove then
        buffDef:OnBuffAffect(unit, instigator)
    end
    
    for atype, vals in buffAffects do
    
        if atype == 'Health' then
        
            #Note: With health we don't actually look at the unit's table because it's an instant happening.  We don't want to overcalculate something as pliable as health.
            
            local health = unit:GetHealth()
            local val = ((buffAffects.Health.Add or 0) + health) * (buffAffects.Health.Mult or 1)
            local healthadj = val - health
            
            if healthadj < 0 then
                # fixme: DoTakeDamage shouldn't be called directly
                local data = {
                    Instigator = instigator,
                    Amount = -1 * healthadj,
                    Type = buffDef.DamageType or 'Spell',
                    Vector = VDiff(instigator:GetPosition(), unit:GetPosition()),
                }
                unit:DoTakeDamage(data)
            else
                unit:AdjustHealth(instigator, healthadj)
            
                #LOG('*BUFF: Unit ', repr(unit:GetEntityId()), ' buffed health to ', repr(val))
            end
        
        elseif atype == 'MaxHealth' then
        
            local unitbphealth = unit:GetBlueprint().Defense.MaxHealth or 1
            local val = BuffCalculate(unit, buffName, 'MaxHealth', unitbphealth)
        
            local oldmax = unit:GetMaxHealth()
        
            unit:SetMaxHealth(val)
            
            if not vals.DoNoFill then
                if val > oldmax then
                    unit:AdjustHealth(unit, val - oldmax)
                else
                    unit:SetHealth(unit, math.min(unit:GetHealth(), unit:GetMaxHealth())) 
                end
            end            
            
            #LOG('*BUFF: Unit ', repr(unit:GetEntityId()), ' buffed max health to ', repr(val))
        
        elseif atype == 'Regen' then
            
            local bpregn = unit:GetBlueprint().Defense.RegenRate or 0
            local val = BuffCalculate(unit, buffName, 'Regen', bpregn)
        
            unit:SetRegenRate(val)
        
            #LOG('*BUFF: Unit ', repr(unit:GetEntityId()), ' buffed regen rate to ', repr(val))
        elseif atype == 'RegenPercent' then
            local val = false
                
            if afterRemove then
                #Restore normal regen value plus buffs so I don't break stuff. Love, Robert
                local bpregn = unit:GetBlueprint().Defense.RegenRate or 0
                val = BuffCalculate(unit, nil, 'Regen', bpregn)
            else
                #Buff this sucka
                val = BuffCalculate(unit, buffName, 'RegenPercent', unit:GetMaxHealth())
            end
            
            unit:SetRegenRate(val)
            
        elseif atype == 'Damage' then
        
            for i = 1, unit:GetWeaponCount() do
        
                local wep = unit:GetWeapon(i)
                if wep.Label != 'DeathWeapon' and wep.Label != 'DeathImpact' then
                    local wepbp = wep:GetBlueprint()
                    local wepdam = wepbp.Damage
                    local val = BuffCalculate(unit, buffName, 'Damage', wepdam)
            
                    if val >= ( math.abs(val) + 0.5 ) then
                        val = math.ceil(val)
                    else
                        val = math.floor(val)
                    end
        
                    wep:ChangeDamage(val)
                    #LOG('*BUFF: Unit ', repr(unit:GetEntityId()), ' buffed damage to ', repr(val))
                end
            end
        
        elseif atype == 'DamageRadius' then
        
            for i = 1, unit:GetWeaponCount() do
        
                local wep = unit:GetWeapon(i)
                local wepbp = wep:GetBlueprint()
                local weprad = wepbp.DamageRadius
                local val = BuffCalculate(unit, buffName, 'DamageRadius', weprad)
                
                wep:SetDamageRadius(val)
                
                #LOG('*BUFF: Unit ', repr(unit:GetEntityId()), ' buffed damage radius to ', repr(val))
            end

        elseif atype == 'MaxRadius' then
        
            for i = 1, unit:GetWeaponCount() do
        
                local wep = unit:GetWeapon(i)
                local wepbp = wep:GetBlueprint()
                local weprad = wepbp.MaxRadius
                local val = BuffCalculate(unit, buffName, 'MaxRadius', weprad)
        
                wep:ChangeMaxRadius(val)
                
                #LOG('*BUFF: Unit ', repr(unit:GetEntityId()), ' buffed max radius to ', repr(val))
            end

        elseif atype == 'MoveMult' then
            
            local val = BuffCalculate(unit, buffName, 'MoveMult', 1)
            
            unit:SetSpeedMult(val)
            unit:SetAccMult(val)
            unit:SetTurnMult(val)
            
            #LOG('*BUFF: Unit ', repr(unit:GetEntityId()), ' buffed speed/accel/turn mult to ', repr(val))
        
        elseif atype == 'Stun' and not afterRemove then
            
            unit:SetStunned(buffDef.Duration or 1, instigator)
            
            #LOG('*BUFF: Unit ', repr(unit:GetEntityId()), ' buffed stunned for ', repr(buffDef.Duration or 1))
            
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
            local val = BuffCalculate(unit, buffName, 'OmniRadius', unit:GetBlueprint().Intel.RadarRadius or 0)
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
            unit:SetBuildRate( val )
            
        #### ADJACENCY BELOW ####
        elseif atype == 'EnergyActive' then
            local val = BuffCalculate(unit, buffName, 'EnergyActive', 1)
            unit.EnergyBuildAdjMod = val
            unit:UpdateConsumptionValues()
            #LOG('*BUFF: EnergyActive = ' ..  val)
            
        elseif atype == 'MassActive' then
            local val = BuffCalculate(unit, buffName, 'MassActive', 1)
            unit.MassBuildAdjMod = val
            unit:UpdateConsumptionValues()
            #LOG('*BUFF: MassActive = ' ..  val)
            
        elseif atype == 'EnergyMaintenance' then
            local val = BuffCalculate(unit, buffName, 'EnergyMaintenance', 1)
            unit.EnergyMaintAdjMod = val
            unit:UpdateConsumptionValues()
            #LOG('*BUFF: EnergyMaintenance = ' ..  val)
            
        elseif atype == 'MassMaintenance' then
            local val = BuffCalculate(unit, buffName, 'MassMaintenance', 1)
            unit.MassMaintAdjMod = val
            unit:UpdateConsumptionValues()
            #LOG('*BUFF: MassMaintenance = ' ..  val)
            
        elseif atype == 'EnergyProduction' then
            local val = BuffCalculate(unit, buffName, 'EnergyProduction', 1)
            unit.EnergyProdAdjMod = val
            unit:UpdateProductionValues()
            #LOG('*BUFF: EnergyProduction = ' .. val)

        elseif atype == 'MassProduction' then
            local val = BuffCalculate(unit, buffName, 'MassProduction', 1)
            unit.MassProdAdjMod = val
            unit:UpdateProductionValues()
            #LOG('*BUFF: MassProduction = ' .. val)
            
        elseif atype == 'EnergyWeapon' then
            local val = BuffCalculate(unit, buffName, 'EnergyWeapon', 1)
            for i = 1, unit:GetWeaponCount() do
                local wep = unit:GetWeapon(i)
                if wep:WeaponUsesEnergy() then
                    wep.AdjEnergyMod = val
                end
            end
            #LOG('*BUFF: EnergyWeapon = ' ..  val)
            
        elseif atype == 'RateOfFire' then
            for i = 1, unit:GetWeaponCount() do
                local wep = unit:GetWeapon(i)
                local wepbp = wep:GetBlueprint()
                local weprof = wepbp.RateOfFire

                # Set new rate of fire based on blueprint rate of fire.=
                local val = BuffCalculate(unit, buffName, 'RateOfFire', 1)
                
                local delay = 1 / wepbp.RateOfFire
                
                wep:ChangeRateOfFire( 1 / ( val * delay ) )
                #LOG('*BUFF: RateOfFire = ' ..  (1 / ( val * delay )) )
            end



#   CLOAKING is a can of worms.  Revisit later.
#        elseif atype == 'Cloak' then
#            
#            local val, bool = BuffCalculate(unit, buffName, 'Cloak', 0)
#            
#            if unit:IsIntelEnabled('Cloak') then
#
#                if bool then
#                    unit:InitIntel(unit:GetArmy(), 'Cloak')
#                    unit:SetRadius('Cloak')
#                    unit:EnableIntel('Cloak')
#            
#                elseif not bool then
#                    unit:DisableIntel('Cloak')
#                end
#            
#            end
           
        elseif atype != 'Stun' then
            WARN("*WARNING: Tried to apply a buff with an unknown affect type of " .. atype .. " for buff " .. buffName)
        end
    end
end

#Calculates the buff from all the buffs of the same time the unit has.
function BuffCalculate(unit, buffName, affectType, initialVal, initialBool)
    
    #Add all the 
    local adds = 0
    local mults = 1.0
    local bool = initialBool or false
    
    local highestCeil = false
    local lowestFloor = false
    
    if not unit.Buffs.Affects[affectType] then return initialVal, bool end
    
    for k, v in unit.Buffs.Affects[affectType] do
    
        if v.Add and v.Add != 0 then
            adds = adds + (v.Add * v.Count)
        end
        
        if v.Mult then
            for i=1,v.Count do
                mults = mults * v.Mult
            end
        end
        
        if not v.Bool then
            bool = false
        else
            bool = true
        end
        
        if v.Ceil and (not highestCeil or highestCeil < v.Ceil) then
            highestCeil = v.Ceil
        end
        
        if v.Floor and (not lowestFloor or lowestFloor > v.Floor) then
            lowestFloor = v.Floor
        end
    end
    
    #Adds are calculated first, then the mults.  May want to expand that later.
    local returnVal = (initialVal + adds) * mults
    
    if lowestFloor and returnVal < lowestFloor then returnVal = lowestFloor end
    
    if highestCeil and returnVal > highestCeil then returnVal = highestCeil end 
    
    return returnVal, bool
end

#Removes buffs
function RemoveBuff(unit, buffName, removeAllCounts, instigator)
    
    local def = Buffs[buffName]

    local unitBuff = unit.Buffs.BuffTable[def.BuffType][buffName]
    
    for atype,_ in def.Affects do
        local list = unit.Buffs.Affects[atype]
        if list and list[buffName] then
            # If we're removing all buffs of this name, only remove as 
            # many affects as there are buffs since other buffs may have
            # added these same affects.
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
    
    
    if not unitBuff.Count then
        local stg = "*WARNING: BUFF: unitBuff.Count is nil.  Unit: "..unit:GetUnitId().." Buff Name: ".. buffName.." Unit BuffTable: ", repr(unitBuff)
        error(stg, 2)
    else
        unitBuff.Count = unitBuff.Count - 1
    end

    if removeAllCounts or unitBuff.Count <= 0 then
        # unit:PlayEffect('RemoveBuff', buffName)
        unitBuff.Trash:Destroy()
        unit.Buffs.BuffTable[def.BuffType][buffName] = nil
    end

    if def.OnBuffRemove then
        def:OnBuffRemove(unit, instigator)
    end

    # FIXME: This doesn't work because the magic sync table doesn't detect
    # the change. Need to give all child tables magic meta tables too.
    if def.Icon then
        # If the user layer was displaying an icon, remove it from the sync table
        local newTable = unit.Sync.Buffs
        table.removeByValue(newTable,buffName)
        unit.Sync.Buffs = table.copy(newTable)
    end

    BuffAffectUnit(unit, buffName, unit, true)
    
    #LOG('*BUFF: Removed ', buffName)
end

function HasBuff(unit, buffName)
    local def = Buffs[buffName]
    if not def then
        return false
    end
    local bonu = unit.Buffs.BuffTable[def.BuffType][buffName]
    if bonu then
        return true
    end
    return false
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
        unit.TrashOnKilled:Add(bufffx)
    end
end

#
# DEBUG FUNCTIONS
# 
_G.PrintBuffs = function()
    local selection = DebugGetSelection()
    for k,unit in selection do
        if unit.Buffs then
            LOG('Buffs = ', repr(unit.Buffs))
        end
    end
end