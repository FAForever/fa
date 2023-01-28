----****************************************************************************
----**
----**  File     :  /cdimage/units/UEB4202/UEB4202_script.lua
----**  Author(s):  David Tomandl
----**
----**  Summary  :  UEF Shield Generator Script
----**
----**  Copyright © 20010 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local TShieldStructureUnit = import("/lua/terranunits.lua").TShieldStructureUnit
local ShieldEffectsComponent = import("/lua/defaultcomponents.lua").ShieldEffectsComponent

---@class UEB4202 : TShieldStructureUnit
---@field Rotator1? moho.RotateManipulator
---@field Rotator2? moho.RotateManipulator
---@field ShieldEffectsBag TrashBag
UEB4202 = ClassUnit(TShieldStructureUnit, ShieldEffectsComponent) {
    ShieldEffects = {
        '/effects/emitters/terran_shield_generator_t2_01_emit.bp',
        '/effects/emitters/terran_shield_generator_t2_02_emit.bp',
        -- '/effects/emitters/terran_shield_generator_t2_03_emit.bp',
    },

    ---@param self UEB4202
    OnCreate = function(self)
        TShieldStructureUnit.OnCreate(self)
        ShieldEffectsComponent.OnCreate(self)
    end,

    ---@param self UEB4202
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self,builder,layer)
        TShieldStructureUnit.OnStopBeingBuilt(self,builder,layer)
        self.Rotator1 = CreateRotator(self, 'Spinner', 'y', nil, 10, 5, 10)
        self.Rotator2 = CreateRotator(self, 'B01', 'z', nil, -10, 5, -10)
        self.Trash:Add(self.Rotator1)
        self.Trash:Add(self.Rotator2)
    end,

    ---@param self UEB4202
    OnShieldEnabled = function(self)
        TShieldStructureUnit.OnShieldEnabled(self)
        ShieldEffectsComponent.OnShieldEnabled(self)

        if self.Rotator1 then
            self.Rotator1:SetTargetSpeed(10)
        end
        if self.Rotator2 then
            self.Rotator2:SetTargetSpeed(-10)
        end
    end,

    ---@param self UEB4202
    OnShieldDisabled = function(self)
        TShieldStructureUnit.OnShieldDisabled(self)
        ShieldEffectsComponent.OnShieldDisabled(self)
        self.Rotator1:SetTargetSpeed(0)
        self.Rotator2:SetTargetSpeed(0)
    end,

    UpgradingState = State(TShieldStructureUnit.UpgradingState) {
        Main = function(self)
            TShieldStructureUnit.UpgradingState.Main(self)
            self.Rotator1:SetTargetSpeed(90)
            self.Rotator2:SetTargetSpeed(90)
            self.Rotator1:SetSpinDown(true)
            self.Rotator2:SetSpinDown(true)
        end,
    }
}

TypeClass = UEB4202
