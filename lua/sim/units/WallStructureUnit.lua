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
local CreateScalableUnitExplosion = import("/lua/defaultexplosions.lua").CreateScalableUnitExplosion

-- upvalue scope for performance
local EntityCategoryContains = EntityCategoryContains

local StructureUnitOnDamage = StructureUnit.OnDamage

local CategoriesWall = categories.WALL

---@class WallStructureUnit : StructureUnit
WallStructureUnit = ClassUnit(StructureUnit) {

    WallOverspillFactor = 0.2,

    ---@param self WallStructureUnit
    ---@param instigator Unit
    ---@param amount number
    ---@param vector Vector
    ---@param damageType DamageType
    OnDamage = function(self, instigator, amount, vector, damageType)
        StructureUnitOnDamage(self, instigator, amount, vector, damageType)

        -- basic damage overspill for adjacent walls. Works similar to that of shields except that it only
        -- takes into account walls that are directly adjacent

        if damageType != 'WallOverspill' then
            local adjacentUnits = self.AdjacentUnits
            if adjacentUnits then
                local wallOverspillFactor = self.WallOverspillFactor
                for id, adjacentUnit in adjacentUnits do
                    if EntityCategoryContains(CategoriesWall, adjacentUnit) then
                        adjacentUnit:OnDamage(instigator, wallOverspillFactor * amount, vector, 'WallOverspill')
                    end
                end
            end
        end
    end,

    --- Separate death thread for walls that is simplified
    ---@param self WallStructureUnit
    ---@param overkillRatio number
    ---@param instigator Unit | Projectile
    DeathThread = function(self, overkillRatio, instigator)
        -- cap the amount of debris we can spawn
        if overkillRatio > 3 then
            overkillRatio = 3
        end

        CreateScalableUnitExplosion(self, 1 + overkillRatio)
        self:DestroyUnit(overkillRatio)
    end,
}
