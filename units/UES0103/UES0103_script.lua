--******************************************************************************************************
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
--******************************************************************************************************

local TSeaUnit = import("/lua/terranunits.lua").TSeaUnit
local TSeaUnitOnStopBeingBuilt = TSeaUnit.OnStopBeingBuilt
local TSeaUnitOnKilled = TSeaUnit.OnKilled

local TAALinkedRailgun = import("/lua/terranweapons.lua").TAALinkedRailgun
local TDFGaussCannonWeapon = import("/lua/terranweapons.lua").TDFGaussCannonWeapon

-- upvalue scope for performance
local CreateRotator = CreateRotator

local TrashBagAdd = TrashBag.Add
local RotatorSetTargetSpeed = moho.RotateManipulator.SetTargetSpeed
local RotatorSetAccel = moho.RotateManipulator.SetAccel

---@class UES0103 : TSeaUnit
---@field Spinner01 moho.RotateManipulator
---@field Spinner02 moho.RotateManipulator
---@field Spinner03 moho.RotateManipulator
UES0103 = ClassUnit(TSeaUnit) {
    Weapons = {
        MainGun = ClassWeapon(TDFGaussCannonWeapon) {},
        AAGun = ClassWeapon(TAALinkedRailgun) {},
    },

    ---@param self UES0103
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        TSeaUnitOnStopBeingBuilt(self, builder, layer)

        local trash = self.Trash
        self.Spinner01 = TrashBagAdd(trash, CreateRotator(self, 'Spinner01', 'y', nil, 360, 0, 180))
        self.Spinner02 = TrashBagAdd(trash, CreateRotator(self, 'Spinner02', 'y', nil, 90, 0, 180))
        self.Spinner03 = TrashBagAdd(trash, CreateRotator(self, 'Spinner03', 'y', nil, -180, 0, -180))
    end,

    ---@param self UES0103
    ---@param instigator Unit
    ---@param type DamageType
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        TSeaUnitOnKilled(self, instigator, type, overkillRatio)

        if self:GetFractionComplete() >= 1.0 then

            local spinner

            spinner = self.Spinner01
            RotatorSetTargetSpeed(spinner, 0)
            RotatorSetAccel(spinner, -40)

            spinner = self.Spinner02
            RotatorSetTargetSpeed(spinner, 0)
            RotatorSetAccel(spinner, -10)

            spinner = self.Spinner03
            RotatorSetTargetSpeed(spinner, 0)
            RotatorSetAccel(spinner, 20)

            -- create sparkles
            local emit
            local army = self.Army
            local trash = self.Trash

            emit = TrashBagAdd(trash,
                CreateAttachedEmitter(self, 'Spinner01', army, '/effects/emitters/sparks_11_emit.bp'))
            emit:SetEmitterParam('REPEATTIME', Random(20, 40))

            emit = TrashBagAdd(trash,
                CreateAttachedEmitter(self, 'Spinner02', army, '/effects/emitters/sparks_11_emit.bp'))
            emit:SetEmitterParam('REPEATTIME', Random(20, 40))

            emit = TrashBagAdd(trash,
                CreateAttachedEmitter(self, 'Spinner03', army, '/effects/emitters/sparks_11_emit.bp'))
            emit:SetEmitterParam('REPEATTIME', Random(20, 40))

            -- create a short debrish-isch flash, as if the dishes explode
            CreateLightParticleIntel(self, 'Spinner01', army, 0.15 + 0.05 * Random(2, 4), Random(3, 6), 'debris_alpha_03'
                , 'ramp_antimatter_01')
            CreateLightParticleIntel(self, 'Spinner02', army, 0.15 + 0.05 * Random(2, 4), Random(3, 6), 'debris_alpha_03'
                , 'ramp_antimatter_01')
            CreateLightParticleIntel(self, 'Spinner03', army, 0.15 + 0.05 * Random(2, 4), Random(3, 6), 'debris_alpha_03'
                , 'ramp_antimatter_01')
        end
    end,
}

TypeClass = UES0103
