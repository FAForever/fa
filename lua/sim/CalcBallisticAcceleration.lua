-- upvalue globals for performance
local IsUnit = IsUnit
local GetSurfaceHeight = GetSurfaceHeight
local VDist2 = VDist2

-- upvalue moho functions for performance
local ProjectileMethods = moho.projectile_methods
local ProjectileGetLauncher = ProjectileMethods.GetLauncher

local EntityMethods = moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

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
CalculateBallisticAcceleration = function(weapon, projectile)
    local launcher = ProjectileGetLauncher(projectile)
    if not launcher then -- fail-fast
        return 4.75
    end
    local bombData = upBombData
    local id = launcher.EntityId

    -- Get projectile position and velocity
    -- velocity needs to multiplied by 10 due to being returned /tick instead of /s
    local projPos = EntityGetPosition(projectile)
    local projPosX, projPosY, projPosZ = projPos[1], projPos[2], projPos[3]
    local projVelX,    _    , projVelZ = UnitGetVelocity(launcher)

    local target = UnitGetTargetEntity(launcher)

    local targetPos
    local targetPosX, targetPosZ
    local targetVelX, targetVelZ
    if target and IsUnit(target) then
        -- target is a entity
        targetPos = EntityGetPosition(target)
        targetPosX, targetPosZ = targetPos[1], targetPos[3]
        targetVelX, _, targetVelZ = UnitGetVelocity(target)
    else
        -- target is something else i.e. attack ground
        targetPos = WeaponGetCurrentTargetPos(weapon)
        targetPosX, targetPosZ = targetPos[1], targetPos[3]
        targetVelX, targetVelZ = 0, 0
    end

    local bp = weapon.Blueprint
    local data = bombData[id]

    -- if it's the first time...
    if not data then
        local muzzleSalvoSize = bp.MuzzleSalvoSize
        -- and there's going to be a second time
        if muzzleSalvoSize > 1 then
            -- calculate & cache a couple things only the first time
            data = {
                remaining = muzzleSalvoSize,
                lastAccel = 4.75,
                -- subtract one because we will have already dropped one bomb
                spreadBegin = 0.5 * muzzleSalvoSize - 0.5,
                -- adjusted time between bombs, this is multiplied by 0.5 to get the bombs overlapping a bit
                -- (also pre-convert velocity from per ticks to per seconds by multiplying by 10)
                adjustedDelay = 5 * bp.MuzzleSalvoDelay,
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
            local targetTPosX = targetPosX + time * targetVelX
            local targetTPosZ = targetPosZ + time * targetVelZ
            local targetTPosY = GetSurfaceHeight(targetTPosX, targetTPosZ)
            return 200 * (projPosY - targetTPosY) / (time*time)
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
    -- velocity will need to multiplied by 10 due to being returned per tick instead of per second
    local distVel = VDist2(projVelX, projVelZ, targetVelX, targetVelZ)
    if distVel == 0 then
        return 4.75
    end
    local distPos = VDist2(projPosX, projPosZ, targetPosX, targetPosZ)

    local dropShort = data.dropShortRatio
    if dropShort then
        -- deliberately drop bomb short by % ratio, could be useful for torpedo bombers
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

    -- also convert time from per tick to per second (multiply by 10*10)
    local acc = 200 * (projPosY - targetNewPosY) / (time*time)

    -- store last acceleration in case target dies in the middle of carpet bomb run
    data.lastAccel = acc
    return acc
end