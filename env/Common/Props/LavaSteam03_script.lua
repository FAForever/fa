--
-- LavaSteam03
--
local Prop = import("/lua/sim/prop.lua").Prop

LavaSteam03 = Class(Prop) {
    OnCreate = function(self)
        Prop.OnCreate(self)
        CreateEmitterAtBone(self, -2, -1, '/effects/emitters/lava_smoke_01_emit.bp')
    end,
}
TypeClass = LavaSteam03