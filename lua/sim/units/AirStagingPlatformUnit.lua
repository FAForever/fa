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

local StructureUnit = import("/lua/sim/units/structureunit.lua").StructureUnit

---@class AirStagingPlatformUnit : StructureUnit
AirStagingPlatformUnit = ClassUnit(StructureUnit) {
    --- Detach units from air staging on death to allow working around an engine bug
    --- where units get stuck in the air staging.
    ---@param self AirStagingPlatformUnit
    ---@param instigator Unit
    ---@param damageType DamageType
    ---@param excessDamageRatio number
    Kill = function(self, instigator, damageType, excessDamageRatio)
        -- check if we're dead because we can still take damage/be killed during death animations
        if not self.Dead then
            self:TransportDetachAllUnits(false)
        end
        -- `Kill` can only be called with 4 args or 1 arg
        if instigator then
            StructureUnit.Kill(self, instigator, damageType, excessDamageRatio)
        else
            StructureUnit.Kill(self)
        end
    end,
}
