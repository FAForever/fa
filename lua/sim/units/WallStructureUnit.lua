
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
