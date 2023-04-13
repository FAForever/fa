-- File     :  /cdimage/units/URL0306/URL0306_script.lua
-- Author(s):  Jessica St. Croix
-- Summary  :  Cybran Mobile Radar Jammer Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local CLandUnit = import("/lua/cybranunits.lua").CLandUnit
local EffectUtil = import("/lua/effectutilities.lua")
local DefaultProjectileWeapon = import("/lua/sim/defaultweapons.lua").DefaultProjectileWeapon

---@class URL0306 : CLandUnit
URL0306 = ClassUnit(CLandUnit) {
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

        self.TargetPointer = self:GetWeapon(1)
        self.TargetLayerCaps = self.Blueprint.Weapon[1].FireTargetLayerCapsTable
        self.PointerEnabled = true
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

    DisablePointer = function(self)
        self.TargetPointer:SetFireTargetLayerCaps('None') --this disables the stop feature - note that its reset on layer change!
        local thread = ForkThread(self.PointerRestart,self)
        self.Trash:Add(thread)
        self.PointerRestartThread = thread
    end,

    PointerRestart = function(self)
        --sadly i couldnt find some way of doing this without a thread. dont know where to check if its still assisting other than this.
        while self.PointerEnabled == false do
            WaitTicks(11)
            if not self:GetGuardedUnit() then
                self.PointerEnabled = true
                self.TargetPointer:SetFireTargetLayerCaps(self.TargetLayerCaps[self.Layer]) --this resets the stop feature - note that its reset on layer change!
            end
        end
    end,

    OnLayerChange = function(self, new, old)
        CLandUnit.OnLayerChange(self, new, old)

        if self.PointerEnabled == false then
            self.TargetPointer:SetFireTargetLayerCaps('None') --since its reset on layer change we need to do this. unfortunate.
        end
    end,
}

TypeClass = URL0306
