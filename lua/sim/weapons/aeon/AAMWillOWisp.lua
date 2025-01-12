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

local DefaultProjectileWeapon = import("/lua/sim/defaultweapons.lua").DefaultProjectileWeapon
local EffectTemplate = import("/lua/effecttemplates.lua")
local EntityMethods = moho.entity_methods
local EntityGetPositionXYZ = EntityMethods.GetPositionXYZ
local EntityGetBoneDirection = EntityMethods.GetBoneDirection
local GetDistanceBetweenTwoPoints2 = import('/lua/utilities.lua').GetDistanceBetweenTwoPoints2

---@param proj Projectile
---@param t number
local function floatProjectile(proj, t)
    WaitSeconds(t)
    proj:SetVelocity(0, 0, 0)
    proj:SetBallisticAcceleration(-4.9)
end

---@class AAMWillOWisp : DefaultProjectileWeapon
AAMWillOWisp = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AAntiMissileFlareFlash,

    --- Launch the flare to the target's height
    ---@param self AAMWillOWisp
    ---@param muzzle Bone
    ---@return Projectile
    CreateProjectileAtMuzzle = function(self, muzzle)
        local proj = DefaultProjectileWeapon.CreateProjectileAtMuzzle(self, muzzle)

        local target = self:GetCurrentTarget()
        if target then
            local targetX, targetY, targetZ = EntityGetPositionXYZ(target)
            local targetDX, targetDY, targetDZ = target:GetVelocity()

            local unit = self.unit
            local posX, posY, posZ = EntityGetPositionXYZ(unit, muzzle)
            
            local arriveTime = (GetDistanceBetweenTwoPoints2(targetX, targetZ, posX, posZ) - 10) / (math.sqrt(targetDX * targetDX + targetDZ * targetDZ) * 10)

            local dy = math.max(targetY - posY + targetDY * arriveTime + 9, 17)

            local vy0 = dy / arriveTime * 2
            local g = -vy0 / arriveTime
            proj:SetVelocity(0, vy0, 0)
            proj:SetBallisticAcceleration(g)
            ForkThread(floatProjectile, proj, arriveTime)
        end

        return proj
    end,
}
