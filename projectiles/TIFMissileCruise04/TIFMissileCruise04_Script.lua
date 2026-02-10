
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

--- Used by ues0202
---@class TIFMissileCruise04 : TMissileCruiseProjectile
TIFMissileCruise04 = ClassProjectile(TMissileCruiseProjectile) {
    FxAirUnitHitScale = 2.25,
    FxLandHitScale = 2.25,
    FxNoneHitScale = 2.25,
    FxPropHitScale = 2.25,
    FxProjectileHitScale = 2.25,
    FxProjectileUnderWaterHitScale = 2.25,
    FxShieldHitScale = 2.25,
    FxUnderWaterHitScale = 2.25,
    FxUnitHitScale = 2.25,
    FxWaterHitScale = 2.25,
    FxOnKilledScale = 2.25,
}
TypeClass = TIFMissileCruise04

