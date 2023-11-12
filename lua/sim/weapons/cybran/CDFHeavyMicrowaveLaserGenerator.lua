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

local DefaultBeamWeapon = import('/lua/sim/defaultweapons.lua').DefaultBeamWeapon
local CollisionBeamFile = import('/lua/sim/CollisionBeam.lua').CollisionBeamFile
local EffectTemplate = import('/lua/effecttemplates.lua')

--- SPIDER BOT WEAPON!
---@class CDFHeavyMicrowaveLaserGenerator : DefaultBeamWeapon
---@field RotatorManip moho.RotateManipulator
CDFHeavyMicrowaveLaserGenerator = ClassWeapon(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.MicrowaveLaserCollisionBeam01,
    FxUpackingChargeEffects = EffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 1,

    ---@param self CDFHeavyMicrowaveLaserGenerator
    ---@param muzzle string
    PlayFxBeamStart = function(self, muzzle)
        DefaultBeamWeapon.PlayFxBeamStart(self, muzzle)

        -- create rotator if it doesn't exist
        local rotator = self.RotatorManip
        if not rotator then
            local unit = self.unit
            rotator = CreateRotator(unit, 'Center_Turret_Barrel', 'z')
            unit.Trash:Add(rotator)
            self.RotatorManip = rotator
        end

        -- set their respective properties when firing
        rotator:SetTargetSpeed(500)
        rotator:SetAccel(200)
    end,

    ---@param self CDFHeavyMicrowaveLaserGenerator
    ---@param beam string
    PlayFxBeamEnd = function(self, beam)
        DefaultBeamWeapon.PlayFxBeamEnd(self, beam)

        -- if it exists, then stop rotating
        local rotator = self.RotatorManip
        if rotator then
            rotator:SetTargetSpeed(0)
            rotator:SetAccel(90)
        end
    end,
}