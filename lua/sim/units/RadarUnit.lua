
local StructureUnit = import("/lua/sim/units/structureunit.lua").StructureUnit

---@class RadarUnit : StructureUnit
RadarUnit = ClassUnit(StructureUnit) {

    OnCreate = function(self)
        StructureUnit.OnCreate(self)

        -- keep track of radars
        self.Brain.Radars[self.Blueprint.TechCategory][self.EntityId] = self
    end,

    ---@param self RadarUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
    end,

    OnKilled = function (self, instigator, type, overkillRatio)
        StructureUnit.OnKilled(self, instigator, type, overkillRatio)

        -- keep track of radars
        self.Brain.Radars[self.Blueprint.TechCategory][self.EntityId] = nil
    end,

    OnDestroy = function (self)
        StructureUnit.OnDestroy(self)

        -- keep track of radars
        self.Brain.Radars[self.Blueprint.TechCategory][self.EntityId] = nil
    end,

    ---@param self RadarUnit
    OnIntelDisabled = function(self, intel)
        StructureUnit.OnIntelDisabled(self, intel)
        self:DestroyIdleEffects()
    end,

    ---@param self RadarUnit
    OnIntelEnabled = function(self, intel)
        StructureUnit.OnIntelEnabled(self, intel)
        self:CreateIdleEffects()
    end,
}
