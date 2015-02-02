------------------------------------------------------------------
-- File     :  /lua/sim/CalcBallisticAcceleration.lua
-- Author(s):  Kaskouy, Brute51
-- Summary  :  Calculates bomb drop ballistic acceleration values
------------------------------------------------------------------

--[[
This script was done by Kaskouy and is based on my 'static' first bomb
bug fix. Kaskouy's code is more flexible and should work in (almost) any 
case wheras mine only does when the bomber flies at default height at 
default speed. The script below takes all that into account (speed, 
height, etc) and calculates the proper value to feed to the bomb adjust 
function.
I (brute51) improved the original script to work with attack ground. Also
changed a few minor things here and there.
--]]

-- This is a fraction between 0 and 1, indicating which part of the target we want to hit
-- 0 : on feet ; 1 : on head
-- I personally think that 0 is better, but if you want to try, feel free to play with this...
local alpha = 0

-- This table stores the acceleration previously calculated.
-- This serves for bombers carrying several bombs: acceleration is calculated
-- for first bomb, then stored in this table and reused for the next bombs
-- format : bomber_table[entityId] = {acc, remaining_bombs}
local bomber_table = {}

-- This is the default value returned by the function if a problem occurred in the calculation...
-- But normally that may never happen
local default_value = 4.75

CalculateBallisticAcceleration = function (weapon, proj, MuzzleSalvoSize, MuzzleSalvoDelay)
    local launcher = proj:GetLauncher()
    if not launcher then return default_value end

    local acc = default_value

    local entityId = launcher:GetEntityId()

    if bomber_table[entityId] then
        -- Acceleration already calculated for previous bomb
        acc = bomber_table[entityId].acc
        bomber_table[entityId].remaining_bombs = bomber_table[entityId].remaining_bombs - 1
      
        if bomber_table[entityId].remaining_bombs <= 0 then
            bomber_table[entityId] = nil
        end
    else
        local pos_target = {0, 0, 0}
        local wx, wy, wz = 0, 0, 0

        -- Get projectile position
        local pos_proj = proj:GetPosition()

        -- Get the target if it's an entity
        local target = launcher:GetTargetEntity()

        if target and IsUnit(target) then
            -- Get target position
            pos_target = target:GetPosition()
          
            -- Get target speed
            wx, wy, wz = target:GetVelocity()
            wx = wx * 10
            wy = wy * 10
            wz = wz * 10
        else    -- Target is not a unit, so could be non-unit entity, or the ground
            -- Get target position
            pos_target = weapon:GetCurrentTargetPos()

            -- Set alpha to 0 so we don't overshoot because of this variable
            alpha = 0
        end

        -- Return default value if the target's position data is incomplete
        if not pos_target[1] or not pos_target[2] or not pos_target[3] then
            return default_value
        end

        -- Get unit height
        local unit_height = pos_target[2] - GetSurfaceHeight(pos_target[1], pos_target[3])

        -- Decide where vertically on the target to aim the bomb
        if weapon:GetBlueprint().DropBombShort then
            -- Deliberately launch Torpedo bombers short
            alpha = (weapon:GetBlueprint().DropBombShort) * (pos_proj[2] - GetSurfaceHeight(pos_target[1], pos_target[3]))
            pos_target[2] = GetSurfaceHeight(pos_target[1], pos_target[3]) - alpha
        else
            pos_target[2] = GetSurfaceHeight(pos_target[1], pos_target[3]) + alpha * unit_height
        end

        -- Get launcher unit's speed, which is also the velocity of the dropped bomb
        local ux, uy, uz = launcher:GetVelocity()
        ux = ux * 10
        uy = uy * 10
        uz = uz * 10

        local v_launcher = math.sqrt(math.pow(ux,2) + math.pow(uy,2) + math.pow(uz,2))
        local vhorz_launcher = math.sqrt(math.pow(ux,2) + math.pow(uz,2))

        if vhorz_launcher == 0 then return default_value end -- The launching unit is not moving, no need to change the acceleration

        -- Calculate bomb speed. This is an odd way to calculate it, but it seems to be correct
        local vx = ux * v_launcher / vhorz_launcher
        local vz = uz * v_launcher / vhorz_launcher

        -- Calculate the distance between projectile and target
        local dist = math.sqrt(math.pow(pos_target[1] -  pos_proj[1], 2) +  math.pow(pos_target[3] -  pos_proj[3], 2))

        -- Calculate the offset : this is for planes carrying several bombs. We are calculating
        -- the trajectory of first bomb, but as the result will be a carpet bomb, we try to have
        -- the target in the center of the flames, so the first bomb must fall before the target
        -- (0.1 is the delay between 2 drops)
        local offset = (MuzzleSalvoSize - 1) * MuzzleSalvoDelay * vhorz_launcher / 2

        dist = dist - offset  -- This is not exact in some cases, but should be good enough

        -- Calculate height between projectile and target
        local height = pos_proj[2] - pos_target[2]

        -- Calculate horizontal speed between projectile and target
        local vhorz = math.sqrt( math.pow(vx-wx, 2) + math.pow(vz-wz, 2) )
        if vhorz == 0 then return default_value end

        -- Calculate the time after which the bomb will hit the target
        local t = dist / vhorz
        if t == 0 then return default_value end

        -- Calculate the position of target at time t
        local pos_target_t = {0,0,0}
        pos_target_t[1] = pos_target[1] + wx * t
        pos_target_t[3] = pos_target[3] + wz * t

        -- Calculate the position of the target vertically at time t
        if weapon:GetBlueprint().DropBombShort then
            pos_target_t[2] = GetSurfaceHeight(pos_target_t[1], pos_target_t[3]) - alpha
        else
            pos_target_t[2] = GetSurfaceHeight(pos_target_t[1], pos_target_t[3]) + alpha * unit_height
        end

        -- Calculate the average vertical speed
        vvert = (pos_target_t[2] - pos_target[2]) / t

        -- Calculate ballistic acceleration so that the projectile hits the target
        acc = 2 * math.pow(1/t , 2) * (height - t * vvert)

        -- Fill bomber_table if several bombs must be dropped
        if MuzzleSalvoSize > 1 then
            bomber_table[entityId] = {}
            bomber_table[entityId].acc = acc
            bomber_table[entityId].remaining_bombs = MuzzleSalvoSize - 1
        end
    end

    return acc
end 