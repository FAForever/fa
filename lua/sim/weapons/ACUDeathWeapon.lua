--**********************************************************************************
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
--**********************************************************************************

local BareBonesWeapon = import("/lua/sim/weapons/barebonesweapon.lua").BareBonesWeapon

--- Creates effects similar to DeathNukeWeapon, but its damage does not bypass shields.
---@class ACUDeathWeapon : BareBonesWeapon
ACUDeathWeapon = ClassWeapon(BareBonesWeapon) {
    ---@param self ACUDeathWeapon
    OnFire = function(self)
    end,

    ---@param self ACUDeathWeapon
    Fire = function(self)
        local bp = self.Blueprint
        local unit = self.unit
        local proj = unit:CreateProjectile(bp.ProjectileId, 0, 0, 0, nil, nil, nil):SetCollision(false)
        proj:ForkThread(proj.EffectThread)

        -- Play the explosion sound
        local audNukeExplosion = proj.Blueprint.Audio.NukeExplosion
        if audNukeExplosion then
            self:PlaySound(audNukeExplosion)
        end

        --Inner then outer ring damage
        DamageArea(unit, unit:GetPosition(), bp.NukeInnerRingRadius, bp.NukeInnerRingDamage,
            bp.DamageType or 'Normal', bp.DamageFriendly or false, false)
        DamageArea(unit, unit:GetPosition(), bp.NukeOuterRingRadius, bp.NukeOuterRingDamage,
            bp.DamageType or 'Normal', bp.DamageFriendly or false, false)
    end,
}