-- File     :  /cdimage/units/UAL0307/UAL0307_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  Aeon Mobile Shield Generator Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------

local AShieldHoverLandUnit = import("/lua/aeonunits.lua").AShieldHoverLandUnit
local DefaultProjectileWeapon = import("/lua/sim/defaultweapons.lua").DefaultProjectileWeapon
local ShieldEffectsComponent = import("/lua/defaultcomponents.lua").ShieldEffectsComponent

---@class UAL0307 : AShieldHoverLandUnit
UAL0307 = ClassUnit(AShieldHoverLandUnit, ShieldEffectsComponent) {
    Weapons = {
        TargetPointer = ClassWeapon(DefaultProjectileWeapon) {},
    },
    ShieldEffects = {
        '/effects/emitters/aeon_shield_generator_mobile_01_emit.bp',
    },

    OnCreate = function(self)
        AShieldHoverLandUnit.OnCreate(self)
        ShieldEffectsComponent.OnCreate(self)
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        AShieldHoverLandUnit.OnStopBeingBuilt(self, builder, layer)
        self.TargetPointer = self:GetWeapon(1) --save the pointer weapon for later - this is extra clever since the pointer weapon has to be first!
        self.TargetLayerCaps = self.Blueprint.Weapon[1].FireTargetLayerCapsTable --we save this to the unit table so dont have to call every time.
        self.PointerEnabled = true --a flag to let our thread know whether we should turn on our pointer.
    end,

    OnShieldEnabled = function(self)
        AShieldHoverLandUnit.OnShieldEnabled(self)
        ShieldEffectsComponent.OnShieldEnabled(self)
        if not self.Animator then
            self.Animator = CreateAnimator(self)
            self.Trash:Add(self.Animator)
            self.Animator:PlayAnim(self.Blueprint.Display.AnimationOpen)
        end
        self.Animator:SetRate(1)
    end,

    OnShieldDisabled = function(self)
        AShieldHoverLandUnit.OnShieldDisabled(self)
        ShieldEffectsComponent.OnShieldDisabled(self)
        if self.Animator then
            self.Animator:SetRate(-1)
        end
    end,

    DisablePointer = function(self)
        self.TargetPointer:SetFireTargetLayerCaps('None') --this disables the stop feature - note that its reset on layer change!
        self.PointerRestartThread = self.Trash:Add(ForkThread(self.PointerRestart,self))
    end,

    PointerRestart = function(self)
        --sadly i couldnt find some way of doing this without a thread. dont know where to check if its still assisting other than this.
        while self.PointerEnabled == false do
            WaitTicks(11)
            if IsDestroyed(self) or IsDestroyed(self.TargetPointer) then
                break
            end

            if not self:GetGuardedUnit() then
                self.PointerEnabled = true
                self.TargetPointer:SetFireTargetLayerCaps(self.TargetLayerCaps[self.Layer]) --this resets the stop feature - note that its reset on layer change!
            end
        end
    end,

    OnLayerChange = function(self, new, old)
        AShieldHoverLandUnit.OnLayerChange(self, new, old)

        if not IsDestroyed(self.TargetPointer) then
            if self.PointerEnabled == false then
                -- since its reset on layer change we need to do this, unfortunate
                self.TargetPointer:SetFireTargetLayerCaps('None')
            end
        end
    end,
}
TypeClass = UAL0307