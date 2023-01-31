----****************************************************************************
----**
----**  File     :  /cdimage/units/UAB4301/UAB4301_script.lua
----**  Author(s):  David Tomandl, Jessica St. Croix
----**
----**  Summary  :  Aeon Heavy Shield Generator Script
----**
----**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local AShieldStructureUnit = import("/lua/aeonunits.lua").AShieldStructureUnit
local ShieldEffectsComponent = import("/lua/defaultcomponents.lua").ShieldEffectsComponent

---@class UAB4301 : AShieldStructureUnit
UAB4301 = ClassUnit(AShieldStructureUnit, ShieldEffectsComponent) {
    ShieldEffects = {
        '/effects/emitters/aeon_shield_generator_t2_01_emit.bp',
        '/effects/emitters/aeon_shield_generator_t3_02_emit.bp',
        '/effects/emitters/aeon_shield_generator_t3_03_emit.bp',
        '/effects/emitters/aeon_shield_generator_t3_04_emit.bp',
    },

    OnCreate = function(self)
        AShieldStructureUnit.OnCreate(self)
        ShieldEffectsComponent.OnCreate(self)
    end,

    OnShieldEnabled = function(self)
        AShieldStructureUnit.OnShieldEnabled(self)
        ShieldEffectsComponent.OnShieldEnabled(self)

        if not self.OrbManip1 then
            self.OrbManip1 = CreateRotator(self, 'Orb', 'y', nil, 0, 45, -45)
            self.Trash:Add(self.OrbManip1)
        end
        self.OrbManip1:SetTargetSpeed(-45)
        if not self.OrbManip2 then
            self.OrbManip2 = CreateRotator(self, 'Orb', 'z', nil, 0, 45, 45)
            self.Trash:Add(self.OrbManip2)
        end
        self.OrbManip2:SetTargetSpeed(45)
    end,

    OnShieldDisabled = function(self)
        AShieldStructureUnit.OnShieldDisabled(self)
        ShieldEffectsComponent.OnShieldDisabled(self)

        if self.OrbManip1 then
            self.OrbManip1:SetSpinDown(true)
            self.OrbManip1:SetTargetSpeed(0)
        end
        if self.OrbManip2 then
            self.OrbManip2:SetSpinDown(true)
            self.OrbManip2:SetTargetSpeed(0)
        end
    end,
    
    OnKilled = function(self, instigator, type, overkillRatio)
        AShieldStructureUnit.OnKilled(self, instigator, type, overkillRatio)
        if self.OrbManip1 then
            self.OrbManip1:Destroy()
            self.OrbManip1 = nil
        end
        if self.OrbManip2 then
            self.OrbManip2:Destroy()
            self.OrbManip2 = nil
        end
    end,
}

TypeClass = UAB4301
