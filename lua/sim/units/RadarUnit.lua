
local StructureUnit = import("/lua/sim/units/structureunit.lua").StructureUnit
local StructureUnitOnCreate = StructureUnit.OnCreate
local StructureUnitOnStopBeingBuilt = StructureUnit.OnStopBeingBuilt
local StructureUnitOnKilled = StructureUnit.OnKilled
local StructureUnitOnDestroy = StructureUnit.OnDestroy
local StructureUnitOnIntelDisabled = StructureUnit.OnIntelDisabled
local StructureUnitOnIntelEnabled = StructureUnit.OnIntelEnabled

---@class RadarUnit : StructureUnit
RadarUnit = ClassUnit(StructureUnit) {

    OnCreate = function(self)
        StructureUnitOnCreate(self)

        -- keep track of radars
        self.Brain.Radars[self.Blueprint.TechCategory][self.EntityId] = self
    end,

    ---@param self RadarUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnitOnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
    end,

    OnKilled = function (self, instigator, type, overkillRatio)
        StructureUnitOnKilled(self, instigator, type, overkillRatio)

        -- keep track of radars
        self.Brain.Radars[self.Blueprint.TechCategory][self.EntityId] = nil
    end,

    OnDestroy = function (self)
        StructureUnitOnDestroy(self)

        -- keep track of radars
        self.Brain.Radars[self.Blueprint.TechCategory][self.EntityId] = nil
    end,

    ---@param self RadarUnit
    OnIntelDisabled = function(self, intel)
        StructureUnitOnIntelDisabled(self, intel)
        self:DestroyIdleEffects()
    end,

    ---@param self RadarUnit
    OnIntelEnabled = function(self, intel)
        StructureUnitOnIntelEnabled(self, intel)
        self:CreateIdleEffects()
    end,
}
