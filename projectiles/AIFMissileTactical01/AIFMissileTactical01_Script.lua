--******************************************************************************************************
--** Copyright (c) 2024 FAForever
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

local AMissileSerpentineProjectile = import("/lua/aeonprojectiles.lua").AMissileSerpentineProjectile
local AMissileSerpentineProjectileOnCreate = AMissileSerpentineProjectile.OnCreate
local AMissileSerpentineProjectileOnImpact = AMissileSerpentineProjectile.OnImpact

local EffectTemplate = import("/lua/effecttemplates.lua")

-- upvalue scope for performance
local CreateLightParticleIntel = CreateLightParticleIntel


--- Used by UAB2108 (T2 Tactical Missile Launcher)
---@class AIFMissileTactical01 : AMissileSerpentineProjectile
AIFMissileTactical01 = ClassProjectile(AMissileSerpentineProjectile) {

    TerminalZigZagMultiplier = 0.5,

    FxImpactUnit = EffectTemplate.AMissileHit02,
    FxImpactProp = EffectTemplate.AMissileHit02,
    FxImpactLand = EffectTemplate.AMissileHit02,

    FxLandHitScale = 1.65,
    FxPropHitScale = 1.65,
    FxUnitHitScale = 1.65,

    ---@param self AIFMissileTactical01
    OnCreate = function(self)
        AMissileSerpentineProjectileOnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread( self.MovementThread,self ))
    end,

    --- Called by the engine when the projectile impacts something
    ---@param self Projectile
    ---@param targetType string
    ---@param targetEntity Unit | Prop
    OnImpact = function(self, targetType, targetEntity)
        AMissileSerpentineProjectileOnImpact(self, targetType, targetEntity)

        local army = self.Army

        -- create light flashes
        CreateLightParticleIntel(self, -1, army, 8, 2, 'flare_lens_add_02', 'ramp_green_02')
        CreateLightParticleIntel(self, -1, army, 12, 4, 'flare_lens_add_02', 'ramp_green_12')
    end
}
TypeClass = AIFMissileTactical01