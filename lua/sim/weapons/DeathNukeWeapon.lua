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

local BareBonesWeapon = import('/lua/sim/weapons/BareBonesWeapon.lua').BareBonesWeapon
local NukeDamage = import("/lua/sim/nukedamage.lua").NukeAOE

---@class DeathNukeWeapon : BareBonesWeapon
DeathNukeWeapon = ClassWeapon(BareBonesWeapon) {

    ---@param self DeathNukeWeapon
    OnFire = function(self)
    end,

    ---@param self DeathNukeWeapon
    Fire = function(self)
        local bp = self.Blueprint
        local launcher = self.unit
        local proj = launcher:CreateProjectile(bp.ProjectileId, 0, 0, 0, nil, nil, nil):SetCollision(false)
        proj:ForkThread(proj.EffectThread)

        -- Play the explosion sound
        local audNukeExplosion = proj.Blueprint.Audio.NukeExplosion
        if audNukeExplosion then
            self:PlaySound(audNukeExplosion)
        end

        proj.InnerRing = NukeDamage()
        proj.InnerRing:OnCreate(bp.NukeInnerRingDamage, bp.NukeInnerRingRadius, bp.NukeInnerRingTicks,
            bp.NukeInnerRingTotalTime)
        proj.OuterRing = NukeDamage()
        proj.OuterRing:OnCreate(bp.NukeOuterRingDamage, bp.NukeOuterRingRadius, bp.NukeOuterRingTicks,
            bp.NukeOuterRingTotalTime)

        local pos = proj:GetPosition()
        local brain = launcher:GetAIBrain()
        local damageType = bp.DamageType
        local army = launcher.Army
        proj.InnerRing:DoNukeDamage(launcher, pos, brain, army, damageType)
        proj.OuterRing:DoNukeDamage(launcher, pos, brain, army, damageType)

        -- Stop it calling DoDamage any time in the future.
        proj.DoDamage = function(self, instigator, DamageData, targetEntity) end
    end,
}