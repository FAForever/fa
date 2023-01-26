--
-- LavaSteam04
--
local Prop = import("/lua/sim/prop.lua").Prop

LavaSteam04 = Class(Prop) {
    OnCreate = function(self)
        Prop.OnCreate(self)
        CreateEmitterAtBone(self, -2, -1, '/effects/emitters/lava_smoke_02_emit.bp')
    end,
}
TypeClass = LavaSteam04