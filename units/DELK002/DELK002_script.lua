-----------------------------------------------------
-- Author(s):  Mikko Tyster
-- Summary  :  UEF T3 Anti-Air
-- Copyright © 2008 Blade Braver!
-----------------------------------------------------
local TLandUnit = import("/lua/terranunits.lua").TLandUnit
local TWeapons = import("/lua/terranweapons.lua")
local TAAPhalanxWeapon = import("/lua/kirvesweapons.lua").TAAPhalanxWeapon
local EffectUtils = import("/lua/effectutilities.lua")
local Effects = import("/lua/effecttemplates.lua")

---@class DELK002 : TLandUnit
DELK002 = ClassUnit(TLandUnit) {
    Weapons = {
        GatlingCannon = ClassWeapon(TAAPhalanxWeapon)
        {
            PlayFxWeaponPackSequence = function(self)
                local spin1 = self.SpinManip1
                local spin2 = self.SpinManip2
                local unit = self.unit
                if spin1 then
                    spin1:SetTargetSpeed(0)
                end
                if spin2 then
                    spin2:SetTargetSpeed(0)
                end
                EffectUtils.CreateBoneEffectsOpti(unit, 'Left_Muzzle', unit.Army, Effects.WeaponSteam01)
                EffectUtils.CreateBoneEffectsOpti(unit, 'Right_Muzzle', unit.Army, Effects.WeaponSteam01)
                TAAPhalanxWeapon.PlayFxWeaponPackSequence(self)
            end,

            PlayFxRackSalvoChargeSequence = function(self)
                local spin1 = self.SpinManip1
                local spin2 = self.SpinManip2
                local unit = self.unit
                if not spin1 then
                    spin1 = CreateRotator(unit, 'Right_Barrel', 'z', nil, 360, 180, 60)
                    unit.Trash:Add(spin1)
                end

                if spin1 then
                    spin1:SetTargetSpeed(500)
                end
                if not spin2 then
                    spin2 = CreateRotator(unit, 'Left_Barrel', 'z', nil, 360, 180, 60)
                    unit.Trash:Add(spin2)
                end

                if spin2 then
                    spin2:SetTargetSpeed(500)
                end
                TAAPhalanxWeapon.PlayFxRackSalvoChargeSequence(self)
            end,

            PlayFxRackSalvoReloadSequence = function(self)
                local spin1 = self.SpinManip1
                local spin2 = self.SpinManip2
                local unit = self.unit
                if spin1 then
                    spin1:SetTargetSpeed(200)
                end
                if spin2 then
                    spin2:SetTargetSpeed(200)
                end
                EffectUtils.CreateBoneEffectsOpti(unit, 'Left_Muzzle', unit.Army, Effects.WeaponSteam01)
                EffectUtils.CreateBoneEffectsOpti(unit, 'Right_Muzzle', unit.Army, Effects.WeaponSteam01)
                TAAPhalanxWeapon.PlayFxRackSalvoChargeSequence(self)
            end,
        },
    },
}
TypeClass = DELK002

--- Move For Mod Support
local TDFPlasmaCannonWeapon = TWeapons.TDFPlasmaCannonWeapon
