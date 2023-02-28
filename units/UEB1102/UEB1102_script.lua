----------------------------------------------------------------------------
--
--  File     :  /cdimage/units/UEB1102/UEB1102_script.lua
--  Author(s):  Jessica St. Croix
--
--  Summary  :  UEF Hydrocarbon Power Plant Script
--
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------

local TEnergyCreationUnit = import("/lua/terranunits.lua").TEnergyCreationUnit

---@class UEB1102 : TEnergyCreationUnit
UEB1102 = ClassUnit(TEnergyCreationUnit) {
    AirEffects = {'/effects/emitters/hydrocarbon_smoke_01_emit.bp',},
    AirEffectsBones = {'Exhaust01'},
    WaterEffects = {'/effects/emitters/underwater_idle_bubbles_01_emit.bp',},
    WaterEffectsBones = {'Exhaust01'},

    OnStopBeingBuilt = function(self,builder,layer)
        TEnergyCreationUnit.OnStopBeingBuilt(self,builder,layer)

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
TypeClass = UEB1102
