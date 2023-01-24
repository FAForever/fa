-- File     :  /units/XSB4202/XSB4202_script.lua
-- Summary  :  Seraphim Shield Generator Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local SShieldStructureUnit = import("/lua/seraphimunits.lua").SShieldStructureUnit
local ShieldEffectsComponent = import("/lua/defaultcomponents.lua").ShieldEffectsComponent

---@class XSB4202 : SShieldStructureUnit
XSB4202 = ClassUnit(SShieldStructureUnit, ShieldEffectsComponent) {

    ShieldEffectsScale = 0.75,
    ShieldEffects = {
        '/effects/emitters/seraphim_shield_generator_t2_01_emit.bp',
        '/effects/emitters/seraphim_shield_generator_t3_03_emit.bp',
        '/effects/emitters/seraphim_shield_generator_t2_03_emit.bp',
    },

    OnCreate = function(self)
        SShieldStructureUnit.OnCreate(self)
        ShieldEffectsComponent.OnCreate(self)
    end,

    OnShieldEnabled = function(self)
        SShieldStructureUnit.OnShieldEnabled(self)
        ShieldEffectsComponent.OnShieldEnabled(self)
    end,

    OnShieldDisabled = function(self)
        SShieldStructureUnit.OnShieldDisabled(self)
        ShieldEffectsComponent.OnShieldDisabled(self)
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        SShieldStructureUnit.OnKilled(self, instigator, type, overkillRatio)
    end,
}
TypeClass = XSB4202