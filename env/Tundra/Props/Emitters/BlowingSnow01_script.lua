--
-- LavaSteam01
--
local Prop = import("/lua/sim/prop.lua").Prop

BlowingSnow01 = Class(Prop) {
    OnCreate = function(self)
        Prop.OnCreate(self)
        CreateEmitterAtBone(self, -2, -1, '/effects/emitters/weather_snow_drifting_01_emit.bp')
    end,
}
TypeClass = BlowingSnow01
