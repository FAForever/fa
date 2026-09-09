-- File     :  /units/XSL0307/XSL0307_script.lua
-- Summary  :  Seraphim Mobile Shield Generator Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local SShieldHoverLandUnit = import("/lua/seraphimunits.lua").SShieldHoverLandUnit
local DefaultProjectileWeapon = import("/lua/sim/defaultweapons.lua").DefaultProjectileWeapon --import a default weapon so our pointer doesnt explode
local SlowHover = import("/lua/defaultunits.lua").SlowHoverLandUnit
local ShieldEffectsComponent = import("/lua/defaultcomponents.lua").ShieldEffectsComponent
local TargetPointerComponent = import("/lua/sim/units/components/TargetPointerComponent.lua").TargetPointerComponent

---@class XSL0307 : SShieldHoverLandUnit, ShieldEffectsComponent, TargetPointerComponent
XSL0307 = ClassUnit(SShieldHoverLandUnit, ShieldEffectsComponent, TargetPointerComponent) {

    Weapons = {
        TargetPointer = ClassWeapon(DefaultProjectileWeapon) {},
    },

    ShieldEffects = {
        '/effects/emitters/aeon_shield_generator_mobile_01_emit.bp',
    },
    ---@param self XSL0307
    OnCreate = function(self) -- Are these missng on purpose?
        SShieldHoverLandUnit.OnCreate(self)
        ShieldEffectsComponent.OnCreate(self)
    end,

    ---@param self XSL0307
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        SShieldHoverLandUnit.OnStopBeingBuilt(self, builder, layer)

        self:InitializeTargetPointer()
    end,

    ---@param self XSL0307
    OnShieldEnabled = function(self)
        SShieldHoverLandUnit.OnShieldEnabled(self)
        ShieldEffectsComponent.OnShieldEnabled(self)
    end,

    ---@param self XSL0307
    OnShieldDisabled = function(self)
        SShieldHoverLandUnit.OnShieldDisabled(self)
        ShieldEffectsComponent.OnShieldDisabled(self)
    end,

    ---@param self XSL0307
    OnLayerChange = function(self, new, old)
        local physics = (self.Blueprint or self:GetBlueprint()).Physics
        if physics.WaterSpeedMultiplier then
            SlowHover.OnLayerChange(self, new, old)
        else
            SShieldHoverLandUnit.OnLayerChange(self, new, old)
        end

        self:OverrideTargetPointerLayerCaps()
    end,
}

TypeClass = XSL0307
