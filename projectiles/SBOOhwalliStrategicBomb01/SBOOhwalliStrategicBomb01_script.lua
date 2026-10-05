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
        local marker = VisionMarkerOpti()
        marker:UpdatePosition(position[1], position[3])
        marker:UpdateDuration(9)
        marker:UpdateIntel(self.Army, 12, 'Vision', true)

        local data = self.DamageData
        local instigator = self.Launcher or self

        -- forked first so the delayed prop effects land on the same tick as, and before, the DoT pulse
        ForkThread(self.EffectThread, self, position, instigator, data.DamageRadius or 0)

        -- initial damage on impact, remaining damage as a DoT pulse (weapon blueprint)
        self:DoDamage(instigator, data, targetEntity, position)

        self:Destroy()
    end,

    --- trees and props only: the engine DoT system can not express these damage types
    ---@param self SBOOhwalliStategicBomb01
    ---@param position Vector
    ---@param instigator? Unit | Projectile
    ---@param radius number
    EffectThread = function(self, position, instigator, radius)
        -- knock over trees
        DamageArea(instigator, position, 0.75 * radius, 1, 'TreeForce', true, true)
        DamageArea(instigator, position, 0.75 * radius, 1, 'TreeForce', true, true)
        DamageArea(instigator, position, 0.9 * radius, 1, 'TreeFire', true, true)

        -- disintegrate props when the delayed damage pulse lands
        WaitTicks(27)
        DamageArea(instigator, position, 0.4 * radius, 1, 'Disintegrate', true, true)
    end,
}
TypeClass = SBOOhwalliStategicBomb01
