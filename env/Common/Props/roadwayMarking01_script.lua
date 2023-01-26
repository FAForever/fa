--
-- RoadwayMarking01
--
local Prop = import("/lua/sim/prop.lua").Prop

RoadwayMarking01 = Class(Prop) {
    OnCreate = function(self)
        Prop.OnCreate(self)
        CreateEmitterAtBone(self, -2, -1, '/effects/emitters/light_red_blinking_03_emit.bp' )
    end,
}
TypeClass = RoadwayMarking01