--
-- Thermal Vent
--
local Prop = import("/lua/sim/prop.lua").Prop

ThermalVent01 = Class(Prop) {
    OnCreate = function(self)
        Prop.OnCreate(self)
        --CreateAttachedEmitter(self, -1, self.Army, '/effects/emitters/_test_20_gaseous_emit.bp')
    end,
}
TypeClass = ThermalVent01