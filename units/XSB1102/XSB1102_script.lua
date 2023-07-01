-- File     :  /cdimage/units/XSB1102/XSB1102_script.lua
-- Author(s):  Dru Staltman, Greg Kohne
-- Summary  :  Seraphim Hydrocarbon Power Plant Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local SEnergyCreationUnit = import("/lua/seraphimunits.lua").SEnergyCreationUnit
---@class XSB1102 : SEnergyCreationUnit
XSB1102 = ClassUnit(SEnergyCreationUnit) {
    AirEffects = {
        '/effects/emitters/hydrocarbon_heatshimmer_01_emit.bp'
    },
    AirEffectsBones = {'Exhaust01','Exhaust02','Exhaust03'},
    WaterEffects = {'/effects/emitters/underwater_idle_bubbles_01_emit.bp',},
    WaterEffectsBones = {'Exhaust01'},

    OnStopBeingBuilt = function(self,builder,layer)
        SEnergyCreationUnit.OnStopBeingBuilt(self,builder,layer)

        local effects = {}
        local bones = {}
        local scale = 0.75

        if self.Layer == 'Land' then
            effects = self.AirEffects
            bones = self.AirEffectsBones
        elseif self.Layer == 'Seabed' then
            effects = self.WaterEffects
            bones = self.WaterEffectsBones
            scale = 3
        end

        for keys, values in effects do
            for keysbones, valuesbones in bones do
                self.Trash:Add(CreateAttachedEmitter(self, valuesbones, self.Army, values):ScaleEmitter(scale):OffsetEmitter(0, -0.2, 1))
            end
        end

        local bp = self.Blueprint.Display
        self.LoopAnimation = CreateAnimator(self)
        self.LoopAnimation:PlayAnim(bp.LoopingAnimation, true)
        self.LoopAnimation:SetRate(0.5)
        self.Trash:Add(self.LoopAnimation)
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        SEnergyCreationUnit.OnKilled(self, instigator, type, overkillRatio)
        if self.LoopAnimation then
            self.LoopAnimation:SetRate(0.0)
        end
    end,
}

TypeClass = XSB1102
