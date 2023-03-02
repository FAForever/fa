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
local MathFloor = math.floor
local CoroutineYield = coroutine.yield

local EntityBeenDestroyed = _G.moho.entity_methods.BeenDestroyed
local EntityGetPositionXYZ = _G.moho.entity_methods.GetPositionXYZ

--- Performs damage over time on a unit.
---@param instigator Unit
---@param unit Unit
---@param pulses any
---@param pulseTime integer
---@param damage number
---@param damType DamageType
---@param friendly boolean
function UnitDoTThread (instigator, unit, pulses, pulseTime, damage, damType, friendly)

    -- localize for performance
    local position = VectorCache
    local DamageArea = DamageArea
    local CoroutineYield = CoroutineYield

    -- convert time to ticks
    pulseTime = 10 * pulseTime + 1

    for i = 1, pulses do
        if unit and not EntityBeenDestroyed(unit) then
            position[1], position[2], position[3] = EntityGetPositionXYZ(unit)
            Damage(instigator, position, unit, damage, damType )
        else
            break
        end
        CoroutineYield(pulseTime)
    end
end

--- Performs damage over time in a given area.
---@param instigator Unit
---@param position number
---@param pulses any
---@param pulseTime integer
---@param radius number
---@param damage number
---@param damType DamageType
---@param friendly boolean
function AreaDoTThread (instigator, position, pulses, pulseTime, radius, damage, damType, friendly)

    -- localize for performance
    local DamageArea = DamageArea
    local CoroutineYield = CoroutineYield

    -- compute ticks between pulses
    pulseTime = 10 * pulseTime + 1

    for i = 1, pulses do
        DamageArea(instigator, position, radius, damage, damType, friendly)
        CoroutineYield(pulseTime)
    end
end

-- Deprecated functionality -- 

-- SCALABLE RADIUS AREA DOT
-- - Allows for a scalable damage radius that begins with DamageStartRadius and ends
-- - with DamageEndRadius, interpolates between based on frequency and duration.
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