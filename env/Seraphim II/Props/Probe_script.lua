--
-- RoadwayMarking01
--

local Prop = import('/lua/sim/Prop.lua').Prop
RoadwayMarking01 = Class(Prop) {

    OnCreate = function(self)
        Prop.OnCreate(self)
        CreateEmitterAtBone(self, 0, -3, '/effects/emitters/blue_lense_blinking_emit.bp' )
    end,

    OnDestroy = function()
    end,
}

TypeClass = RoadwayMarking01
