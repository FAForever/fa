
-- This file is used by the following units:
-- - dead0202 (T2 UEF bomber/fighter: Janus)
-- - uaa0103 (t1 Aeon bomber: Shimmer)
-- - uaa0304 (t3 Aeon bomber: Shocker)
-- - uea0103 (t1 UEF bomber: Scorcher)
-- - uea0304 (t3 UEF bomber: Ambassador)
-- - ura0103 (t1 Cybran bomber: Zeus)
-- - ura0304 (t3 Cybran bomber: Revenant)
-- - xsa0103 (t1 Seraphim bomber: Sinnve)
-- - xsa0202 (t2 Seraphim bomber/fighter: Notha)
-- - xsa0304 (t3 Seraphim bomber: Sinntha)
-- - xsa0402 (t4 Seraphim bomber: Ahwassa)

-- It got introduced because some units miss their shell on their first pass 
-- over a unit. That is obviously frustrating and this function can be enabled
-- for a unit when you add Blueprint.Weapon[X].FixBombTrajectory = true to
-- the weapon blueprint of a unit.

XZDist = import("/lua/utilities.lua").XZDistanceTwoVectors

-- upvalue globals for performance
local VDist2 = VDist2
local GetSurfaceHeight = GetSurfaceHeight

-- upvalue moho functions for performance
local ProjectileMethods = _G.moho.projectile_methods 
local ProjectileGetVelocity = ProjectileMethods.GetVelocity
local ProjectileGetLauncher = ProjectileMethods.GetLauncher 

local EntityMethods = _G.moho.entity_methods 
local EntityGetPosition = EntityMethods.GetPosition

local UnitMethods = _G.moho.unit_methods 
local UnitGetVelocity = UnitMethods.GetVelocity
local UnitGetTargetEntity = UnitMethods.GetTargetEntity

local WeaponMethods = _G.moho.weapon_methods 
local WeaponGetCurrentTargetPos = WeaponMethods.GetCurrentTargetPos

-- upvalue math functions for performance
local MathClamp = math.clamp
local MathPow = math.pow

-- This table stores last acceleration and numbers of bombs left in a cluster bomb run, as well as the original target
-- format : bomb_data[entityId] = {n_left=<n_left>, acc=<last_acc>, targetpos=<original_targetpos>}
bomb_data = {}

-- upvalued reference for performance
local upBombData = bomb_data

-- default null vector
local NullVector = Vector(0, 0, 0)

CalculateBallisticAcceleration = function(weapon, projectile)

    -- default acceleration
    local acc = 4.75

    -- quick exit: no launcher means we just do something
    local launcher = ProjectileGetLauncher(projectile)
    if not launcher then return acc end

    -- temporarily value used to catch vectors
    local vector
    
    -- get projectile position and velocity
    vector = EntityGetPosition(projectile)
    local ppx = vector[1]
    local ppy = vector[2]
    local ppz = vector[3]

    pv = UnitGetVelocity(launcher)

    -- get target position (take into account target bone)
    local tpx, tpy, tpz, tv

    -- get the entity we're targeting
    local target = UnitGetTargetEntity(launcher)

    -- firing at unit
    if target and IsUnit(target) then 
        vector = EntityGetPosition(target)
        local tpx = vector[1]
        local tpz = vector[3]
        local tpy = GetSurfaceHeight(tpx, tpz)

        local tv = UnitGetVelocity(target)

    -- firing at ground or props 
    else 
        vector = WeaponGetCurrentTargetPos(weapon)
        local tpx = vector[1]
        local tpz = vector[3]
        local tpy = GetSurfaceHeight(tpx, tpz)

        local tv = 0
    end

    -- retrieve blueprint information all in one go
    local bp = weapon:GetBlueprint()
    local salvoSize = bp.MuzzleSalvoSize
    local salvoDelay = bp.MuzzleSalvoDelay
    local dropShort = bp.DropBombShort

    -- not happy with this yet
    local id = launcher.EntityId
    local data = upBombData[id] or { 
        acceleration = acc, 
        remaining = salvoSize, 
        -- target x / y / z
        tpx = tpx, tpy = tpy, tpz = tpz,
        -- override = false,
    }

    data.override = target.Dead 

    -- we can override the acceleration when we've lost the target
    if data.override then
        -- use same acceleration as last bomb
        acc = data.acceleration
        data.remaining = data.remaining - 1

        if data.remaining < 1 then
            upBombData[id] = nil
        end

        return acc
    end

    -- compute flat distances velocity
    local dv = 10 * math.abs(pv - tv)

    -- early exit: we can just drop and we'll hit
    if dv == 0 then 
        return acc 
    end

    -- compute flat distance of position
    local dp = VDist2(ppx, ppz, tpx, tpz)

    -- deliberately drop the bomb before the target, could be useful for torpedo bombers
    if dropShort then
        dp = dp * MathClamp(1 - dropShort, 0, 1)
    end

    -- calculate space between bombs, multiplier of 0.5 to make them overlap
    local len = MuzzleSalvoDelay * dv * 0.5
    local current_bomb = salvoSize - data.remaining

    -- calculate the position for this particular bomb
    dp = dp - (len * (salvoSize - 1)) / 2 + len * current_bomb
    data.remaining = data.remaining - 1
    if data.remaining < 1 then
        upBombData[id] = nil
    end

    -- how many seconds until the bomb hits the target in xz-space
    local time = dp / dv
    if time == 0 then return acc end

    -- determine y coordinate
    local tpx = tpx + time * tvx
    local tpz = tpz + time * tvz
    local tpy = GetSurfaceHeight(tpx, tpz)

    -- The basic formula for displacement over time is x = v0*t + 0.5*a*t^2
    -- x: displacement, v0: initial velocity, a: acceleration, t: time
    -- v0 is zero due to projectiles not inheriting y-speed of bomber
    -- now we can calculate what acceleration we need to make it hit the target in the y-axis
    -- a = 2 * (1/t)^2 * x

    local invTime = 1 / time
    acc = 2 * invTime * invTime * (ppy - tvy)

    -- store last acceleration in case target dies in the middle of carpet bomb run
    data.acc = acc

    return acc
end
