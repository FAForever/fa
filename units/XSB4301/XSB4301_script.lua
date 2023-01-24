-- File     :  /units/XSB4301/XSB4301_script.lua
-- Summary  :  Seraphim Heavy Shield Generator Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local SShieldStructureUnit = import("/lua/seraphimunits.lua").SShieldStructureUnit
local ShieldEffectsComponent = import("/lua/defaultcomponents.lua").ShieldEffectsComponent

---@class XSB4301 : SShieldStructureUnit
XSB4301 = ClassUnit(SShieldStructureUnit, ShieldEffectsComponent) {

    ShieldEffects = {
        '/effects/emitters/seraphim_shield_generator_t3_02_emit.bp',
        '/effects/emitters/seraphim_shield_generator_t3_03_emit.bp', 
        '/effects/emitters/seraphim_shield_generator_t3_04_emit.bp',        
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
        if self.ShieldEffctsBag then
            for k,v in self.ShieldEffectsBag do
                v:Destroy()
            end
        end
    end,
}

TypeClass = XSB4301
