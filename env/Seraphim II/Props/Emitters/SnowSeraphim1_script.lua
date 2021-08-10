--
-- LavaSteam01
--

local Prop = import('/lua/sim/Prop.lua').Prop
BlowingSnow01 = Class(Prop) {

    OnCreate = function(self)
        Prop.OnCreate(self)
        CreateEmitterAtBone(self, -2, -1, '/effects/emitters/weather_snowseraphim_01_emit.bp')
    end,

    OnDestroy = function()
    end,
}

TypeClass = BlowingSnow01
