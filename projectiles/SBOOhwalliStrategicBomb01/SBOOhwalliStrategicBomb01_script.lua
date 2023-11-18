-- File     :  /data/projectiles/SBOOhwalliStategicBomb01/SBOOhwalliStategicBomb01_script.lua
-- Author(s):  Greg Kohne, Gordon Duclos, Matt Vainio
-- Summary  :  Ohwalli-Strategic Bomb script, used on XSA402
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------

local SOhwalliStrategicBombProjectile = import("/lua/seraphimprojectiles.lua").SOhwalliStrategicBombProjectile
local SOhwalliStrategicBombProjectileOnCreate = SOhwalliStrategicBombProjectile.OnCreate

local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

-- upvalue scope for performance
local WaitTicks = WaitTicks
local ForkThread = ForkThread
local DamageArea = DamageArea

--- Ohwalli-Strategic Bomb script, used on XSA402
---@class SBOOhwalliStategicBomb01 : SOhwalliStrategicBombProjectile
SBOOhwalliStategicBomb01 = ClassProjectile(SOhwalliStrategicBombProjectile) {

    ---@param self SBOOhwalliStategicBomb01
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        SOhwalliStrategicBombProjectileOnCreate(self, inWater)
        CreateLightParticleIntel(self, -1, self.Army, 15, 5, 'flare_lens_add_02', 'ramp_blue_13')
    end,

    ---@param self SBOOhwalliStategicBomb01
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        local effectController = '/effects/entities/SBOOhwalliBombEffectController01/SBOOhwalliBombEffectController01_proj.bp'
        self:CreateProjectile(effectController, 0, 0, 0, 0, 0, 0)

        local position = self:GetPosition()

        -- create vision
        local marker = VisionMarkerOpti({ Owner = self })
        marker:UpdatePosition(position[1], position[3])
        marker:UpdateDuration(9)
        marker:UpdateIntel(self.Army, 12, 'Vision', true)

        -- separate damage thread
        local data = self.DamageData
        local damage = data.DamageAmount
        local radius = data.DamageRadius or 0
        local instigator = self.Launcher or self
        ForkThread(self.DamageThread, self, position, instigator, damage, radius)

        self:Destroy()
    end,

    ---@param self SBOOhwalliStategicBomb01
    ---@param position Vector
    ---@param instigator? Unit | Projectile
    ---@param damage number
    ---@param radius number
    DamageThread = function(self, position, instigator, damage, radius)
        -- knock over trees
        DamageArea(instigator, position, 0.75 * radius, 1, 'TreeForce', false)
        DamageArea(instigator, position, 0.75 * radius, 1, 'TreeForce', false)

        -- initial damage
        DamageArea(instigator, position, radius, 0.1 * damage, 'Normal', false)
        DamageArea(instigator, position, 0.9 * radius, 1, 'TreeFire', false)

        -- wait for the full explosion and then deal the remaining damage
        WaitTicks(26)
        DamageArea(instigator, position, 0.2 * radius, 1, 'Disintegrate', false)
        DamageArea(instigator, position, radius, 0.3 * damage, 'Normal', false)
        WaitTicks(1)
        DamageArea(instigator, position, 0.3 * radius, 1, 'Disintegrate', false)
        DamageArea(instigator, position, radius, 0.3 * damage, 'Normal', false)
        WaitTicks(1)
        DamageArea(instigator, position, 0.4 * radius, 1, 'Disintegrate', false)
        DamageArea(instigator, position, radius, 0.3 * damage, 'Normal', false)
    end,
}
TypeClass = SBOOhwalliStategicBomb01
