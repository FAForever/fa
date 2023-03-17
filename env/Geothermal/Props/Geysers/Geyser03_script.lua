--
-- Geyser 03
--
local Prop = import("/lua/sim/prop.lua").Prop

Geyser03 = Class(Prop) {
    OnCreate = function(self)
        Prop.OnCreate(self)
        CreateEmitterAtBone(self, -2, -1, '/effects/emitters/geyser_01_emit.bp')
        CreateEmitterAtBone(self, -2, -1, '/effects/emitters/geyser_smoke_01_emit.bp')
    end,
}
TypeClass = Geyser03