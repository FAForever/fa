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
                local spinManip = self.SpinManip
                local unit = self.unit
                if spinManip then
                    spinManip:SetTargetSpeed(0)
                end
                EffectUtils.CreateBoneEffectsOpti(unit, 'Left_Arm_Barrel_Muzzle', unit.Army,
                    Effects.WeaponSteam01)
                TDFPlasmaCannonWeapon.PlayFxWeaponPackSequence(self)
            end,

            PlayFxRackSalvoChargeSequence = function(self)
                local unit = self.unit
                local spinManip = self.SpinManip
                if not spinManip then
                    spinManip = CreateRotator(unit, 'Left_Arm_Barrel', 'z', nil, 270, 180, 60)
                    self.SpinManip = spinManip
                    unit.Trash:Add(spinManip)
                end

                if spinManip then
                    spinManip:SetTargetSpeed(500)
                end
                TDFPlasmaCannonWeapon.PlayFxRackSalvoChargeSequence(self)
            end,

            PlayFxRackSalvoReloadSequence = function(self)
                local spinManip = self.SpinManip
                local unit = self.unit
                if spinManip then
                    spinManip:SetTargetSpeed(200)
                end
                self.ExhaustEffects = EffectUtils.CreateBoneEffectsOpti(unit, 'Left_Arm_Barrel_Muzzle',
                    unit.Army, Effects.WeaponSteam01)
                TDFPlasmaCannonWeapon.PlayFxRackSalvoChargeSequence(self)
            end,
        },
        Grenade = ClassWeapon(TIFFragLauncherWeapon) {}
    },
}
TypeClass = DEL0204
