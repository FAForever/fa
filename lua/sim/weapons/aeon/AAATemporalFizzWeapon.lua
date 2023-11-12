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
local DefaultProjectileWeaponPlayFxRackSalvoChargeSequence = DefaultProjectileWeapon.PlayFxRackSalvoChargeSequence

-- upvalue scope for performance
local CreateAttachedEmitter = CreateAttachedEmitter

---@class AAATemporalFizzWeapon : DefaultProjectileWeapon
AAATemporalFizzWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxChargeEffects = {'/effects/emitters/temporal_fizz_muzzle_charge_01_emit.bp', },
    FxMuzzleFlash = {'/effects/emitters/temporal_fizz_muzzle_flash_01_emit.bp', },

    ---@param self AAATemporalFizzWeapon
    PlayFxRackSalvoChargeSequence = function(self)
        DefaultProjectileWeaponPlayFxRackSalvoChargeSequence(self)

        local unit = self.unit
        local army = unit.Army
        local chargeEffectMuzzles = self.ChargeEffectMuzzles
        local fxChargeEffects = self.FxChargeEffects

        DefaultProjectileWeapon.PlayFxRackSalvoChargeSequence(self)
        for _, v in chargeEffectMuzzles do
            for i, j in fxChargeEffects do
                CreateAttachedEmitter(unit, v, army, j)
            end
        end
    end,
}

LOG(repr(debug.listcode(AAATemporalFizzWeapon.PlayFxRackSalvoChargeSequence)))
