#
# LavaSteam01
#
local Prop = import('/lua/sim/Prop.lua').Prop

DesertBlowingSand01 = Class(Prop) {
    OnCreate = function(self)
        Prop.OnCreate(self)
        CreateEmitterAtBone(self, -2, -1, '/effects/emitters/weather_sand_01_emit.bp')
    end,
}
TypeClass = DesertBlowingSand01