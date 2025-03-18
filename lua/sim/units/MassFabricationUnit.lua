
local StructureUnit = import("/lua/sim/units/structureunit.lua").StructureUnit
local StructureUnitOnScriptBitSet = StructureUnit.OnScriptBitSet
local StructureUnitOnScriptBitClear = StructureUnit.OnScriptBitClear
local StructureUnitOnStopBeingBuilt = StructureUnit.OnStopBeingBuilt
local StructureUnitOnProductionPaused = StructureUnit.OnProductionPaused
local StructureUnitOnProductionUnpaused = StructureUnit.OnProductionUnpaused
local StructureUnitOnConsumptionActive = StructureUnit.OnConsumptionActive
local StructureUnitOnConsumptionInActive = StructureUnit.OnConsumptionInActive

---@class MassFabricationUnit : StructureUnit
MassFabricationUnit = ClassUnit(StructureUnit) {

    ---@param self MassFabricationUnit
    ---@param bit number
    OnScriptBitSet = function(self, bit)
        if bit == 4 then
            -- no longer track us, we want to be disabled
            self.Brain:RemoveEnergyExcessUnit(self)

            -- immediately disable production
            self:OnProductionPaused()
        else
            StructureUnitOnScriptBitSet(self, bit)
        end
    end,

    ---@param self MassFabricationUnit
    ---@param bit number
    OnScriptBitClear = function (self, bit)
        if bit == 4 then
            -- make brain track us to enable / disable accordingly
            self.Brain:AddDisabledEnergyExcessUnit(self)
        else
            StructureUnitOnScriptBitClear(self, bit)
        end
    end,

    ---@param self MassFabricationUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnitOnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
        self:SetProductionActive(true)

        -- make brain track us to enable / disable accordingly
        self.Brain:AddEnabledEnergyExcessUnit(self)
    end,

    ---@param self MassFabricationUnit
    OnConsumptionActive = function(self)
        StructureUnitOnConsumptionActive(self)
        self:SetMaintenanceConsumptionActive()
        self:SetProductionActive(true)
        self:ApplyAdjacencyBuffs()
        self.ConsumptionActive = true
    end,

    ---@param self MassFabricationUnit
    OnConsumptionInActive = function(self)
        StructureUnitOnConsumptionInActive(self)
        self:SetMaintenanceConsumptionInactive()
        self:SetProductionActive(false)
        self:RemoveAdjacencyBuffs()
        self.ConsumptionActive = false
    end,

    ---@param self MassFabricationUnit
    OnProductionPaused = function(self)
        StructureUnitOnProductionPaused(self)
        self:StopUnitAmbientSound('ActiveLoop')
    end,

    ---@param self MassFabricationUnit
    OnProductionUnpaused = function(self)
        StructureUnitOnProductionUnpaused(self)
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