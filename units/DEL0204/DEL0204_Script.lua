------------------------------------------------------------------------------
-- File     :  /cdimage/units/DEL0204/DEL0204_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix, Matt Vainio
-- Summary  :  UEF Mongoose Gatling Bot
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------
local TWalkingLandUnit = import("/lua/terranunits.lua").TWalkingLandUnit
local TWeapons = import("/lua/terranweapons.lua")
local TDFPlasmaCannonWeapon = TWeapons.TDFPlasmaCannonWeapon
local TIFFragLauncherWeapon = TWeapons.TDFFragmentationGrenadeLauncherWeapon

local EffectUtils = import("/lua/effectutilities.lua")
local Effects = import("/lua/effecttemplates.lua")


---@class DEL0204 : TWalkingLandUnit
DEL0204 = ClassUnit(TWalkingLandUnit)
{
    Weapons = {
        GatlingCannon = ClassWeapon(TDFPlasmaCannonWeapon) 
        {
            PlayFxWeaponPackSequence = function(self)
                if self.SpinManip then
                    self.SpinManip:SetTargetSpeed(0)
                end
                EffectUtils.CreateBoneEffectsOpti(self.unit, 'Left_Arm_Barrel_Muzzle', self.unit.Army, Effects.WeaponSteam01)
                TDFPlasmaCannonWeapon.PlayFxWeaponPackSequence(self)
            end,

            PlayFxRackSalvoChargeSequence = function(self)
                if not self.SpinManip then 
                    self.SpinManip = CreateRotator(self.unit, 'Left_Arm_Barrel', 'z', nil, 270, 180, 60)
                    self.unit.Trash:Add(self.SpinManip)
                end

                if self.SpinManip then
                    self.SpinManip:SetTargetSpeed(500)
                end
                TDFPlasmaCannonWeapon.PlayFxRackSalvoChargeSequence(self)
            end,            

            PlayFxRackSalvoReloadSequence = function(self)
                if self.SpinManip then
                    self.SpinManip:SetTargetSpeed(200)
                end
                self.ExhaustEffects = EffectUtils.CreateBoneEffectsOpti(self.unit, 'Left_Arm_Barrel_Muzzle', self.unit.Army, Effects.WeaponSteam01)
                TDFPlasmaCannonWeapon.PlayFxRackSalvoChargeSequence(self)
            end,
        },
        Grenade = ClassWeapon(TIFFragLauncherWeapon) {}
    },
}
TypeClass = DEL0204