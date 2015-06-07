local StructureUnit = import('/lua/sim/units/StructureUnit.lua').StructureUnit

SonarUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    OnStopBeingBuilt = function(self,builder,layer)
        StructureUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionActive()
    end,

    CreateIdleEffects = function(self)
        StructureUnit.CreateIdleEffects(self)
        self.TimedSonarEffectsThread = self:ForkThread(self.TimedIdleSonarEffects)
    end,

    TimedIdleSonarEffects = function( self )
        local layer = self:GetCurrentLayer()
        local army = self:GetArmy()
        local pos = self:GetPosition()

        if self.TimedSonarTTIdleEffects then
            while not self.Dead do
                for kTypeGroup, vTypeGroup in self.TimedSonarTTIdleEffects do
                    local effects = self.GetTerrainTypeEffects( 'FXIdle', layer, pos, vTypeGroup.Type, nil )

                    for kb, vBone in vTypeGroup.Bones do
                        for ke, vEffect in effects do
                            local emit = CreateAttachedEmitter(self,vBone,army,vEffect):ScaleEmitter(vTypeGroup.Scale or 1)
                            if vTypeGroup.Offset then
                                emit:OffsetEmitter(vTypeGroup.Offset[1] or 0, vTypeGroup.Offset[2] or 0,vTypeGroup.Offset[3] or 0)
                            end
                        end
                    end
                end
                self:PlayUnitSound('Sonar')
                WaitSeconds( 6.0 )
            end
        end
    end,

    DestroyIdleEffects = function(self)
        self.TimedSonarEffectsThread:Destroy()
        StructureUnit.DestroyIdleEffects(self)
    end,

    OnIntelDisabled = function(self)
        StructureUnit.OnIntelDisabled(self)
        self:DestroyBlinkingLights()
        self:CreateBlinkingLights('Red')
    end,

    OnIntelEnabled = function(self)
        StructureUnit.OnIntelEnabled(self)
        self:DestroyBlinkingLights()
        self:CreateBlinkingLights('Green')
    end,
}
