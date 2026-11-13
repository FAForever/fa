-- File     :  /cdimage/units/URL0306/URL0306_script.lua
-- Author(s):  Jessica St. Croix
-- Summary  :  Cybran Mobile Radar Jammer Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local CLandUnit = import("/lua/cybranunits.lua").CLandUnit
local EffectUtil = import("/lua/effectutilities.lua")
local DefaultProjectileWeapon = import("/lua/sim/defaultweapons.lua").DefaultProjectileWeapon
local TargetPointerComponent = import("/lua/sim/units/components/TargetPointerComponent.lua").TargetPointerComponent

---@class URL0306 : CLandUnit, TargetPointerComponent
URL0306 = ClassUnit(CLandUnit, TargetPointerComponent) {
    Weapons = {
        TargetPointer = ClassWeapon(DefaultProjectileWeapon) {},
    },
    IntelEffects = {
        {
            Bones = {
                'AttachPoint',
            },
            Offset = {
                0,
                0.3,
                0,
            },
            Scale = 0.2,
            Type = 'Jammer01',
        },
    },

    OnStopBeingBuilt = function(self, builder, layer)
        CLandUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()

        self:InitializeTargetPointer()
    end,

    ---@param self RadarJammerUnit
    OnIntelEnabled = function(self)
        CLandUnit.OnIntelEnabled(self)
        if self.IntelEffects and not self.IntelFxOn then
            self.IntelEffectsBag = {}
            self:CreateTerrainTypeEffects(self.IntelEffects, 'FXIdle', self.Layer, nil, self.IntelEffectsBag)
            self.IntelFxOn = true
        end
    end,

    ---@param self RadarJammerUnit
    OnIntelDisabled = function(self)
        CLandUnit.OnIntelDisabled(self)
        EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
        self.IntelFxOn = false
    end,

    OnLayerChange = function(self, new, old)
        CLandUnit.OnLayerChange(self, new, old)

        self:OverrideTargetPointerLayerCaps()
    end,
}

TypeClass = URL0306
