-- File     :  /cdimage/units/UAB1102/UAB1102_script.lua
-- Author(s):  Jessica St. Croix, John Comes
-- Summary  :  Aeon Hydrocarbon Power Plant Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local AEnergyCreationUnit = import("/lua/aeonunits.lua").AEnergyCreationUnit

-- upvalue for perfomance
local CreateAttachedEmitter = CreateAttachedEmitter
local TrashBagAdd = TrashBag.Add

---@class UAB1102 : AEnergyCreationUnit
UAB1102 = ClassUnit(AEnergyCreationUnit) {
    AirEffects = {'/effects/emitters/hydrocarbon_smoke_01_emit.bp',},
    AirEffectsBones = {'Extension02'},
    WaterEffects = {'/effects/emitters/underwater_idle_bubbles_01_emit.bp',},
    WaterEffectsBones = {'Extension02'},

    OnStopBeingBuilt = function(self, builder, layer)
        AEnergyCreationUnit.OnStopBeingBuilt(self, builder, layer)
        local effects = {}
        local bones = {}
        local scale = 0.75
        local trash = self.Trash
        local army = self.Army

        if self:GetCurrentLayer() == 'Land' then
            effects = self.AirEffects
            bones = self.AirEffectsBones
        elseif self:GetCurrentLayer() == 'Seabed' then
            effects = self.WaterEffects
            bones = self.WaterEffectsBones
            scale = 3
        end
        for keys, values in effects do
            for keysbones, valuesbones in bones do
                TrashBagAdd(trash, CreateAttachedEmitter(self, valuesbones, army, values):ScaleEmitter(scale):OffsetEmitter(0, -0.2, 1))
            end
        end
    end,
}

TypeClass = UAB1102