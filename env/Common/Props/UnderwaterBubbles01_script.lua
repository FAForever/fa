--
-- MudPot 01
--
local Prop = import("/lua/sim/prop.lua").Prop

MudPot01 = Class(Prop) {
    OnCreate = function(self)
        Prop.OnCreate(self)
        CreateEmitterAtBone(self, -2, -1, '/effects/emitters/underwater_vent_bubbles_01_emit.bp')
    end,
}
TypeClass = MudPot01