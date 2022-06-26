--****************************************************************************
--**
--**  File     :  /lua/sim/defaultdamage.lua
--**  Author(s): John Comes
--**
--**  Summary  : A common way to do damage over than direct damage, ie: Dots, area dots, etc.
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

-- scope as upvalue for performance
local Damage = Damage 
local DamageArea = DamageArea

local Entity = import('/lua/sim/Entity.lua').Entity

--- A cache of categories for stun allow / disallow strings
local CategoriesCache = { }

--- A dummy entity that is used to pass over stun parameters via stun instances
---@class StunEntity
---@field CategoriesAllowed Categories
---@field CategoriesDisallowed Categories | boolean
local StunEntity = Class(Entity) {

    CategoriesAllowed = categories.ALLUNITS,
    CategoriesDisallowed = false,

    --- Defines the categories that we're allowed to stun, caching the parsing. Defaults to categories.ALLUNITS
    ---@param self StunEntity       # Instance of StunEntity
    ---@param cats string | nil     # String of categories, defaults to categories.ALLUNITS
    SetAllowedCategories = function (self, cats)

        -- if no categories given, we apply to all units
        if not cats then
            self.CategoriesDisallowed = categories.ALLUNITS
            return
        end

        local cached = CategoriesCache[cats]
        if cached then
            self.CategoriesAllowed = cached
        end

        cached = ParseEntityCategory(cats)
        CategoriesCache[cats] = cached
        self.CategoriesAllowed = cached
    end,

    --- Defines the categories that we're allowed to stun, caching the parsing. Defaults to false
    ---@param self StunEntity       # Instance of StunEntity
    ---@param cats string | nil     # String of categories, defaults to false
    SetDisallowedCategories = function (self, cats)

        -- if no categories given, we do not exclude units
        if not cats then
            self.CategoriesDisallowed = false
            return
        end

        local cached = CategoriesCache[cats]
        if cached then
            self.CategoriesDisallowed = cached
        end

        cached = ParseEntityCategory(cats)
        CategoriesCache[cats] = cached
        self.CategoriesDisallowed = cached
    end,
}

--- Create an instance for each army
local StunEntityInstances = { }
for k, brain in ArmyBrains do 
    StunEntityInstances[k] = StunEntity({ Army = brain:GetArmyIndex() })
end

--- Applies an area stun at the given location, caches the parsing of categories
---@param position Vector           # Origin of the stun
---@param duration number           # Duration of the stun, in seconds
---@param radius number             # Radius of the stun, in oGrids
---@param allowed string | nil      # String representation of allowed categories, nil allows all units
---@param disallowed string | nil   # String representation of disallowed categories, nil disallows no units
---@param army number               # Army where the stun damage originates from
function ApplyAreaStun (position, duration, radius, allowed, disallowed, army)
    StunEntityInstances[army]:SetAllowedCategories(allowed)
    StunEntityInstances[army]:SetDisallowedCategories(disallowed)

    DamageArea(StunEntityInstances[army], position, radius, 10 * duration, 'Stun', false)
end

--- Applies a single-target stun, caches the parsing of categories
---@param target Unit               # Target to stun
---@param duration number           # Duration of the stun, in seconds
---@param allowed string | nil      # String representation of allowed categories, nil allows all units
---@param disallowed string | nil   # String representation of disallowed categories, nil disallows no units
---@param army number               # Army where the stun damage originates from
function ApplyStun (target, duration, allowed, disallowed, army)
    StunEntityInstances[army]:SetAllowedCategories(allowed)
    StunEntityInstances[army]:SetDisallowedCategories(disallowed)

    Damage(StunEntityInstances[army], target, 10 * duration, 'Stun')
end

-- scope as upvalue for performance
local VectorCache = Vector(0, 0, 0)
local CoroutineYield = coroutine.yield

local EntityBeenDestroyed = _G.moho.entity_methods.BeenDestroyed
local EntityGetPositionXYZ = _G.moho.entity_methods.GetPositionXYZ

--- Applies damage over time on a single target
---@param instigator Unit | Projectile | Weapon | Entity
---@param unit Unit         # Unit to apply damage instances to
---@param pulses number     # Number of damage instances
---@param pulseTime number  # Time between damage instances
---@param damage number     # Damage amount
---@param damType string    # Damage type such as 'Normal' or 'Force'
---@param friendly boolean  # Flag to indicate we can damage allied units
function UnitDoTThread (instigator, unit, pulses, pulseTime, damage, damType, friendly)

    -- localize for performance
    local position = VectorCache
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

--- Applies damage over time in an area
---@param instigator Unit | Projectile | Weapon | Entity
---@param position Vector       # Location to apply damage instances at
---@param pulses number         # Number of damage instances
---@param pulseTime number      # Time between damage instances
---@param radius number         # Damage radius
---@param damage number         # Damage amount
---@param damType string        # Damage type such as 'Normal' or 'Force'
---@param friendly boolean      # Flag to indicate we can damage allied units
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

-- SCALABLE RADIUS AREA DOT
-- - Allows for a scalable damage radius that begins with DamageStartRadius and ends
-- - 

--- Allows for a scalable damage radius that begins with DamageStartRadius and ends with DamageEndRadius, interpolates between based on frequency and duration.
---@deprecated
---@param entity any
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
