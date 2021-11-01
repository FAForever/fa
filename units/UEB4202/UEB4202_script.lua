-- Automatically upvalued moho functions for performance
local CRotateManipulatorMethods = _G.moho.RotateManipulator
local CRotateManipulatorMethodsSetSpinDown = CRotateManipulatorMethods.SetSpinDown
local CRotateManipulatorMethodsSetTargetSpeed = CRotateManipulatorMethods.SetTargetSpeed
-- End of automatically upvalued moho functions

--#****************************************************************************
--#**
--#**  File     :  /cdimage/units/UEB4202/UEB4202_script.lua
--#**  Author(s):  David Tomandl
--#**
--#**  Summary  :  UEF Shield Generator Script
--#**
--#**  Copyright © 20010 Gas Powered Games, Inc.  All rights reserved.
--#****************************************************************************
local TShieldStructureUnit = import('/lua/terranunits.lua').TShieldStructureUnit

UEB4202 = Class(TShieldStructureUnit)({
    ShieldEffects = {
        '/effects/emitters/terran_shield_generator_t2_01_emit.bp',
        '/effects/emitters/terran_shield_generator_t2_02_emit.bp',
        --'/effects/emitters/terran_shield_generator_t2_03_emit.bp',
    },

    OnStopBeingBuilt = function(self, builder, layer)
        TShieldStructureUnit.OnStopBeingBuilt(self, builder, layer)
        self.Rotator1 = CreateRotator(self, 'Spinner', 'y', nil, 10, 5, 10)
        self.Rotator2 = CreateRotator(self, 'B01', 'z', nil, -10, 5, -10)
        self.Trash:Add(self.Rotator1)
        self.Trash:Add(self.Rotator2)
        self.ShieldEffectsBag = {}
    end,

    OnShieldEnabled = function(self)
        TShieldStructureUnit.OnShieldEnabled(self)
        if self.Rotator1 then
            CRotateManipulatorMethodsSetTargetSpeed(self.Rotator1, 10)
        end
        if self.Rotator2 then
            CRotateManipulatorMethodsSetTargetSpeed(self.Rotator2, -10)
        end

        if self.ShieldEffectsBag then
            for k, v in self.ShieldEffectsBag do
                v:Destroy()
            end
            self.ShieldEffectsBag = {}
        end
        for k, v in self.ShieldEffects do
            table.insert(self.ShieldEffectsBag, CreateAttachedEmitter(self, 0, self.Army, v))
        end
    end,

    OnShieldDisabled = function(self)
        TShieldStructureUnit.OnShieldDisabled(self)
        CRotateManipulatorMethodsSetTargetSpeed(self.Rotator1, 0)
        CRotateManipulatorMethodsSetTargetSpeed(self.Rotator2, 0)

        if self.ShieldEffectsBag then
            for k, v in self.ShieldEffectsBag do
                v:Destroy()
            end
            self.ShieldEffectsBag = {}
        end
    end,

    UpgradingState = State(TShieldStructureUnit.UpgradingState)({
        Main = function(self)
            CRotateManipulatorMethodsSetTargetSpeed(self.Rotator1, 90)
            CRotateManipulatorMethodsSetTargetSpeed(self.Rotator2, 90)
            CRotateManipulatorMethodsSetSpinDown(self.Rotator1, true)
            CRotateManipulatorMethodsSetSpinDown(self.Rotator2, true)
            TShieldStructureUnit.UpgradingState.Main(self)
        end,

        EnableShield = function(self)
            TShieldStructureUnit.EnableShield(self)
        end,

        DisableShield = function(self)
            TShieldStructureUnit.DisableShield(self)
        end,
    }),
})

TypeClass = UEB4202
