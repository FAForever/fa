
local StructureUnit = import("/lua/defaultunits/structure.lua").StructureUnit

---@class ConcreteStructureUnit : StructureUnit
ConcreteStructureUnit = ClassUnit(StructureUnit) {
    ---@param self ConcreteStructureUnit
    OnCreate = function(self)
        StructureUnit.OnCreate(self)
        self:Destroy()
    end
}

