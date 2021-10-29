local XZDist = import('/lua/utilities.lua').XZDistanceTwoVectors

-- This table stores last acceleration and numbers of bombs left in a cluster bomb run, as well as the original target
-- format : bomb_data[entityId] = {n_left=<n_left>, acc=<last_acc>, targetpos=<original_targetpos>}
bomb_data = {}

CalculateBallisticAcceleration = function(weapon, projectile)
    local bp = weapon:GetBlueprint()
    local MuzzleSalvoSize = bp.MuzzleSalvoSize
    local MuzzleSalvoDelay = bp.MuzzleSalvoDelay
    local acc = 4.75
    local launcher = projectile:GetLauncher()
    if not launcher then return acc end
    local id = launcher.EntityId

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

    if MuzzleSalvoSize > 1 and bomb_data[id] == nil then
        bomb_data[id] = {acc = 4.75, n_left = MuzzleSalvoSize, targetpos = target.pos}
    end

    local mydata = bomb_data[id]

    if not target.pos or mydata.usestore then
        if mydata then
            -- use same acceleration as last bomb
            acc = mydata.acc
            mydata.n_left = mydata.n_left - 1
            mydata.usestore = true -- Signal that we've lost our target to lock in these settings

            if mydata.n_left < 1 then
                bomb_data[id] = nil
            end
        end

        return acc
    end

    -- calculate flat(exclude y-axis) distance and velocity between projectile and target
    local dist = {pos=XZDist(proj.pos, target.pos), vel=XZDist(proj.vel, target.vel)}
    if dist.vel == 0 then return acc end

    if bp.DropBombShort then
        -- deliberately drop bomb short by % ratio, could be useful for torpedo bombers
        dist.pos = dist.pos * math.clamp(1 - bp.DropBombShort, 0, 1)
    end

    if bomb_data[id] ~= nil then -- bomber will drop several bombs
        -- calculate space between bombs, this is multiplied by 0.5
        -- to get the bombs overlapping a bit
        local len = MuzzleSalvoDelay * dist.vel * 0.5
        local current_bomb = MuzzleSalvoSize - bomb_data[id].n_left

        -- calculate the position for this particular bomb
        dist.pos = dist.pos - (len * (MuzzleSalvoSize - 1)) / 2 + len * current_bomb
        bomb_data[id].n_left = bomb_data[id].n_left - 1
        if bomb_data[id].n_left < 1 then
            bomb_data[id] = nil
        end

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

    if bomb_data[id] then
        -- store last acceleration in case target dies in the middle of carpet bomb run
        bomb_data[id].acc = acc
    end

    return acc
end
