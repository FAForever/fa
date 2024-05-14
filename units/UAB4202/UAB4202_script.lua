----****************************************************************************
----**
----**  File     :  /cdimage/units/UAB4202/UAB4202_script.lua
----**  Author(s):  David Tomandl
----**
----**  Summary  :  Aeon Shield Generator Script
----**
----**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local AShieldStructureUnit = import("/lua/aeonunits.lua").AShieldStructureUnit
local ShieldEffectsComponent = import("/lua/defaultcomponents.lua").ShieldEffectsComponent

-- upvalue for perfomance
local TrashBagAdd = TrashBag.Add


---@class UAB4202 : AShieldStructureUnit
UAB4202 = ClassUnit(AShieldStructureUnit, ShieldEffectsComponent) {

    ShieldEffectsScale = 0.75,
    ShieldEffects = {
        '/effects/emitters/aeon_shield_generator_t2_01_emit.bp',
        '/effects/emitters/aeon_shield_generator_t2_02_emit.bp',
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

        local trash = self.Trash

        local orbManip1 = self.OrbManip1
        if not orbManip1 then
            orbManip1 = CreateRotator(self, 'Orb', '-x', nil, 0, 45, 45)
            TrashBagAdd(trash, orbManip1)
            self.OrbManip1 = orbManip1
        else
            orbManip1:SetSpinDown(false)
            orbManip1:SetTargetSpeed(45)
        end

        local orbManip2 = self.OrbManip2 
        if not orbManip2 then
            orbManip2 = CreateRotator(self, 'Orb', 'z', nil, 0, 45, 45)
            TrashBagAdd(trash, orbManip2)
            self.OrbManip2 = orbManip2
        else
            orbManip2:SetSpinDown(false)
            orbManip2:SetTargetSpeed(45)
        end
    end,

    OnShieldDisabled = function(self)
        AShieldStructureUnit.OnShieldDisabled(self)
        ShieldEffectsComponent.OnShieldDisabled(self)

        local orbManip1 = self.OrbManip1
        if orbManip1 then
            orbManip1:SetSpinDown(true)
        end

        local orbManip2 = self.OrbManip2
        if orbManip2 then
            orbManip2:SetSpinDown(true)
        end
    end,
}

TypeClass = UAB4202
