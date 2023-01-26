--
-- WaterSurfaceMist01
--
local Prop = import("/lua/sim/prop.lua").Prop

WaterSurfaceMist01 = Class(Prop) {
    OnCreate = function(self)
        Prop.OnCreate(self)
        CreateEmitterAtBone(self, -2, -1, '/effects/emitters/water_heat_ambient_01_emit.bp')
    end,
}
TypeClass = WaterSurfaceMist01