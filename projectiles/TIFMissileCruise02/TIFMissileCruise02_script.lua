
--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local EffectTemplate = import("/lua/effecttemplates.lua")

local TMissileCruiseSubProjectile = import("/lua/terranprojectiles.lua").TMissileCruiseSubProjectile
local TMissileCruiseSubProjectileOnCreate = TMissileCruiseSubProjectile.OnCreate
local TMissileCruiseSubProjectileOnExitWater = TMissileCruiseSubProjectile.OnExitWater
local TMissileCruiseProjectileOnImpact = TMissileCruiseSubProjectile.OnImpact

-- upvalue scope for performance
local CreateLightParticleIntel = CreateLightParticleIntel

--- Used by ues0304
---@class TIFMissileCruise02 : TMissileCruiseSubProjectile
TIFMissileCruise02 = ClassProjectile(TMissileCruiseSubProjectile) {

    FxImpactTrajectoryAligned = false,
    DestroyOnImpact = false,
    FxTrails = EffectTemplate.TMissileExhaust02,
    FxTrailOffset = -1,
    BeamName = '/effects/emitters/missile_munition_exhaust_beam_01_emit.bp',
    FxImpactUnit = EffectTemplate.TShipGaussCannonHitUnit02,
    FxImpactProp = EffectTemplate.TShipGaussCannonHit02,
    FxImpactLand = EffectTemplate.TShipGaussCannonHit02,

	FxAirUnitHitScale = 1.65,
    FxLandHitScale = 1.65,
    FxNoneHitScale = 1.65,
    FxPropHitScale = 1.65,
    FxProjectileHitScale = 1.65,
    FxProjectileUnderWaterHitScale = 1.65,
    FxShieldHitScale = 1.65,
    FxUnderWaterHitScale = 1.65,
    FxUnitHitScale = 1.65,
    FxWaterHitScale = 1.65,
    FxOnKilledScale = 1.65,

    -- reduce height due to distance
    FinalBoostAngle = 30,

    ---@param self TIFMissileCruise02
    OnCreate = function(self)
        TMissileCruiseSubProjectileOnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread, self))
    end,

    ---@param self TIFMissileCruise02
    OnExitWater = function(self)
        TMissileCruiseSubProjectileOnExitWater(self)
        self:SetDestroyOnWater(true)
    end,

    --- Called by the engine when the projectile impacts something
    ---@param self TIFMissileCruise01
    ---@param targetType string
    ---@param targetEntity Unit | Prop
    OnImpact = function(self, targetType, targetEntity)
        TMissileCruiseProjectileOnImpact(self, targetType, targetEntity)

        -- create light flashes
        CreateLightParticleIntel(self, -1, self.Army, 7, 4, 'glow_02', 'ramp_antimatter_02')
    end
}

TypeClass = TIFMissileCruise02

