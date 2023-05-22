----****************************************************************************
----**
----**  File     :  /cdimage/units/URB4206/URB4206_script.lua
----**  Author(s):  David Tomandl, Greg Kohne
----**
----**  Summary  :  Cybran Shield Generator lvl 4 Script
----**
----**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local CShieldStructureUnit = import("/lua/cybranunits.lua").CShieldStructureUnit
local ShieldEffectsComponent = import("/lua/defaultcomponents.lua").ShieldEffectsComponent

---@class URB4206 : CShieldStructureUnit, ShieldEffectsComponent
---@field Rotator1? moho.RotateManipulator
URB4206 = ClassUnit(CShieldStructureUnit,ShieldEffectsComponent) {
    ShieldEffects = { 
        '/effects/emitters/cybran_shield_04_generator_01_emit.bp',
        '/effects/emitters/cybran_shield_04_generator_02_emit.bp',
        '/effects/emitters/cybran_shield_04_generator_03_emit.bp',
    },

    ShieldEffectsBone = 'Shaft',

    ---@param self URB4206
    OnCreate = function(self)
        CShieldStructureUnit.OnCreate(self)
        ShieldEffectsComponent.OnCreate(self)
    end,

    ---@param self URB4206
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        CShieldStructureUnit.OnStopBeingBuilt(self, builder, layer)
        self.Rotator1 = CreateRotator(self, 'Shaft', 'z', nil, 30, 5, 30)
        self.Trash:Add(self.Rotator1)
    end,

    ---@param self URB4206
    OnShieldEnabled = function(self)
        CShieldStructureUnit.OnShieldEnabled(self)
        ShieldEffectsComponent.OnShieldEnabled(self)

        if self.Rotator1 then
            self.Rotator1:SetTargetSpeed(10)
        end
    end,

    ---@param self URB4206
    OnShieldDisabled = function(self)
        CShieldStructureUnit.OnShieldDisabled(self)
        ShieldEffectsComponent.OnShieldDisabled(self)
        self.Rotator1:SetTargetSpeed(0)            
    end,
}

TypeClass = URB4206
