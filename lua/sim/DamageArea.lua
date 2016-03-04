-- Trying to mimic DamageArea as good as possible, used for nukes to bypass the bubble damage absorbation of shields.
local DamageArea = function(instigator, location, radius, damage, type, damageAllies, damageSelf)
    local units = instigator:GetAIBrain():GetUnitsAroundPoint(categories.ALLUNITS, location, radius, not damageAllies and 'Enemy' or 'Neutral')

    -- edge case where you manually need to add the instigator
    if not damageAllies and damageSelf and instigator and VDist3(instigator:GetPosition(), location) <= radius then
        table.insert(units, instigator)
    end

    for _, u in units do
        if u ~= instigator or damageSelf then
            Damage(instigator, location, u, damage, type)
        end
    end

    local reclaim = GetReclaimablesInRect(location[1]-radius, location[3]-radius, location[1]+radius, location[3]+radius)
    for _, r in reclaim do
        if VDist3(r:GetPosition(), location) <= radius then
            Damage(instigator, location, r, damage, type)
        end
    end

     -- Get rid of trees
     DamageArea(instigator, location, radius, 1, 'Force', false, false)
end
