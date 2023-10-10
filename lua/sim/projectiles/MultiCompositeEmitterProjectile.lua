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


local MultiPolyTrailProjectile = import("/lua/sim/projectiles/multipolytrailprojectile.lua").MultiPolyTrailProjectile

-- upvalue for performance
local CreateBeamEmitterOnEntity = CreateBeamEmitterOnEntity

---@class MultiCompositeEmitterProjectile : MultiPolyTrailProjectile
MultiCompositeEmitterProjectile = ClassProjectile(MultiPolyTrailProjectile) {

    Beams = {'/effects/emitters/default_beam_01_emit.bp',},
    PolyTrails = {'/effects/emitters/test_missile_trail_emit.bp'},
    PolyTrailOffset = { 0 },
    RandomPolyTrails = 0,
    FxTrails = { },

    ---@param self MultiCompositeEmitterProjectile
    OnCreate = function(self)
        MultiPolyTrailProjectile.OnCreate(self)

        local army = self.Army
        local beams = self.Beams

        for _, beamName in beams do
            CreateBeamEmitterOnEntity(self, -1, army, beamName)
        end
    end,
}
