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

local DefaultProjectileWeapon = import('/lua/sim/defaultweapons.lua').DefaultProjectileWeapon
local DefaultProjectileWeaponPlayFxMuzzleSequence = DefaultProjectileWeapon.PlayFxMuzzleSequence

local EffectTemplate = import('/lua/effecttemplates.lua')

-- upvalue scope for performance
local CreateAttachedEmitter = CreateAttachedEmitter

---@class TAMPhalanxWeapon : DefaultProjectileWeapon
TAMPhalanxWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TPhalanxGunMuzzleFlash,
    FxShellEject  = EffectTemplate.TPhalanxGunShells,

    ---@param self TAMPhalanxWeapon
    ---@param muzzle Bone
    PlayFxMuzzleSequence = function(self, muzzle)
        DefaultProjectileWeaponPlayFxMuzzleSequence(self, muzzle)

        local unit = self.unit
        local army = self.Army
        local turretBonePitch = self.Blueprint.TurretBonePitch
        local fxShellEject = self.FxShellEject
        if turretBonePitch then
            for k, v in fxShellEject do
                CreateAttachedEmitter(unit, turretBonePitch, army, v)
            end
        end
    end,
}
