local XZDist = import('/lua/utilities.lua').XZDistanceTwoVectors

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

    -- Get projectile position and velocity
    -- velocity needs to multiplied by 10 due to being returned /tick instead of /s
    local proj = {pos=projectile:GetPosition(), vel=VMult(Vector(launcher:GetVelocity()), 10)}
    local entity = launcher:GetTargetEntity()
    local target
    if entity and IsUnit(entity) then
        -- target is a entity
        target = {pos=entity:GetPosition(), vel=VMult(Vector(entity:GetVelocity()), 10)}
    else
        -- target is something else i.e. attack ground
        target = {pos=weapon:GetCurrentTargetPos(), vel=Vector(0, 0, 0)}
    end

    -- calculate flat(exclude y-axis) distance and velocity between projectile and target
    local dist = {pos=XZDist(proj.pos, target.pos), vel=XZDist(proj.vel, target.vel)}
    if dist.vel == 0 then return acc end

    if bp.DropBombShort then
        -- deliberately drop bomb short by % ratio, could be useful for torpedo bombers
        dist.pos = dist.pos * math.clamp(1 - bp.DropBombShort, 0, 1)
    end

    if bombs_left[id] ~= nil then -- bomber will drop several bombs
        -- calculate space between bombs, this is multiplied by 0.5
        -- to get the bombs overlapping a bit
        local len = MuzzleSalvoDelay * dist.vel * 0.5
        local current_bomb = MuzzleSalvoSize - bombs_left[id]

        -- calculate the position for this particular bomb
        dist.pos = dist.pos - (len * (MuzzleSalvoSize - 1)) / 2 + len * current_bomb
        bombs_left[id] = bombs_left[id] > 1 and bombs_left[id] - 1 or nil
    end

    -- how many seconds until the bomb hits the target in xz-space
    local time = dist.pos / dist.vel
    if time == 0 then return acc end

    -- find out where the target will be at that point in time (it could be moving)
    target.tpos = {target.pos[1] + time * target.vel[1], 0, target.pos[3] + time * target.vel[3]}
    -- what is the height at that future position
    target.tpos[2] = GetSurfaceHeight(target.tpos[1], target.tpos[3])

    -- The basic formula for displacement over time is x = v0*t + 0.5*a*t^2
    -- x: displacement, v0: initial velocity, a: acceleration, t: time
    -- v0 is zero due to projectiles not inheriting y-speed of bomber
    -- now we can calculate what acceleration we need to make it hit the target in the y-axis
    -- a = 2 * (1/t)^2 * x

    acc = 2 * math.pow(1 / time , 2) * (proj.pos[2] - target.tpos[2])

    return acc
end
