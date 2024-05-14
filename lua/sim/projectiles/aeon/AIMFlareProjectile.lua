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

local Flare = import("/lua/defaultantiprojectile.lua").Flare
local EffectTemplate = import("/lua/effecttemplates.lua")

local EmitterProjectile = import("/lua/sim/defaultprojectiles.lua").EmitterProjectile
local EmitterProjectileOnCreate = EmitterProjectile.OnCreate
local EmitterProjectileOnDestroy = EmitterProjectile.OnDestroy

-- upvalue scope for performance
local IsEnemy = IsEnemy
local EntityCategoryContains = EntityCategoryContains

-- pre-computed for performance
local FlareCategories = categories.TACTICAL + categories.MISSILE

--- AEON FLARE PROJECTILES
---@class AIMFlareProjectile : EmitterProjectile
---@field RedirectedMissiles number
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

        -- missiles that hit the flare are immediately neutralized
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)

        -- Create several flares of different sizes. A collision check is done when an entity enters the
        -- collision box of another entity. As long as the entity remains inside no additional checks
        -- are done. Therefore we create several flares of different sizes to catch missiles that are
        -- far out and close by.

        local flareSpecs = {
            Radius = 10,
            Owner = self,
            Category = "MISSILE TACTICAL",
        }

        local trash = self.Trash
        for k = 1, 3 do
            flareSpecs.Radius = 8 + k * 5
            trash:Add(Flare(flareSpecs))
        end
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
        -- flat out destroy the tactical missile when we get in contact with it
        if EntityCategoryContains(FlareCategories, other) and
            IsEnemy(self.Army, other.Army)
        then
            -- destroy the other projectile
            Damage(self.Launcher, other:GetPosition(), other, 200, "Normal")
        end

        return true
    end,


}
