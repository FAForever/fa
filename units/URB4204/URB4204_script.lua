-- Automatically upvalued moho functions for performance
local CRotateManipulatorMethods = _G.moho.RotateManipulator
local CRotateManipulatorMethodsSetTargetSpeed = CRotateManipulatorMethods.SetTargetSpeed
-- End of automatically upvalued moho functions

--#****************************************************************************
--#**
--#**  File     :  /cdimage/units/URB4204/URB4204_script.lua
--#**  Author(s):  David Tomandl, Greg Kohne
--#**
--#**  Summary  :  Cybran Shield Generator lvl 2 Script
--#**
--#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--#****************************************************************************
local CShieldStructureUnit = import('/lua/cybranunits.lua').CShieldStructureUnit

URB4204 = Class(CShieldStructureUnit)({
    ShieldEffects = {
        '/effects/emitters/cybran_shield_02_generator_01_emit.bp',
        '/effects/emitters/cybran_shield_02_generator_02_emit.bp',
        '/effects/emitters/cybran_shield_02_generator_03_emit.bp',
    },

    OnStopBeingBuilt = function(self, builder, layer)
        CShieldStructureUnit.OnStopBeingBuilt(self, builder, layer)
        self.Rotator1 = CreateRotator(self, 'Shaft', 'z', nil, 30, 5, 30)
        self.Trash:Add(self.Rotator1)
        self.ShieldEffectsBag = {}
    end,

    OnShieldEnabled = function(self)
        CShieldStructureUnit.OnShieldEnabled(self)
        if self.Rotator1 then
            CRotateManipulatorMethodsSetTargetSpeed(self.Rotator1, 10)
        end

        if self.ShieldEffectsBag then
            for k, v in self.ShieldEffectsBag do
                v:Destroy()
            end
            self.ShieldEffectsBag = {}
        end

        for k, v in self.ShieldEffects do
            table.insert(self.ShieldEffectsBag, CreateAttachedEmitter(self, 'Shaft', self.Army, v))
        end
    end,

    OnShieldDisabled = function(self)
        CShieldStructureUnit.OnShieldDisabled(self)
        CRotateManipulatorMethodsSetTargetSpeed(self.Rotator1, 0)

        if self.ShieldEffectsBag then
            for k, v in self.ShieldEffectsBag do
                v:Destroy()
            end
            self.ShieldEffectsBag = {}
        end
    end,
})

TypeClass = URB4204
