
--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
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

local TMissileCruiseProjectile = import("/lua/terranprojectiles.lua").TMissileCruiseProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")

--- Used by xel0306
---@class TIFMissileCruise05 : TMissileCruiseProjectile
TIFMissileCruise05 = ClassProjectile(TMissileCruiseProjectile) {

    FxTrails = EffectTemplate.TMissileExhaust01,
    FxTrailOffset = -0.85,

    FxAirUnitHitScale = 0.90,
    FxLandHitScale = 0.90,
    FxNoneHitScale = 0.90,
    FxPropHitScale = 0.90,
    FxProjectileHitScale = 0.90,
    FxProjectileUnderWaterHitScale = 0.90,
    FxShieldHitScale = 0.90,
    FxUnderWaterHitScale = 0.90,
    FxUnitHitScale = 0.90,
    FxWaterHitScale = 0.90,
    FxOnKilledScale = 0.90,

    ---@param self TIFMissileCruise05
    OnCreate = function(self)
        TMissileCruiseProjectile.OnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread, self))
    end,

}
TypeClass = TIFMissileCruise05

