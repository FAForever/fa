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

local AIMFlareProjectile = import("/lua/aeonprojectiles.lua").AIMFlareProjectile
local AIMFlareProjectileOnCreate = AIMFlareProjectile.OnCreate
local AIMFlareProjectileOnDestroy = AIMFlareProjectile.OnDestroy

---@class AIMAntiMissile01 : AIMFlareProjectile
---@field RedirectedMissiles number
AIMAntiMissile01 = ClassProjectile(AIMFlareProjectile) {

    ---@param self AIMAntiMissile01
    OnCreate = function(self)
        AIMFlareProjectileOnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        self.RedirectedMissiles = 0
    end,

    ---@param self AIMAntiMissile01
    OnDestroy = function(self)
        AIMFlareProjectileOnDestroy(self)

        local redirectedMissiles = self.RedirectedMissiles
        if redirectedMissiles > 0 then
            CreateLightParticleIntel(self, -1, self.Army, redirectedMissiles, 5, 'glow_02', 'ramp_blue_22')
        end
    end,
}

TypeClass = AIMAntiMissile01
