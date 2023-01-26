--
-- LavaSteam01
--
local Prop = import("/lua/sim/prop.lua").Prop

LavaSteam01 = Class(Prop) {
    OnCreate = function(self)
        Prop.OnCreate(self)
        CreateEmitterAtBone(self, -2, -1, '/effects/emitters/water_heat_ambient_02_emit.bp')
    end,
}
TypeClass = LavaSteam01