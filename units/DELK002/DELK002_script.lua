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

-- upvalue for performance
local CreateRotator = CreateRotator
local TrashBagAdd = TrashBag.Add

---@class DELK002 : TLandUnit
DELK002 = ClassUnit(TLandUnit) {
    Weapons = {
        GatlingCannon = ClassWeapon(TAAPhalanxWeapon)
        {
            PlayFxWeaponPackSequence = function(self)
                local unit = self.unit
                local army = self.Army

                if self.SpinManip1 then
                    self.SpinManip1:SetTargetSpeed(0)
                end
                if self.SpinManip2 then
                    self.SpinManip2:SetTargetSpeed(0)
                end
                EffectUtils.CreateBoneEffectsOpti(unit, 'Left_Muzzle', army, Effects.WeaponSteam01)
                EffectUtils.CreateBoneEffectsOpti(unit, 'Right_Muzzle', army, Effects.WeaponSteam01)
                TAAPhalanxWeapon.PlayFxWeaponPackSequence(self)
            end,

            PlayFxRackSalvoChargeSequence = function(self)
                local trash = self.Trash
                local unit = self.unit

                if not self.SpinManip1 then
                    self.SpinManip1 = CreateRotator(unit, 'Right_Barrel', 'z', nil, 360, 180, 60)
                    TrashBagAdd(trash,self.SpinManip1)
                end

                if self.SpinManip1 then
                    self.SpinManip1:SetTargetSpeed(500)
                end
                if not self.SpinManip2 then
                    self.SpinManip2 = CreateRotator(unit, 'Left_Barrel', 'z', nil, 360, 180, 60)
                    TrashBagAdd(trash,self.SpinManip2)
                end

                if self.SpinManip2 then
                    self.SpinManip2:SetTargetSpeed(500)
                end
                TAAPhalanxWeapon.PlayFxRackSalvoChargeSequence(self)
            end,

            PlayFxRackSalvoReloadSequence = function(self)
                local unit = self.unit
                local army = self.Army

                if self.SpinManip1 then
                    self.SpinManip1:SetTargetSpeed(200)
                end
                if self.SpinManip2 then
                    self.SpinManip2:SetTargetSpeed(200)
                end
                EffectUtils.CreateBoneEffectsOpti(unit, 'Left_Muzzle',  army, Effects.WeaponSteam01)
                EffectUtils.CreateBoneEffectsOpti(unit, 'Right_Muzzle', army, Effects.WeaponSteam01)
                TAAPhalanxWeapon.PlayFxRackSalvoChargeSequence(self)
            end,
        },
    },
}
TypeClass = DELK002