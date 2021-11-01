-- Automatically upvalued moho functions for performance
local CRotateManipulatorMethods = _G.moho.RotateManipulator
local CRotateManipulatorMethodsSetTargetSpeed = CRotateManipulatorMethods.SetTargetSpeed
-- End of automatically upvalued moho functions

--#****************************************************************************
--#**
--#**  File     :  /cdimage/units/XEB2306/XEB2306_script.lua
--#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix, Matt Vainio
--#**
--#**  Summary  :  Terran Light Gun Tower Script
--#**
--#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--#****************************************************************************
local TStructureUnit = import('/lua/terranunits.lua').TStructureUnit
local TDFHeavyPlasmaCannonWeapon = import('/lua/terranweapons.lua').TDFHeavyPlasmaGatlingCannonWeapon

local EffectUtils = import('/lua/effectutilities.lua')
local Effects = import('/lua/effecttemplates.lua')

XEB2306 = Class(TStructureUnit)({
    Weapons = {
        MainGun = Class(TDFHeavyPlasmaCannonWeapon)({
            PlayFxWeaponPackSequence = function(self)
                if self.SpinManip then
                    CRotateManipulatorMethodsSetTargetSpeed(self.SpinManip, 0)
                end
                self.ExhaustEffects = EffectUtils.CreateBoneEffects(self.unit, 'Exhaust', self.unit.Army, Effects.WeaponSteam01)
                TDFHeavyPlasmaCannonWeapon.PlayFxWeaponPackSequence(self)
            end,

            PlayFxRackSalvoChargeSequence = function(self)
                if not self.SpinManip then
                    self.SpinManip = CreateRotator(self.unit, 'Gun_Barrel', 'z', nil, 270, 180, 60)
                    self.unit.Trash:Add(self.SpinManip)
                end

                if self.SpinManip then
                    CRotateManipulatorMethodsSetTargetSpeed(self.SpinManip, 500)
                end
                TDFHeavyPlasmaCannonWeapon.PlayFxRackSalvoChargeSequence(self)
            end,

            PlayFxRackSalvoReloadSequence = function(self)
                if self.SpinManip then
                    CRotateManipulatorMethodsSetTargetSpeed(self.SpinManip, 200)
                end
                self.ExhaustEffects = EffectUtils.CreateBoneEffects(self.unit, 'Exhaust', self.unit.Army, Effects.WeaponSteam01)
                TDFHeavyPlasmaCannonWeapon.PlayFxRackSalvoChargeSequence(self)
            end,
        }),
    },
})

TypeClass = XEB2306
