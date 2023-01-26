--
-- RoadwayMarking01
--
RoadwayMarking01 = Class(import("/lua/sim/prop.lua").Prop) {

    OnCreate = function(self)
        CreateEmitterAtBone(self, 0, -3, '/effects/emitters/blue_lense_blinking_emit.bp' )
    end,

    OnDestroy = function()
    end,
}

TypeClass = RoadwayMarking01
