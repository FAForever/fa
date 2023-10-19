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

local EmitterProjectile = import("/lua/sim/projectiles/emitterprojectile.lua").EmitterProjectile

-- upvalue scope for performance
local Random = Random
local CreateTrail = CreateTrail
local IEffectOffsetEmitter = _G.moho.IEffect.OffsetEmitter

local TableGetn = table.getn

---@class MultiPolyTrailProjectile : EmitterProjectile
MultiPolyTrailProjectile = ClassProjectile(EmitterProjectile) {

    PolyTrails = {'/effects/emitters/test_missile_trail_emit.bp'},
    PolyTrailOffset = { 0 },
    FxTrails = { },

    --- Count of how many are selected randomly for PolyTrail table
    RandomPolyTrails = 0,

    ---@param self MultiPolyTrailProjectile
    OnCreate = function(self)
        EmitterProjectile.OnCreate(self)

        local army = self.Army
        local polyTrails = self.PolyTrails
        local polyTrailOffsets = self.PolyTrailOffset
        local numberOfPolyTrails = self.RandomPolyTrails

        if polyTrails then
            local polyTrailCount = TableGetn(polyTrails)

            if numberOfPolyTrails ~= 0 then
                local index
                for i = 1, numberOfPolyTrails do
                    index = Random(1, polyTrailCount)
                    local effect = CreateTrail(self, -1, army, polyTrails[index])

                    -- only do these engine calls when they matter
                    if polyTrailOffsets[index] ~= 0 then 
                        IEffectOffsetEmitter(effect, 0, 0, polyTrailOffsets[index])
                    end
                end
            else
                for i = 1, polyTrailCount do
                    local effect = CreateTrail(self, -1, army, polyTrails[i])

                    -- only do these engine calls when they matter
                    if polyTrailOffsets[i] ~= 0 then 
                        IEffectOffsetEmitter(effect, 0, 0, polyTrailOffsets[i])
                    end
                end
            end
        end
    end,
}