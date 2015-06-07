local StructureUnit = import('/lua/sim/units/StructureUnit.lua').StructureUnit

--- Walls.
ConcreteStructureUnit = Class(StructureUnit) {
    OnCreate = function(self)
        StructureUnit.OnCreate(self)
        self:Destroy()
    end
}
