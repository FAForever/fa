-- File     :  /cdimage/units/UEL0307/UEL0307_script.lua
-- Author(s):  David Tomandl, Jessica St. Croix
-- Summary  :  UEF Mobile Shield Generator Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local TShieldLandUnit = import("/lua/terranunits.lua").TShieldLandUnit
local ShieldEffectsComponent = import("/lua/defaultcomponents.lua").ShieldEffectsComponent
local DefaultProjectileWeapon = import("/lua/sim/defaultweapons.lua").DefaultProjectileWeapon

---@class UEL0307 : TShieldLandUnit
UEL0307 = ClassUnit(TShieldLandUnit, ShieldEffectsComponent) {
    Weapons = {
        TargetPointer = ClassWeapon(DefaultProjectileWeapon) {},
    },

    ShieldEffectsBone = 0,
    ShieldEffects = {
        '/effects/emitters/terran_shield_generator_mobile_01_emit.bp',
        '/effects/emitters/terran_shield_generator_mobile_02_emit.bp',
    },

    OnCreate = function(self)
        TShieldLandUnit.OnCreate(self)
        ShieldEffectsComponent.OnCreate(self)
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        TShieldLandUnit.OnStopBeingBuilt(self, builder, layer)
        self.TargetPointer = self:GetWeapon(1) --save the pointer weapon for later - this is extra clever since the pointer weapon has to be first!
        self.TargetLayerCaps = self.Blueprint.Weapon[1].FireTargetLayerCapsTable --we save this to the unit table so dont have to call every time.
        self.PointerEnabled = true --a flag to let our thread know whether we should turn on our pointer.
    end,

    OnShieldEnabled = function(self)
        TShieldLandUnit.OnShieldEnabled(self)
        ShieldEffectsComponent.OnShieldEnabled(self)

        KillThread(self.DestroyManipulatorsThread)
        if not self.RotatorManipulator then
            self.RotatorManipulator = CreateRotator(self, 'Spinner', 'y')
            self.Trash:Add(self.RotatorManipulator)
        end
        self.RotatorManipulator:SetAccel(5)
        self.RotatorManipulator:SetTargetSpeed(30)
        if not self.AnimationManipulator then
            local myBlueprint = self.Blueprint
            self.AnimationManipulator = CreateAnimator(self)
            self.AnimationManipulator:PlayAnim(myBlueprint.Display.AnimationOpen)
            self.Trash:Add(self.AnimationManipulator)
        end
        self.AnimationManipulator:SetRate(1)
    end,

    OnShieldDisabled = function(self)
        TShieldLandUnit.OnShieldDisabled(self)
        ShieldEffectsComponent.OnShieldDisabled(self)
        KillThread(self.DestroyManipulatorsThread)

        local thread = ForkThread(self.DestroyManipulators, self)
        self.Trash:Add(thread)
        self.DestroyManipulatorsThread = thread
    end,

    DestroyManipulators = function(self)
        if self.RotatorManipulator then
            self.RotatorManipulator:SetAccel(10)
            self.RotatorManipulator:SetTargetSpeed(0)
            -- Unless it goes smoothly back to its original position,
            -- it will snap there when the manipulator is destroyed.
            -- So for now, we'll just keep it on.
            --WaitFor( self.RotatorManipulator )
            --self.RotatorManipulator:Destroy()
            --self.RotatorManipulator = nil
        end
        if self.AnimationManipulator then
            self.AnimationManipulator:SetRate(-1)
            WaitFor(self.AnimationManipulator)
            self.AnimationManipulator:Destroy()
            self.AnimationManipulator = nil
        end
    end,

    DisablePointer = function(self)
        self.TargetPointer:SetFireTargetLayerCaps('None') --this disables the stop feature - note that its reset on layer change!

        local thread = ForkThread(self.PointerRestart, self)
        self.Trash:Add(thread)
        self.PointerRestartThread = thread
    end,

    PointerRestart = function(self)
        while not self.PointerEnabled do
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
        TShieldLandUnit.OnLayerChange(self, new, old)
        if not IsDestroyed(self) then
            if self.PointerEnabled == false then
                self.TargetPointer:SetFireTargetLayerCaps('None')
            end
        end
    end,
}
TypeClass = UEL0307
