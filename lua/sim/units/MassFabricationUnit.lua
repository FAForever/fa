
local StructureUnit = import("/lua/sim/units/structureunit.lua").StructureUnit

---@class MassFabricationUnit : StructureUnit
MassFabricationUnit = ClassUnit(StructureUnit) {

    ---@param self MassFabricationUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
        self:SetProductionActive(true)
    end,

    ---@param self MassFabricationUnit
    OnConsumptionActive = function(self)
        StructureUnit.OnConsumptionActive(self)
        self:SetMaintenanceConsumptionActive()
        self:SetProductionActive(true)
        self:ApplyAdjacencyBuffs()
        self.ConsumptionActive = true
    end,

    ---@param self MassFabricationUnit
    OnConsumptionInActive = function(self)
        StructureUnit.OnConsumptionInActive(self)
        self:SetMaintenanceConsumptionInactive()
        self:SetProductionActive(false)
        self:RemoveAdjacencyBuffs()
        self.ConsumptionActive = false
    end,

    ---@param self MassFabricationUnit
    OnProductionPaused = function(self)
        StructureUnit.OnProductionPaused(self)
        self:StopUnitAmbientSound('ActiveLoop')
    end,

    ---@param self MassFabricationUnit
    OnProductionUnpaused = function(self)
        StructureUnit.OnProductionUnpaused(self)
        self:PlayUnitAmbientSound('ActiveLoop')
    end,

    ---@param self MassFabricationUnit
    OnExcessEnergy = function(self)
        self:OnProductionUnpaused()
    end,

    ---@param self MassFabricationUnit
    OnNoExcessEnergy = function(self)
        self:OnProductionPaused()
    end,

}