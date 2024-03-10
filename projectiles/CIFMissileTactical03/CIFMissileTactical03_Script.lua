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

local CLOATacticalMissileProjectile = import("/lua/cybranprojectiles.lua").CLOATacticalMissileProjectile
local CLOATacticalMissileProjectileOnImpact = CLOATacticalMissileProjectile.OnImpact
local CLOATacticalMissileProjectileOnCreate = CLOATacticalMissileProjectile.OnCreate

-- upvalue scope for performance
local Random = Random
local CreateLightParticleIntel = CreateLightParticleIntel

local TableRandom = table.random

--- URB2108 : cybran TML
--- Cybran "Loa" Tactical Missile, structure unit launched variant of this projectile,
--- with a higher arc and distance based adjusting trajectory. Splits into child projectile
--- if it takes enough damage.
---@class CIFMissileTactical03 : CLOATacticalMissileProjectile
CIFMissileTactical03 = ClassProjectile(CLOATacticalMissileProjectile) {
    ChildCount = 3,

    ---@param self CLOATacticalMissileProjectile
    OnCreate = function(self)
        CLOATacticalMissileProjectileOnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread, self))
    end,

    --- Called by the engine when the projectile impacts something
    ---@param self CIFMissileTactical02
    ---@param targetType string
    ---@param targetEntity Unit | Prop
    OnImpact = function(self, targetType, targetEntity)
        CLOATacticalMissileProjectileOnImpact(self, targetType, targetEntity)

        local army = self.Army

        -- create light flashes
        CreateLightParticleIntel(self, -1, army, 5, 12, 'glow_03', 'ramp_red_06')
        CreateLightParticleIntel(self, -1, army, 5, 22, 'glow_03', 'ramp_antimatter_02')

        -- create flying and burning debris for the child projectiles
        local vx, _, vz = self:GetVelocity()
        for k = 1, self.ChildCount do
            local blueprint = TableRandom(self.DebrisBlueprints)
            local pvx = 0.5 * (vx + Random() - 0.5)
            local pvz = 0.5 * (vz + Random() - 0.5)
            self:CreateProjectile(blueprint, 0, 0.2, 0, pvx, 0.75, pvz)
        end
    end
}
TypeClass = CIFMissileTactical03
