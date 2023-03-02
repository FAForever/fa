--
-- MudPot 03
--
local Prop = import("/lua/sim/prop.lua").Prop

MudPot03 = Class(Prop) {
    OnCreate = function(self)
        Prop.OnCreate(self)
        CreateEmitterAtBone(self, -2, -1, '/effects/emitters/mudpot_02_emit.bp')
    end,
}
TypeClass = MudPot03