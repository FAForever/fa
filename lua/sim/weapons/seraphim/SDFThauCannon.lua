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
local EffectTemplate = import('/lua/effecttemplates.lua')

-- Units: XSL0303
---@class SDFThauCannon : DefaultProjectileWeapon
SDFThauCannon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.STauCannonMuzzleFlash,
    FxMuzzleTerrainTypeName = 'ThauTerrainMuzzle',

    PlayFxMuzzleSequence = function(self, muzzle)
        DefaultProjectileWeapon.PlayFxMuzzleSequence(self, muzzle)
        local pos = self.unit:GetPosition()
        local TerrainType = GetTerrainType(pos.x,pos.z)
        local effectTable = TerrainType.FXOther[self.unit.Layer][self.FxMuzzleTerrainTypeName]
        if effectTable ~= nil then
            local army = self.unit.Army
            for k, v in effectTable do
                CreateAttachedEmitter(self.unit, muzzle, army, v)
            end
        end
    end,
}