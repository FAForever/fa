-- upvalue globals for performance
local IsUnit = IsUnit
local GetSurfaceHeight = GetSurfaceHeight
local VDist2 = VDist2

-- upvalue moho functions for performance
local ProjectileMethods = moho.projectile_methods
local ProjectileGetLauncher = ProjectileMethods.GetLauncher

local EntityMethods = moho.entity_methods
local EntityGetPositionXYZ = EntityMethods.GetPositionXYZ

local UnitMethods = moho.unit_methods
local UnitGetVelocity = UnitMethods.GetVelocity
local UnitGetTargetEntity = UnitMethods.GetTargetEntity

local WeaponMethods = moho.weapon_methods
local WeaponGetCurrentTargetPos = WeaponMethods.GetCurrentTargetPos

local MathMax = math.max
local MathMin = math.min

---@class BombCache
---@field remaining number
---@field lastAccel number
---@field spreadBegin number
---@field adjustedDelay number
---@field dropShortRatio? number
---@field usestore? true
---@field targetpos? Vector

-- This table stores number of bombs left in a cluster bomb run and last acceleration
---@type table<string, BombCache>
bomb_data = {}

local upBombData = bomb_data

---
---@param weapon Weapon
---@param projectile Projectile
CalculateBallisticAccelerationNew = function(weapon, projectile)
    local launcher = ProjectileGetLauncher(projectile)
    if not launcher then -- fail-fast
        return 4.75
    end
    local bombData = upBombData
    local id = launcher.EntityId

    -- Get projectile position and velocity
    -- velocity needs to multiplied by 10 due to being returned /tick instead of /s
    local projPosX, projPosY, projPosZ = EntityGetPositionXYZ(projectile)
    local projVelX,    _    , projVelZ = UnitGetVelocity(launcher)

    local target = UnitGetTargetEntity(launcher)

    local targetPos
    local targetPosX, targetPosZ
    local targetVelX, targetVelZ
    if target and IsUnit(target) then
        -- target is a entity
        targetPosX, _, targetPosZ = EntityGetPositionXYZ(target)
        targetVelX, _, targetVelZ = UnitGetVelocity(target)
    else
        -- target is something else i.e. attack ground
        targetPos = WeaponGetCurrentTargetPos(weapon)
        targetPosX, targetPosZ = targetPos[1], targetPos[3]
        targetVelX, targetVelZ = 0, 0
    end

    local data = bombData[id]

    -- if it's the first time...
    if not data then
        local bp = weapon.Blueprint
        local muzzleSalvoSize = bp.MuzzleSalvoSize
        -- and there's going to be a second time
        if muzzleSalvoSize > 1 then
            -- calculate & cache a couple things only the first time
            data = {
                remaining = muzzleSalvoSize,
                lastAccel = 4.75,
                -- center the spread on the target
                -- subtract one because we will have already dropped one bomb when we calculate it
                spreadBegin = 0.5 * muzzleSalvoSize - 0.5,
                -- adjusted time between bombs, this is multiplied by 0.5 to get the bombs overlapping a bit
                -- (also pre-convert velocity from per ticks to per seconds by multiplying by 10)
                adjustedDelay = 5 * bp.MuzzleSalvoDelay,
                -- store the target position if it was a groundfire
                targetpos = targetPos, -- we don't use this, but apparently other code does
            }
            local dropShort = bp.DropBombShort
            if dropShort then
                -- deliberately drop bomb short by % ratio, could be useful for torpedo bombers
                data.dropShortRatio = MathMax(0, MathMin(1 - dropShort, 1))
            end
            bombData[id] = data
        else
            -- otherwise, do the same calculation but skip any cache or salvo logic
            if target.Dead then
                return 4.75
            end
            local distVel = VDist2(projVelX, projVelZ, targetVelX, targetVelZ)
            if distVel == 0 then
                return 4.75
            end
            local distPos = VDist2(projPosX, projPosZ, targetPosX, targetPosZ)
            local dropShort = bp.DropBombShort
            if dropShort then
                distPos = distPos * MathMax(0, MathMin(1 - dropShort, 1))
            end
            if distPos == 0 then
                return 4.75
            end
            local time = distPos / distVel
            local targetNewPosX = targetPosX + time * targetVelX
            local targetNewPosZ = targetPosZ + time * targetVelZ
            local targetNewPosY = GetSurfaceHeight(targetNewPosX, targetNewPosZ)
            return 200 * (projPosY - targetNewPosY) / (time*time)
        end
    end

    -- check if we lost the target (or if we previously did; regaining a target mid-run shouldn't
    -- suddenly divert some of the bombs)
    if target.Dead or data.usestore then
        -- use same acceleration as last bomb
        local remaining = data.remaining - 1
        data.remaining = remaining
        data.usestore = true
        if remaining == 0 then
            bombData[id] = nil
        end
        return data.lastAccel
    end

    -- calculate flat (exclude y-axis) distance and velocity between projectile and target
    -- velocity will need to multiplied by 10 due to being per tick instead of per second
    local distVel = VDist2(projVelX, projVelZ, targetVelX, targetVelZ)
    if distVel == 0 then
        return 4.75
    end
    local distPos = VDist2(projPosX, projPosZ, targetPosX, targetPosZ)

    local dropShort = data.dropShortRatio
    if dropShort then
        distPos = distPos * dropShort
    end

    -- bomber will drop several bombs
    local remaining = data.remaining - 1

    -- calculate the position for this particular bomb
    -- (centers the individual bomb release positions around the optimal position)
    distPos = distPos + data.adjustedDelay * distVel * (data.spreadBegin - remaining)
    data.remaining = remaining
    if remaining == 0 then
        bombData[id] = nil
    end
    if distPos == 0 then
        return 4.75
    end

    -- how many ticks until the bomb hits the target in xz-space
    local time = distPos / distVel

    -- find out where the target will be at that point in time (it could be moving)
    local targetNewPosX = targetPosX + time * targetVelX
    local targetNewPosZ = targetPosZ + time * targetVelZ
    -- what is the height at that future position
    local targetNewPosY = GetSurfaceHeight(targetNewPosX, targetNewPosZ)

    -- The basic formula for displacement over time is x = v0*t + 0.5*a*t^2
    -- x: displacement, v0: initial velocity, a: acceleration, t: time
    -- v0 is zero due to projectiles not inheriting y-speed of bomber
    -- now we can calculate what acceleration we need to make it hit the target in the y-axis
    -- a = 2 * (1/t)^2 * x

    -- also convert time from ticks to seconds (multiply by 10, twice)
    local acc = 200 * (projPosY - targetNewPosY) / (time*time)

    -- store last acceleration in case target dies in the middle of carpet bomb run
    data.lastAccel = acc
    return acc
end

local XZDist = import('/lua/utilities.lua').XZDistanceTwoVectors

-- This table stores last acceleration and numbers of bombs left in a cluster bomb run, as well as the original target
-- format : bomb_data[entityId] = {n_left=<n_left>, acc=<last_acc>, targetpos=<original_targetpos>}
bomb_data = {}

CalculateBallisticAccelerationOld = function(weapon, projectile)
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

CalculateBallisticAcceleration = function(weapon, projectile)
    LOG(string.format('Old result: %d', CalculateBallisticAccelerationOld(weapon, projectile)))
    LOG(string.format('New result: %d', CalculateBallisticAccelerationNew(weapon, projectile)))
    return CalculateBallisticAccelerationNew(weapon, projectile)
end