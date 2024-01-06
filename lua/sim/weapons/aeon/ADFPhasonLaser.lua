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

local DefaultBeamWeapon = import("/lua/sim/defaultweapons.lua").DefaultBeamWeapon
local CollisionBeamFile = import("/lua/defaultcollisionbeams.lua")
local EffectTemplate = import("/lua/effecttemplates.lua")

local DefaultBeamWeaponPlayFxWeaponUnpackSequence = DefaultBeamWeapon.PlayFxWeaponUnpackSequence

-- upvalue scope for performance
local CreateAttachedEmitter = CreateAttachedEmitter

---@class ADFPhasonLaser : DefaultBeamWeapon
ADFPhasonLaser = ClassWeapon(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.PhasonLaserCollisionBeam,
    FxMuzzleFlash = {},
    FxChargeMuzzleFlash = {},
    FxUpackingChargeEffects = EffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 1,

    ---@param self ADFPhasonLaser
    PlayFxWeaponUnpackSequence = function(self)

        local contBeamOn = self.ContBeamOn

        if not contBeamOn then
            local unit = self.unit
            local army = self.Army
            local bp = self.Blueprint
            local rackbones = bp.RackBones
            local fxUpackingChargeEffects = self.FxUpackingChargeEffects
            local currentRackSalvoNumber = self.CurrentRackSalvoNumber
            local fxUpackingChargeEffectScale = self.FxUpackingChargeEffectScale

            for _, v in fxUpackingChargeEffects do
                for i, j in rackbones[currentRackSalvoNumber].MuzzleBones do
                    CreateAttachedEmitter(unit, j, army, v):ScaleEmitter(fxUpackingChargeEffectScale)
                end
            end
            DefaultBeamWeaponPlayFxWeaponUnpackSequence(self)
        end
    end,
}
