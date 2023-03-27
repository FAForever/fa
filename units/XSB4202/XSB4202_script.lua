----****************************************************************************
----**
----**  File     :  /units/XSB4202/XSB4202_script.lua
----**
----**  Summary  :  Seraphim Shield Generator Script
----**
----**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local SShieldStructureUnit = import("/lua/seraphimunits.lua").SShieldStructureUnit
local ShieldEffectsComponent = import("/lua/defaultcomponents.lua").ShieldEffectsComponent

---@class XSB4202 : SShieldStructureUnit, ShieldEffectsComponent
XSB4202 = ClassUnit(SShieldStructureUnit, ShieldEffectsComponent) {
    ShieldEffects = {
        '/effects/emitters/seraphim_shield_generator_t2_01_emit.bp',
        '/effects/emitters/seraphim_shield_generator_t3_03_emit.bp',
        '/effects/emitters/seraphim_shield_generator_t2_03_emit.bp',
    },

    ShieldEffectsScale = 0.75,

    ---@param self XSB4202
    OnCreate = function(self) -- Are these missng on purpose?
        SShieldStructureUnit.OnCreate(self)
        ShieldEffectsComponent.OnCreate(self)
    end,

    ---@param self XSB4202
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        SShieldStructureUnit.OnStopBeingBuilt(self, builder, layer)
    end,

    ---@param self XSB4202
    OnShieldEnabled = function(self)
        SShieldStructureUnit.OnShieldEnabled(self)
        ShieldEffectsComponent.OnShieldEnabled(self)        
    end,

    ---@param self XSB4202
    OnShieldDisabled = function(self)
        SShieldStructureUnit.OnShieldDisabled(self)
        ShieldEffectsComponent.OnShieldDisabled(self)                
    end,

    ---@param self XSB4202
    OnKilled = function(self, instigator, type, overkillRatio)
        SShieldStructureUnit.OnKilled(self, instigator, type, overkillRatio)
        if self.ShieldEffectsBag then
            ShieldEffectsComponent.OnShieldDisabled(self)
        end
    end,
}

TypeClass = XSB4202
