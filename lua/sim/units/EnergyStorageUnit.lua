local StructureUnit = import('/lua/sim/units/StructureUnit.lua').StructureUnit

EnergyStorageUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    OnStopBeingBuilt = function(self,builder,layer)
        StructureUnit.OnStopBeingBuilt(self,builder,layer)
        local aiBrain = GetArmyBrain(self:GetArmy())
        aiBrain:ESRegisterUnitEnergyStorage(self)
        local curEnergy = aiBrain:GetEconomyStoredRatio('ENERGY')
        if curEnergy > 0.11 then
            self:CreateBlinkingLights('Yellow')
        else
            self:CreateBlinkingLights('Red')
        end
    end,

    OnEnergyStorageStateChange = function(self, newState)
        if newState == 'EconLowEnergyStore' then
            self:CreateBlinkingLights('Red')
        elseif newState == 'EconMidEnergyStore' then
            self:CreateBlinkingLights('Yellow')
        elseif newState == 'EconFullEnergyStore' then
            self:CreateBlinkingLights('Green')
        end
    end,
}
