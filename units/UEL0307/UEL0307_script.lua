--****************************************************************************
--**
--**  File     :  /cdimage/units/UEL0307/UEL0307_script.lua
--**  Author(s):  David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Mobile Shield Generator Script
--**
--**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

-- Automatically upvalued moho functions for performance
local CAnimationManipulatorMethods = _G.moho.AnimationManipulator
local CAnimationManipulatorMethodsPlayAnim = CAnimationManipulatorMethods.PlayAnim
local CAnimationManipulatorMethodsSetRate = CAnimationManipulatorMethods.SetRate

local CRotateManipulatorMethods = _G.moho.RotateManipulator
local CRotateManipulatorMethodsSetAccel = CRotateManipulatorMethods.SetAccel
local CRotateManipulatorMethodsSetTargetSpeed = CRotateManipulatorMethods.SetTargetSpeed

local UnitWeaponMethods = _G.moho.weapon_methods
local UnitWeaponMethodsSetFireTargetLayerCaps = UnitWeaponMethods.SetFireTargetLayerCaps
-- End of automatically upvalued moho functions

local TShieldLandUnit = import('/lua/terranunits.lua').TShieldLandUnit
--import a default weapon so our pointer doesnt explode
local DefaultProjectileWeapon = import('/lua/sim/defaultweapons.lua').DefaultProjectileWeapon

UEL0307 = Class(TShieldLandUnit)({

    Weapons = {
        TargetPointer = Class(DefaultProjectileWeapon)({}),
    },

    ShieldEffects = {
        '/effects/emitters/terran_shield_generator_mobile_01_emit.bp',
        '/effects/emitters/terran_shield_generator_mobile_02_emit.bp',
    },

    OnStopBeingBuilt = function(self, builder, layer)
        TShieldLandUnit.OnStopBeingBuilt(self, builder, layer)
        self.ShieldEffectsBag = {


            --save the pointer weapon for later - this is extra clever since the pointer weapon has to be first!
        }
        self.TargetPointer = self:GetWeapon(1)
        --we save this to the unit table so dont have to call every time.
        self.TargetLayerCaps = self:GetBlueprint().Weapon[1].FireTargetLayerCapsTable
        --a flag to let our thread know whether we should turn on our pointer.
        self.PointerEnabled = true
    end,

    OnShieldEnabled = function(self)
        TShieldLandUnit.OnShieldEnabled(self)
        KillThread(self.DestroyManipulatorsThread)
        if not self.RotatorManipulator then
            self.RotatorManipulator = CreateRotator(self, 'Spinner', 'y')
            self.Trash:Add(self.RotatorManipulator)
        end
        CRotateManipulatorMethodsSetAccel(self.RotatorManipulator, 5)
        CRotateManipulatorMethodsSetTargetSpeed(self.RotatorManipulator, 30)
        if not self.AnimationManipulator then
            local myBlueprint = self:GetBlueprint()
            --LOG( 'it is ', repr(myBlueprint.Display.AnimationOpen) )
            self.AnimationManipulator = CreateAnimator(self)
            CAnimationManipulatorMethodsPlayAnim(self.AnimationManipulator, myBlueprint.Display.AnimationOpen)
            self.Trash:Add(self.AnimationManipulator)
        end
        CAnimationManipulatorMethodsSetRate(self.AnimationManipulator, 1)

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
        TShieldLandUnit.OnShieldDisabled(self)
        KillThread(self.DestroyManipulatorsThread)
        self.DestroyManipulatorsThread = self:ForkThread(self.DestroyManipulators)

        if self.ShieldEffectsBag then
            for k, v in self.ShieldEffectsBag do
                v:Destroy()
            end
            self.ShieldEffectsBag = {}
        end
    end,

    DestroyManipulators = function(self)
        if self.RotatorManipulator then
            CRotateManipulatorMethodsSetAccel(self.RotatorManipulator, 10)
            CRotateManipulatorMethodsSetTargetSpeed(self.RotatorManipulator, 0)
            -- Unless it goes smoothly back to its original position,
            -- it will snap there when the manipulator is destroyed.
            -- So for now, we'll just keep it on.
            --WaitFor( self.RotatorManipulator )
            --self.RotatorManipulator:Destroy()
            --self.RotatorManipulator = nil
        end
        if self.AnimationManipulator then
            CAnimationManipulatorMethodsSetRate(self.AnimationManipulator, -1)
            WaitFor(self.AnimationManipulator)
            self.AnimationManipulator:Destroy()
            self.AnimationManipulator = nil
        end
    end,

    DisablePointer = function(self)
        --this disables the stop feature - note that its reset on layer change!
        UnitWeaponMethodsSetFireTargetLayerCaps(self.TargetPointer, 'None')
        self.PointerRestartThread = self:ForkThread(self.PointerRestart)
    end,

    PointerRestart = function(self)
        --sadly i couldnt find some way of doing this without a thread. dont know where to check if its still assisting other than this.
        while not self.PointerEnabled do

            WaitSeconds(1)

            -- break if we're a gooner
            if IsDestroyed(self) or IsDestroyed(self.TargetPointer) then
                break
            end

            -- if not gooner, check whether we need to enable our weapon to keep reasonable distance
            if not self:GetGuardedUnit() then
                self.PointerEnabled = true
                --this resets the stop feature - note that its reset on layer change!
                UnitWeaponMethodsSetFireTargetLayerCaps(self.TargetPointer, self.TargetLayerCaps[self.Layer])
            end
        end
    end,

    OnLayerChange = function(self, new, old)
        TShieldLandUnit.OnLayerChange(self, new, old)

        if self.PointerEnabled == false then
            --since its reset on layer change we need to do this. unfortunate.
            UnitWeaponMethodsSetFireTargetLayerCaps(self.TargetPointer, 'None')
        end
    end,
})

TypeClass = UEL0307