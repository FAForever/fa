-----------------------------------------------------
-- Author(s):  Mikko Tyster
-- Summary  :  UEF T3 Anti-Air
-- Copyright © 2008 Blade Braver!
-----------------------------------------------------
local TLandUnit = import("/lua/terranunits.lua").TLandUnit
local TWeapons = import("/lua/terranweapons.lua")
local TDFPlasmaCannonWeapon = TWeapons.TDFPlasmaCannonWeapon
local TAAPhalanxWeapon = import("/lua/kirvesweapons.lua").TAAPhalanxWeapon
local EffectUtils = import("/lua/effectutilities.lua")
local Effects = import("/lua/effecttemplates.lua")


---@class DELK002 : TLandUnit
DELK002 = ClassUnit(TLandUnit) {
    Weapons = {
        GatlingCannon = ClassWeapon(TAAPhalanxWeapon)
        {
            PlayFxWeaponPackSequence = function(self)
                if self.SpinManip1 then
                    self.SpinManip1:SetTargetSpeed(0)
                end
                if self.SpinManip2 then
                    self.SpinManip2:SetTargetSpeed(0)
                end
                EffectUtils.CreateBoneEffectsOpti(self.unit, 'Left_Muzzle', self.unit.Army, Effects.WeaponSteam01)
                EffectUtils.CreateBoneEffectsOpti(self.unit, 'Right_Muzzle', self.unit.Army, Effects.WeaponSteam01)
                TAAPhalanxWeapon.PlayFxWeaponPackSequence(self)
            end,

            PlayFxRackSalvoChargeSequence = function(self)
                if not self.SpinManip1 then
                    self.SpinManip1 = CreateRotator(self.unit, 'Right_Barrel', 'z', nil, 360, 180, 60)
                    self.unit.Trash:Add(self.SpinManip1)
                end

                if self.SpinManip1 then
                    self.SpinManip1:SetTargetSpeed(500)
                end
                if not self.SpinManip2 then
                    self.SpinManip2 = CreateRotator(self.unit, 'Left_Barrel', 'z', nil, 360, 180, 60)
                    self.unit.Trash:Add(self.SpinManip2)
                end

                if self.SpinManip2 then
                    self.SpinManip2:SetTargetSpeed(500)
                end
                TAAPhalanxWeapon.PlayFxRackSalvoChargeSequence(self)
            end,

            PlayFxRackSalvoReloadSequence = function(self)
                if self.SpinManip1 then
                    self.SpinManip1:SetTargetSpeed(200)
                end
                if self.SpinManip2 then
                    self.SpinManip2:SetTargetSpeed(200)
                end
                EffectUtils.CreateBoneEffectsOpti(self.unit, 'Left_Muzzle', self.unit.Army, Effects.WeaponSteam01)
                EffectUtils.CreateBoneEffectsOpti(self.unit, 'Right_Muzzle', self.unit.Army, Effects.WeaponSteam01)
                TAAPhalanxWeapon.PlayFxRackSalvoChargeSequence(self)
            end,
        },
    },
}
TypeClass = DELK002