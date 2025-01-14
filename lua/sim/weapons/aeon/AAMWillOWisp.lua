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
local DefaultCreateProjectileAtMuzzle = DefaultProjectileWeapon.CreateProjectileAtMuzzle
local EffectTemplate = import("/lua/effecttemplates.lua")
local GetDistanceBetweenTwoPoints2 = import('/lua/utilities.lua').GetDistanceBetweenTwoPoints2

local EntityGetPositionXYZ = moho.entity_methods.GetPositionXYZ
local ProjectileGetVelocity = moho.projectile_methods.GetVelocity
local ProjectileSetVelocity = moho.projectile_methods.SetVelocity
local ProjectileSetBallisticAcceleration = moho.projectile_methods.SetBallisticAcceleration
local WeaponGetCurrentTarget = moho.weapon_methods.GetCurrentTarget

local MathSqrt = math.sqrt
local MathMax = math.max
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds
local IsDestroyed = IsDestroyed

--- Makes the flare fall at a natural speed at the top of its trajectory so that it can catch the missile better
---@param proj Projectile
---@param t number
local function floatProjectile(proj, t)
    WaitSeconds(t)
    if not IsDestroyed(proj) then
        ProjectileSetVelocity(proj, 0, 0, 0)
        ProjectileSetBallisticAcceleration(proj, -4.9)
    end
end

--- Aeon anti-projectile weapon that launches flares to a bit above the target projectile's height.
---@class AAMWillOWisp : DefaultProjectileWeapon
AAMWillOWisp = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AAntiMissileFlareFlash,

    --- Launch the flare to the target's height
    ---@param self AAMWillOWisp
    ---@param muzzle Bone
    ---@return Projectile
    CreateProjectileAtMuzzle = function(self, muzzle)
        local proj = DefaultCreateProjectileAtMuzzle(self, muzzle)

        -- Assume we only target and fire at projectiles. The projectile may destroy itself right as we fire though if it hit something.
        local target = WeaponGetCurrentTarget(self) --[[@as Projectile?]]
        if target then
            local targetX, targetY, targetZ = EntityGetPositionXYZ(target)
            local targetVX, targetVY, targetVZ = ProjectileGetVelocity(target)

            local posX, posY, posZ = EntityGetPositionXYZ(self.unit, muzzle)

            -- Make the distance a bit shorter to allow the flare hitbox to catch the projectile and to launch faster to catch projectiles on the edge of the range
            local arriveTime = MathMax(GetDistanceBetweenTwoPoints2(targetX, targetZ, posX, posZ) - 10, 10) / (MathSqrt(targetVX * targetVX + targetVZ * targetVZ) * 10)

            -- Have a minimum height so that shields don't get hit by diverted projectiles
            -- Also launch a bit above the projectile's height to catch it better as the flare falls down
            local dy = MathMax(targetY - posY + 9, 17)

            local vy0 = dy / arriveTime * 2
            ProjectileSetVelocity(proj, 0, vy0, 0)
            ProjectileSetBallisticAcceleration(proj, -vy0 / arriveTime)
            -- Can't wait in here or else it interrupts the firing cycle
            ForkThread(floatProjectile, proj, arriveTime)
        end

        return proj
    end,
}
