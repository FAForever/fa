--function AreaDamage(instigator, pos, radius, damage, damageType, damageFriendly, damageSelf)
function AreaDamage(...)
    local args
    local params = {'Instigator', 'Position', 'Radius', 'Damage', 'DamageType', 'DamageFriendly', 'DamageSelf'}

    if IsEntity(arg[1]) then
        args = {}
        for i, p in params do
            args[p] = arg[i]
        end
    else
        args = arg[1]
    end

    local instigator = args.Instigator
    local pos = args.Position or instigator:GetPosition()
    local startRadius = args.StartRadius or 0
    local radius = args.DamageRadius or 0
    local damageRadiusMax = math.min(args.DamageRadiusMax or radius, radius)
    local damage = args.Damage or 0
    local decay = args.DamageDecay or 'Linear'
    local damageType = args.DamageType or 'Normal'
    local friendly = args.DamageFriendly or true
    local damageSelf = args.DamageSelf or false

    local dFunctions = {
        None=function(p) return 1 end,
        Linear=function(p) return p end,
        Square=function(p) return math.pow(p, 2) end,
    }

    local damFunc = dFunctions[decay]
    local units = GetUnitsInRect(Rect(pos[1]-radius, pos[3]-radius, pos[1]+radius, pos[3]+radius)) or {}

    local sorted = {}

    for _, u in units do
        local d = VDist3(u:GetPosition(), pos)
        local doDamage = (damageSelf or instigator ~= u) and (friendly or not IsAlly(instigator:GetArmy(), u:GetArmy()))
        if d <= radius and doDamage then
            table.binsert(sorted, {unit=u, distance=d}, function(a, b) return a.distance < b.distance end)
        end
    end

    if not sorted then
        return
    end

    for _, s in sorted do
        local percent = 1 - (math.max(s.distance-damageRadiusMax, 0) / math.max(radius-damageRadiusMax, 0.001))
        local rdamage = damage * damFunc(percent)
        Damage(instigator, pos, s.unit, rdamage, damageType)
    end

    return
end
