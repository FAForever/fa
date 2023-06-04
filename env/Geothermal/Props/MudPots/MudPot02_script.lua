--
-- MudPot 02
--
local Prop = import("/lua/sim/prop.lua").Prop

MudPot02 = Class(Prop) {
    OnCreate = function(self)
        Prop.OnCreate(self)
        CreateEmitterAtBone(self, -2, -1, '/effects/emitters/mudpot_02_emit.bp'):OffsetEmitter( 0.2, 0, 0.7 )
    end,
}
TypeClass = MudPot02