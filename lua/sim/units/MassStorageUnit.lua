local StructureUnit = import('/lua/sim/units/StructureUnit.lua').StructureUnit

MassStorageUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    OnStopBeingBuilt = function(self,builder,layer)
        StructureUnit.OnStopBeingBuilt(self,builder,layer)
        local aiBrain = GetArmyBrain(self:GetArmy())
        aiBrain:ESRegisterUnitMassStorage(self)
        local curMass = aiBrain:GetEconomyStoredRatio('MASS')
        if curMass > 0.11 then
            self:CreateBlinkingLights('Yellow')
        else
            self:CreateBlinkingLights('Red')
        end
    end,

    OnMassStorageStateChange = function(self, newState)
        if newState == 'EconLowMassStore' then
            self:CreateBlinkingLights('Red')
        elseif newState == 'EconMidMassStore' then
            self:CreateBlinkingLights('Yellow')
        elseif newState == 'EconFullMassStore' then
            self:CreateBlinkingLights('Green')
        end
    end,
}
