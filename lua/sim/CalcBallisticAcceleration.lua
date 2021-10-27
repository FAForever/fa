
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
local UnitGetVelocity = UnitMethods.GetVelocity()

local WeaponMethods = _G.moho.weapon_methods 
local WeaponGetTargetEntity = WeaponMethods.GetTargetEntity
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

    vector = ProjectileGetVelocity(projectile)
    local pvx = 10 * vector[1]
    local pvy = 10 * vector[2]
    local pvz = 10 * vector[3]

    -- get target position
    vector = WeaponGetCurrentTargetPos(weapon)
    local tpx = vector[1]
    local tpz = vector[3]
    local tpy = GetSurfaceHeight(x, z)

    -- determine target velocity
    local entity = WeaponGetTargetEntity((projectile))
    if entity and IsUnit(entity) then 
        vector = UnitGetVelocity(entity)
    else 
        vector = NullVector
    end

    local tvx = 10 * vector[1]
    local tvy = 10 * vector[2]
    local tvz = 10 * vector[3]

    -- retrieve blueprint information all in one go
    local bp = weapon:GetBlueprint()
    local salvoSize = bp.MuzzleSalvoSize
    local salvoDelay = bp.MuzzleSalvoDelay
    local dropShort = bp.DropBombShort

    -- not happy with this yet
    local id = launcher.EntityId
    local data = upBombData[id] or { acc = acc, n_left = MuzzleSalvoSize, targetpos = target.pos }

    local mydata = upBombData[id]
    if not target.pos or mydata.usestore then
        if mydata then
            -- use same acceleration as last bomb
            acc = mydata.acc
            mydata.n_left = mydata.n_left - 1
            mydata.usestore = true -- Signal that we've lost our target to lock in these settings

            if mydata.n_left < 1 then
                upBombData[id] = nil
            end
        end

        return acc
    end

    -- compute flat distances velocity
    local dv = VDist2(pvx, pvz, tvx, tvz)

    -- early exit: we can just drop and we'll hit
    if dv == 0 then 
        return acc 
    end

    -- compute flat distance of position
    local dp = VDist2(ppx, ppz, tpx, tpz)

    -- deliberately drop the bomb before the target, could be useful for torpedo bombers
    if bp.DropBombShort then
        dp = dp * MathClamp(1 - bp.DropBombShort, 0, 1)
    end

    if upBombData[id] ~= nil then -- bomber will drop several bombs
        -- calculate space between bombs, this is multiplied by 0.5
        -- to get the bombs overlapping a bit
        local len = MuzzleSalvoDelay * dist.vel * 0.5
        local current_bomb = MuzzleSalvoSize - upBombData[id].n_left

        -- calculate the position for this particular bomb
        dist.pos = dist.pos - (len * (MuzzleSalvoSize - 1)) / 2 + len * current_bomb
        upBombData[id].n_left = upBombData[id].n_left - 1
        if upBombData[id].n_left < 1 then
            upBombData[id] = nil
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
