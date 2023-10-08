
local StructureUnit = import("/lua/sim/defaultunits/structureunit.lua").StructureUnit

local StructureUnitOnDamage = StructureUnit.OnDamage

---@class WallStructureUnit : StructureUnit
WallStructureUnit = ClassUnit(StructureUnit) {

    IsWall = true,
    WallOverspillFactor = 0.2,

    ---@param self WallStructureUnit
    ---@param instigator Unit
    ---@param amount number
    ---@param vector Vector
    ---@param damageType DamageType
    OnDamage = function(self, instigator, amount, vector, damageType)
        StructureUnitOnDamage(self, instigator, amount, vector, damageType)

        if damageType != 'WallOverspill' then
            local adjacentUnits = self.AdjacentUnits
            if adjacentUnits then
                local wallOverspillFactor = self.WallOverspillFactor
                for id, adjacentUnit in adjacentUnits do
                    if adjacentUnit.IsWall then
                        adjacentUnit:OnDamage(instigator, wallOverspillFactor * amount, vector, 'WallOverspill')
                    end
                end
            end
        end
    end,
}
