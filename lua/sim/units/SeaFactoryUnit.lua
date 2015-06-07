local FactoryUnit = import('/lua/sim/units/FactoryUnit.lua').FactoryUnit

SeaFactoryUnit = Class(FactoryUnit) {
    -- Disable the default rocking behavior
    StartRocking = function(self)
    end,

    StopRocking = function(self)
    end,
}
