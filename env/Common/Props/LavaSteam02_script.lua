--
-- LavaSteam02
--
local Prop = import("/lua/sim/prop.lua").Prop

LavaSteam02 = Class(Prop) {
    OnCreate = function(self)
        Prop.OnCreate(self)
        CreateEmitterAtBone(self, -2, -1, '/effects/emitters/water_heat_ambient_03_emit.bp')
    end,
}
TypeClass = LavaSteam02