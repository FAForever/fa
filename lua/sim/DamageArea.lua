local utils = import('/lua/utilities.lua')
local oldDamageArea = DamageArea

-- Trying to mimic DamageArea as good as possible, used for nukes to bypass the bubble damage absorbation of shields.
DamageArea = function(instigator, pos, radius, damage, type, damageAllies, damageSelf)
    local rect = Rect(pos[1]-radius, pos[3]-radius, pos[1]+radius, pos[3]+radius)
    local units = GetUnitsInRect(rect) or {}
    local army = instigator:GetArmy()

    for _, u in units do
        if VDist3(u:GetPosition(), pos) > radius then continue end
        if instigator == u then
            if damageSelf then
                -- need this ugliness due to Damage() refuse to damage when instigator == u
                instigator:OnDamage(instigator, damage, utils.GetDirectionVector(pos, u:GetPosition()), type)
            end
        elseif damageAllies or not IsAlly(army, u:GetArmy()) then
            Damage(instigator, pos, u, damage, type)
        end
    end

    local reclaim = GetReclaimablesInRect(pos[1]-radius, pos[3]-radius, pos[1]+radius, pos[1]+radius) or {}
    for _, r in reclaim do
        if IsProp(r) and VDist3(r:GetPosition(), pos) <= radius then
            Damage(instigator, pos, r, damage, type)
        end
    end

     -- Get rid of trees
     oldDamageArea(instigator, pos, radius, 1, 'Force', false, false)
end

Area = function(p)
    table.assimilate(p,  {type='Normal', allies=true, self=true, ticks=1, duration=0})
    local width = p.ticks > 1 and p.duration > 0 and (p.radius / p.ticks) or p.radius

    DamageArea(p.instigator, p.pos, width, p.damage, p.type, p.allies, p.self)

    -- deal more damage over time
    if width < p.radius then
        local delay = (p.duration / p.ticks)
        ForkThread(function()
            for i=2, p.ticks do
                WaitSeconds(delay)
                DamageRing(p.instigator, p.pos, width * (i - 1), width * i, p.damage, p.type, p.allies, p.self)
            end
        end)
    end
end
