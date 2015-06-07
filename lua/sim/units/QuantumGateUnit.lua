local FactoryUnit = import('/lua/sim/units/FactoryUnit.lua').FactoryUnit

QuantumGateUnit = Class(FactoryUnit) {
    OnKilled = function(self, instigator, type, overkillRatio)
        self:StopUnitAmbientSound('ActiveLoop')
        FactoryUnit.OnKilled(self, instigator, type, overkillRatio)
    end
}
