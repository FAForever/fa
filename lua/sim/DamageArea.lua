local oldDamageArea = DamageArea

-- Trying to mimic DamageArea as good as possible, used for nukes to bypass the bubble damage absorbation of shields.
DamageArea = function(instigator, location, radius, damage, type, damageAllies, damageSelf, brain, army)
    local units = brain:GetUnitsAroundPoint(categories.ALLUNITS, location, radius)

    for _, u in units do
        if instigator == u then
            if damageSelf then
                local vector = import('/lua/utilities.lua').GetDirectionVector(location, u:GetPosition())
                -- need this ugliness due to Damage() refuse to damage when instigator == u
                instigator:OnDamage(instigator, damage, vector, type)
            end
        elseif damageAllies or not IsAlly(army, u:GetArmy()) then
            Damage(instigator, location, u, damage, type)
            
            -- Mark those damaged, then fall back on the original DamageArea to hit stuff out of intel
            if not u.Dead and u.CanTakeDamage then
                u:SetCanTakeDamage(false)
                u.Marked = true
            end
        end
    end
    
    oldDamageArea(instigator, location, radius, damage, type, damageAllies, damageSelf)
    for _, u in units do
        if not u.Dead and u.Marked then
            u:SetCanTakeDamage(true)
            u.Marked = nil
        end
    end

    local reclaim = GetReclaimablesInRect(location[1]-radius, location[3]-radius, location[1]+radius, location[1]+radius) or {}
    for _, r in reclaim do
        if IsProp(r) and VDist3(r:GetPosition(), location) <= radius then
            Damage(instigator, location, r, damage, type)
        end
    end

     -- Get rid of trees
     oldDamageArea(instigator, location, radius, 1, 'Force', false, false)
end
