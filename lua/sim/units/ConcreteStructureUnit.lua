
local StructureUnit = import("/lua/sim/units/structureunit.lua").StructureUnit

---@class ConcreteStructureUnit : StructureUnit
ConcreteStructureUnit = ClassUnit(StructureUnit) {
    ---@param self ConcreteStructureUnit
    OnCreate = function(self)
        StructureUnit.OnCreate(self)
        self:Destroy()
    end
}

