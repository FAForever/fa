#
# DesertBlowingSand02
#
local Prop = import('/lua/sim/Prop.lua').Prop

DesertBlowingSand02 = Class(Prop) {
    OnCreate = function(self)
        Prop.OnCreate(self)
        CreateEmitterAtBone(self, -2, -1, '/effects/emitters/weather_sand_02_emit.bp')
    end,
}
TypeClass = DesertBlowingSand02