
local StructureUnit = import("/lua/sim/units/structureunit.lua").StructureUnit
local StructureUnitOnStopBeingBuilt = StructureUnit.OnStopBeingBuilt
local StructureUnitCreateIdleEffects = StructureUnit.CreateIdleEffects
local StructureUnitDestroyIdleEffects = StructureUnit.DestroyIdleEffects

---@class SonarUnit : StructureUnit
---@field TimedSonarEffectsThread? thread
SonarUnit = ClassUnit(StructureUnit) {

    ---@param self SonarUnit
    ---@param builder Unit
    ---@param layer string
    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnitOnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
    end,

    ---@param self SonarUnit
    CreateIdleEffects = function(self)
        StructureUnitCreateIdleEffects(self)
        self.TimedSonarEffectsThread = self:ForkThread(self.TimedIdleSonarEffects)
    end,

    ---@param self SonarUnit
    TimedIdleSonarEffects = function(self)
        local layer = self.Layer
        local pos = self:GetPosition()

        if self.TimedSonarTTIdleEffects then
            while not self.Dead do
                for kTypeGroup, vTypeGroup in self.TimedSonarTTIdleEffects do
                    local effects = self.GetTerrainTypeEffects('FXIdle', layer, pos, vTypeGroup.Type, nil)

                    for kb, vBone in vTypeGroup.Bones do
                        for ke, vEffect in effects do
                            local emit = CreateAttachedEmitter(self, vBone, self.Army, vEffect):ScaleEmitter(vTypeGroup.Scale or 1)
                            if vTypeGroup.Offset then
                                emit:OffsetEmitter(vTypeGroup.Offset[1] or 0, vTypeGroup.Offset[2] or 0, vTypeGroup.Offset[3] or 0)
                            end
                        end
                    end
                end
                self:PlayUnitSound('Sonar')
                WaitSeconds(6.0)
            end
        end
    end,

    ---@param self SonarUnit
    DestroyIdleEffects = function(self)
        StructureUnitDestroyIdleEffects(self)
        local timedSonarEffectsThread = self.TimedSonarEffectsThread
        if timedSonarEffectsThread then
            timedSonarEffectsThread:Destroy()
        end
    end,
}
