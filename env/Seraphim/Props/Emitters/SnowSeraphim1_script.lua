#
# LavaSteam01
#
BlowingSnow01 = Class(import('/lua/sim/Prop.lua').Prop) {

    OnCreate = function(self)
        CreateEmitterAtBone(self, -2, -1, '/effects/emitters/weather_snowseraphim_01_emit.bp')
    end,

    OnDestroy = function()
    end,
}

TypeClass = BlowingSnow01
