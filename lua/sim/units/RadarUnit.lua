local StructureUnit = import('/lua/sim/units/StructureUnit.lua').StructureUnit

RadarUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    OnStopBeingBuilt = function(self,builder,layer)
        StructureUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionActive()
    end,

    OnIntelDisabled = function(self)
        StructureUnit.OnIntelDisabled(self)
        self:DestroyIdleEffects()
        self:DestroyBlinkingLights()
        self:CreateBlinkingLights('Red')
    end,

    OnIntelEnabled = function(self)
        StructureUnit.OnIntelEnabled(self)
        self:DestroyBlinkingLights()
        self:CreateBlinkingLights('Green')
        self:CreateIdleEffects()
    end,
}
