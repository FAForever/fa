-- File     :  /units/XSL0307/XSL0307_script.lua
-- Summary  :  Seraphim Mobile Shield Generator Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local SShieldHoverLandUnit = import("/lua/seraphimunits.lua").SShieldHoverLandUnit
local DefaultProjectileWeapon = import("/lua/sim/defaultweapons.lua").DefaultProjectileWeapon

---@class XSL0307 : SShieldHoverLandUnit
XSL0307 = ClassUnit(SShieldHoverLandUnit) {

    Weapons = {
        TargetPointer = ClassWeapon(DefaultProjectileWeapon) {},
    },

    ShieldEffects = {
        '/effects/emitters/aeon_shield_generator_mobile_01_emit.bp',
    },

    OnStopBeingBuilt = function(self, builder, layer)
        SShieldHoverLandUnit.OnStopBeingBuilt(self, builder, layer)
        self.ShieldEffectsBag = {}

        self.TargetPointer = self:GetWeapon(1)
        self.TargetLayerCaps = self.Blueprint.Weapon[1].FireTargetLayerCapsTable
        self.PointerEnabled = true --a flag to let our thread know whether we should turn on our pointer.
    end,

    OnShieldEnabled = function(self)
        SShieldHoverLandUnit.OnShieldEnabled(self)

        if self.ShieldEffectsBag then
            for k, v in self.ShieldEffectsBag do
                v:Destroy()
            end
            self.ShieldEffectsBag = {}
        end
        for k, v in self.ShieldEffects do
            table.insert(self.ShieldEffectsBag, CreateAttachedEmitter(self, 0, self.Army, v))
        end
    end,

    OnShieldDisabled = function(self)
        SShieldHoverLandUnit.OnShieldDisabled(self)

        if self.ShieldEffectsBag then
            for k, v in self.ShieldEffectsBag do
                v:Destroy()
            end
            self.ShieldEffectsBag = {}
        end
    end,

    DisablePointer = function(self)
        self.TargetPointer:SetFireTargetLayerCaps('None')
        self.PointerRestartThread = self.Trash:Add(ForkThread(self.PointerRestart,self))
    end,

    PointerRestart = function(self)
        while self.PointerEnabled == false do
            WaitTicks(11)
            if IsDestroyed(self) or IsDestroyed(self.TargetPointer) then
                break
            end
            if not self:GetGuardedUnit() then
                self.PointerEnabled = true
                self.TargetPointer:SetFireTargetLayerCaps(self.TargetLayerCaps[self.Layer])
            end
        end
    end,

    OnLayerChange = function(self, new, old)
        SShieldHoverLandUnit.OnLayerChange(self, new, old)
        if not IsDestroyed(self.TargetPointer) then
            if self.PointerEnabled == false then
                self.TargetPointer:SetFireTargetLayerCaps('None')
            end
        end
    end,
}

TypeClass = XSL0307
