-- File     :  /cdimage/units/URB1102/URB1102_script.lua
-- Author(s):  John Comes, Dave Tomandl, Jessica St. Croix
-- Summary  :  Cybran Hydrocarbon Power Plant Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local CEnergyCreationUnit = import("/lua/cybranunits.lua").CEnergyCreationUnit

---@class URB1102 : CEnergyCreationUnit
URB1102 = ClassUnit(CEnergyCreationUnit) {
    AirEffects = { '/effects/emitters/hydrocarbon_smoke_01_emit.bp', },
    AirEffectsBones = { 'Exhaust01', 'Exhaust02', 'Exhaust03', 'Exhaust04', },
    WaterEffects = { '/effects/emitters/underwater_idle_bubbles_01_emit.bp', },
    WaterEffectsBones = { 'Exhaust01', 'Exhaust02', 'Exhaust03', 'Exhaust04', },

    OnStopBeingBuilt = function(self,builder,layer)
        CEnergyCreationUnit.OnStopBeingBuilt(self,builder,layer)

        local effects, bones, scale = nil, nil, 1
        if self.Layer == 'Land' then
            effects = self.AirEffects
            bones = self.AirEffectsBones
        elseif self.Layer == 'Seabed' then
            effects = self.WaterEffects
            bones = self.WaterEffectsBones
            scale = 3
        end

        if effects and bones then
            for _, effect in effects do
                for _, bone in bones do
                    self.Trash:Add(CreateAttachedEmitter(self, bone, self.Army, effect):ScaleEmitter(scale):OffsetEmitter(0,-.1,0))
                end
            end
        end
    end,
}
TypeClass = URB1102