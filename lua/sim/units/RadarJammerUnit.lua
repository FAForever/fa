
local StructureUnit = import("/lua/sim/units/structureunit.lua").StructureUnit
local EffectUtil = import("/lua/effectutilities.lua")

---@class RadarJammerUnit : StructureUnit
RadarJammerUnit = ClassUnit(StructureUnit) {

    -- Shut down intel while upgrading
    ---@param self RadarJammerUnit
    ---@param unitbuilding RadarJammerUnit
    ---@param order boolean
    OnStartBuild = function(self, unitbuilding, order)
        StructureUnit.OnStartBuild(self, unitbuilding, order)
        self:SetMaintenanceConsumptionInactive()
        self:DisableUnitIntel('Construction', 'Jammer')
        self:DisableUnitIntel('Construction', 'RadarStealthField')
    end,

    -- If we abort the upgrade, re-enable the intel
    ---@param self RadarJammerUnit
    ---@param unitBeingBuilt Unit
    OnStopBuild = function(self, unitBeingBuilt)
        StructureUnit.OnStopBuild(self, unitBeingBuilt)
        self:SetMaintenanceConsumptionActive()
        self:EnableUnitIntel('Construction', 'Jammer')
        self:EnableUnitIntel('Construction', 'RadarStealthField')
    end,

    -- If we abort the upgrade, re-enable the intel
    ---@param self RadarJammerUnit
    OnFailedToBuild = function(self)
        StructureUnit.OnFailedToBuild(self)
        self:SetMaintenanceConsumptionActive()
        self:EnableUnitIntel('Construction', 'Jammer')
        self:EnableUnitIntel('Construction', 'RadarStealthField')
    end,

    ---@param self RadarJammerUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
    end,

    ---@param self RadarJammerUnit
    OnIntelEnabled = function(self, intel)
        StructureUnit.OnIntelEnabled(self, intel)
        if self.IntelEffects and not self.IntelFxOn then
            self.IntelEffectsBag = {}
            self:CreateTerrainTypeEffects(self.IntelEffects, 'FXIdle', self.Layer, nil, self.IntelEffectsBag)
            self.IntelFxOn = true
        end
    end,

    ---@param self RadarJammerUnit
    OnIntelDisabled = function(self, intel)
        StructureUnit.OnIntelDisabled(self, intel)
        EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
        self.IntelFxOn = false
    end,
}
