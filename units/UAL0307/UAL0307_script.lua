-- File     :  /cdimage/units/UAL0307/UAL0307_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  Aeon Mobile Shield Generator Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------

local AShieldHoverLandUnit = import("/lua/aeonunits.lua").AShieldHoverLandUnit
local DefaultProjectileWeapon = import("/lua/sim/defaultweapons.lua").DefaultProjectileWeapon
local SlowHover = import("/lua/defaultunits.lua").SlowHoverLandUnit
local ShieldEffectsComponent = import("/lua/defaultcomponents.lua").ShieldEffectsComponent
local TargetPointerComponent = import("/lua/sim/units/components/TargetPointerComponent.lua").TargetPointerComponent

---@class UAL0307 : AShieldHoverLandUnit, ShieldEffectsComponent, TargetPointerComponent
UAL0307 = ClassUnit(AShieldHoverLandUnit, ShieldEffectsComponent, TargetPointerComponent) {
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

        self:InitializeTargetPointer()
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

    OnLayerChange = function(self, new, old)
        local physics = (self.Blueprint or self:GetBlueprint()).Physics
        if physics.WaterSpeedMultiplier then
            SlowHover.OnLayerChange(self, new, old)
        else
            AShieldHoverLandUnit.OnLayerChange(self, new, old)
        end

        self:OverrideTargetPointerLayerCaps()
    end,
}
TypeClass = UAL0307