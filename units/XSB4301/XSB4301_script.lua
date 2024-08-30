----****************************************************************************
----**
----**  File     :  /units/XSB4301/XSB4301_script.lua
----**
----**  Summary  :  Seraphim Heavy Shield Generator Script
----**
----**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local SShieldStructureUnit = import("/lua/seraphimunits.lua").SShieldStructureUnit
local ShieldEffectsComponent = import("/lua/defaultcomponents.lua").ShieldEffectsComponent

---@class XSB4301 : SShieldStructureUnit
XSB4301 = ClassUnit(SShieldStructureUnit, ShieldEffectsComponent) {
    ShieldEffects = {
        --'/effects/emitters/seraphim_shield_generator_t3_01_emit.bp',
        '/effects/emitters/seraphim_shield_generator_t3_02_emit.bp',
        '/effects/emitters/seraphim_shield_generator_t3_03_emit.bp', 
        '/effects/emitters/seraphim_shield_generator_t3_04_emit.bp',        
        --'/effects/emitters/seraphim_shield_generator_t3_05_emit.bp',
    },

    ---@param self XSB4301
    OnCreate = function(self) -- Are these missng on purpose?
        SShieldStructureUnit.OnCreate(self)
        ShieldEffectsComponent.OnCreate(self)
    end,

    ---@param self XSB4301
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        SShieldStructureUnit.OnStopBeingBuilt(self, builder, layer)
    end,

    ---@param self XSB4301
    OnShieldEnabled = function(self)
        SShieldStructureUnit.OnShieldEnabled(self)
        ShieldEffectsComponent.OnShieldEnabled(self)        
    end,

    ---@param self XSB4301
    OnShieldDisabled = function(self)
        SShieldStructureUnit.OnShieldDisabled(self)
        ShieldEffectsComponent.OnShieldDisabled(self)        
    end,

    ---@param self XSB4301
    OnKilled = function(self, instigator, type, overkillRatio)
        SShieldStructureUnit.OnKilled(self, instigator, type, overkillRatio)
        if self.ShieldEffectsBag then
            for k,v in self.ShieldEffectsBag do
                v:Destroy()
            end
        end
    end,
}

TypeClass = XSB4301
