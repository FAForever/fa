local XZDist = import('/lua/utilities.lua').XZDistanceTwoVectors

function ScaleV(v, scale)
    return Vector(v.x * scale, v.y * scale, v.z * scale)
end

-- This table stores numbers of bombs left in a cluster bomb run
-- format : bombs_left[entityId] = <n_left>
local bombs_left = {}

CalculateBallisticAcceleration = function(weapon, projectile)
    local bp = weapon:GetBlueprint()
    local MuzzleSalvoSize = bp.MuzzleSalvoSize
    local MuzzleSalvoDelay = bp.MuzzleSalvoDelay
    local acc = 4.75
    local launcher = projectile:GetLauncher()
    if not launcher then return acc end
    local id = launcher:GetEntityId()

    if MuzzleSalvoSize > 1 and bombs_left[id] == nil then
        bombs_left[id] = MuzzleSalvoSize
    end

    local proj = {pos=projectile:GetPosition(), vel=ScaleV(Vector(launcher:GetVelocity()), 10)}
    local entity = launcher:GetTargetEntity()
    local target
    if entity and IsUnit(entity) then
        target = {pos=entity:GetPosition(), vel=ScaleV(Vector(entity:GetVelocity()), 10)}
    else
        target = {pos=weapon:GetCurrentTargetPos(), vel=Vector(0, 0, 0)}
    end

    local dist = {pos=XZDist(proj.pos, target.pos), vel=XZDist(proj.vel, target.vel)}
    if dist.vel == 0 then return acc end

    if bp.DropBombShort then
        dist.pos = dist.pos * math.clamp(1 - bp.DropBombShort, 0, 1)
    end

    if bombs_left[id] ~= nil then
        local len = MuzzleSalvoDelay * dist.vel * 0.5
        dist.pos = dist.pos + (len * MuzzleSalvoSize)/2 - len*bombs_left[id]
        bombs_left[id] = bombs_left[id] > 1 and bombs_left[id] - 1 or nil
    end

    local time = dist.pos / dist.vel
    if time == 0 then return acc end

    target.tpos = {target.pos[1] + time * target.vel[1], 0, target.pos[3] + time * target.vel[3]}
    target.tpos[2] = GetSurfaceHeight(target.tpos[1], target.tpos[3])

    acc = 2 * math.pow(1 / time , 2) * (proj.pos[2] - target.tpos[2])

    return acc
end
