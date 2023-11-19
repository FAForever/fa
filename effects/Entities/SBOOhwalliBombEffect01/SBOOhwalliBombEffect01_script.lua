------------------------------------------------------------------------------
-- File     :  /data/projectiles/SBOOhwalliBombEffect01/SBOOhwalliBombEffect01_script.lua
-- Author(s):  Greg Kohne, Gordon Duclos
-- Summary  :  Ohwalli Strategic Bomb effect script, non-damaging
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------

local EmitterProjectile = import("/lua/sim/defaultprojectiles.lua").EmitterProjectile
local EmitterProjectileOnImpact = EmitterProjectile.OnImpact

local EffectTemplate = import("/lua/EffectTemplates.lua")

local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

--- Ohwalli Strategic Bomb effect script, non-damaging
---@class SBOOhwalliBombEffect01 : EmitterProjectile
SBOOhwalliBombEffect01 = Class(EmitterProjectile) {
	FxTrails = EffectTemplate.SOhwalliBombPlumeFxTrails01,

	---@param self Projectile
	---@param targetType string
	---@param targetEntity Unit | Prop
	OnImpact = function(self, targetType, targetEntity)
		EmitterProjectileOnImpact(self, targetType, targetEntity)

		local army = self.Army
		local position = self:GetPosition()

        -- create vision
        local marker = VisionMarkerOpti({ Owner = self })
        marker:UpdatePosition(position[1], position[3])
        marker:UpdateDuration(6)
        marker:UpdateIntel(army, 5, 'Vision', true)

		-- create a flash upon impacting
		CreateLightParticleIntel(self, -1, army, 3, 5, 'glow_03', 'ramp_antimatter_02')

		-- create a bit of fire and additional damage
		DamageArea(self, position, 2, 1, "TreeForce", false)
		DamageArea(self, position, 3, 1, "TreeFire", false)
		DamageArea(self, position, 2, 1, "TreeForce", false)
		DamageArea(self, position, 1, 1, 'Disintegrate', false)
		DamageArea(self, position, 3, 300, "Normal", false)
	end,
}
TypeClass = SBOOhwalliBombEffect01
