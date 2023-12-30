--**********************************************************************************
--** Copyright (c) 2023 FAForever
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
--**********************************************************************************

local EmitterProjectile = import("/lua/sim/defaultprojectiles.lua").EmitterProjectile
local EmitterProjectileOnCreate = EmitterProjectile.OnCreate
local EmitterProjectileOnDestroy = EmitterProjectile.OnDestroy
local Flare = import("/lua/defaultantiprojectile.lua").Flare
local EffectTemplate = import("/lua/effecttemplates.lua")

-- upvalue scope for performance
local IsEnemy = IsEnemy
local EntityCategoryContains = EntityCategoryContains

-- pre-computed for performance
local FlareCategories = categories.TACTICAL + categories.MISSILE

--- AEON FLARE PROJECTILES
---@class AIMFlareProjectile : EmitterProjectile
AIMFlareProjectile = ClassProjectile(EmitterProjectile) {
    FxTrails = EffectTemplate.AAntiMissileFlare,
    FxTrailScale = 1.0,
    FxImpactNone = EffectTemplate.AAntiMissileFlareHit,
    FxImpactProjectile = EffectTemplate.AAntiMissileFlareHit,
    FxOnKilled = EffectTemplate.AAntiMissileFlareHit,
    FxUnitHitScale = 0.4,
    FxLandHitScale = 0.4,
    FxWaterHitScale = 0.4,
    FxUnderWaterHitScale = 0.4,
    FxAirUnitHitScale = 0.4,
    FxNoneHitScale = 0.4,
    DestroyOnImpact = false,

    ---@param self AIMFlareProjectile
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        EmitterProjectileOnCreate(self, inWater)
        self.RedirectedMissiles = 0

        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)

        local flareSpecs = {
            Radius = 10,
            Owner = self,
            Category = "MISSILE TACTICAL",
        }

        local flares = {}
        for k = 1, 3 do
            flareSpecs.Radius = 8 + k * 5
            flares[k] = self.Trash:Add(Flare(flareSpecs))
        end

        self.Flares = flares
    end,

    ---@param self AIMFlareProjectile
    OnDestroy = function(self)
        EmitterProjectileOnDestroy(self)

        -- create a pretty flash depending on the number of missiles we redirected
        local redirectedMissiles = self.RedirectedMissiles
        if redirectedMissiles > 0 then
            CreateLightParticleIntel(self, -1, self.Army, redirectedMissiles, 5, 'glow_02', 'ramp_blue_22')
        end
    end,

    ---@param self AIMAntiMissile01
    ---@param other Projectile
    ---@return boolean
    OnCollisionCheck = function(self, other)
        -- nullify damage amount when it hits the flare. We do this to prevent projectiles
        -- damaging the unit that fired the flare, as if it 'encapsulates' the damage
        if EntityCategoryContains(FlareCategories, other) and
            IsEnemy(self.Army, other.Army)
        then
            -- destroy the other projectile
            Damage(self.Launcher, other:GetPosition(), other, 200, "Normal")
        end

        return true
    end,


}
