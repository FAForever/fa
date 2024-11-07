--****************************************************************************
--**
--**  File     :  /lua/sim/defaultdamage.lua
--**  Author(s): John Comes
--**
--**  Summary  : A common way to do damage over than direct damage, ie: Dots, area dots, etc.
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

-- upvalue for performance
local Damage = Damage
local DamageArea = DamageArea

-- cache for performance
local VectorCache = Vector(0, 0, 0)
local MathMod = math.mod
local MATH_IRound = MATH_IRound
local WaitTicks = WaitTicks

local EntityBeenDestroyed = _G.moho.entity_methods.BeenDestroyed
local EntityGetPositionXYZ = _G.moho.entity_methods.GetPositionXYZ

--- Performs damage over time on a target, waiting the interval *before* dealing damage.
---@param instigator Unit
---@param target Unit | Prop | Projectile
---@param pulses number
---@param pulseInterval number
---@param damage number
---@param damageType DamageType
function UnitDoTThread(instigator, target, pulses, pulseInterval, damage, damageType)
    -- localize for performance
    local position = VectorCache
    local Damage = Damage
    local EntityGetPositionXYZ = EntityGetPositionXYZ
    local WaitTicks = WaitTicks
    local MathMod = MathMod

    -- convert seconds to ticks, have to "wait" 1 extra tick to get to the end of the current tick
    pulseInterval = 10 * pulseInterval + 1
    -- accumulator to compensate for error caused by `WaitTicks` only working with integers
    local accum = 0

    for i = 1, pulses do
        if target and not EntityBeenDestroyed(target) then
            position[1], position[2], position[3] = EntityGetPositionXYZ(target)
            Damage(instigator, position, target, damage, damageType)
        else
            break
        end
        accum = accum + pulseInterval
        if accum > 1 then
            -- final accumulator value may be #.999 which needs to be rounded
            if i == pulses then
                WaitTicks(MATH_IRound(accum))
            else
                WaitTicks(accum)
                accum = MathMod(accum, 1)
            end
        end
    end
end

--- Performs damage over time in a given area, waiting the interval *before* dealing damage.
---@param instigator Unit
---@param position Vector
---@param pulses number
---@param pulseInterval number
---@param radius number
---@param damage number
---@param damageType DamageType
---@param damageFriendly boolean
---@param damageSelf boolean
function AreaDoTThread(instigator, position, pulses, pulseInterval, radius, damage, damageType, damageFriendly, damageSelf)
    -- localize for performance
    local DamageArea = DamageArea
    local WaitTicks = WaitTicks
    local MathMod = MathMod

    -- convert seconds to ticks, have to "wait" 1 extra tick to get to the end of the current tick
    pulseInterval = 10 * pulseInterval + 1
    -- accumulator to compensate for error caused by `WaitTicks` only working with integers
    local accum = 0

    for i = 1, pulses do
        accum = accum + pulseInterval
        if accum > 1 then
            -- final accumulator value may be #.999 which needs to be rounded
            if i == pulses then
                WaitTicks(MATH_IRound(accum))
            else
                WaitTicks(accum)
                accum = MathMod(accum, 1)
            end
        end
        DamageArea(instigator, position, radius, damage, damageType, damageFriendly, damageSelf)
    end
end

--#region Deprecated functionality 

-- SCALABLE RADIUS AREA DOT
-- - Allows for a scalable damage radius that begins with DamageStartRadius and ends
-- - with DamageEndRadius, interpolates between based on frequency and duration.
---@deprecated
---@param entity Entity
function ScalableRadiusAreaDoT(entity)
    local spec = entity.Spec.Data

    -- FIX ME
    -- Change this to get position from the entity, once we have the tech to set the entity's position
    -- local position = entity:GetPosition()
    local position = entity.Spec.Position
    local radius = spec.StartRadius or 0
    local freq = spec.Frequency or 1
    local dur = spec.Duration or 1
    if dur != freq then
        local reductionScalar = (radius - (spec.EndRadius or 1) ) * freq / (dur - freq)
        local duration = math.floor(dur / freq)

        for i = 1, duration do
            DamageArea(entity, position, radius, spec.Damage, spec.Type, spec.DamageFriendly)
            radius = radius - reductionScalar
            WaitSeconds(freq)
        end
    end
    entity:Destroy()
end
--#endregion
