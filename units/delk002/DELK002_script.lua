#****************************************************************************
#**
#**  Author(s):  Mikko Tyster
#**
#**  Summary  :  UEF T3 Anti-Air
#**
#**  Copyright © 2008 Blade Braver!
#****************************************************************************
local TLandUnit = import('/lua/terranunits.lua').TLandUnit
local TWeapons = import('/lua/terranweapons.lua')
local TDFPlasmaCannonWeapon = TWeapons.TDFPlasmaCannonWeapon
local TAAPhalanxWeapon = import('/lua/kirvesweapons.lua').TAAPhalanxWeapon
local EffectUtils = import('/lua/effectutilities.lua')
local Effects = import('/lua/effecttemplates.lua')

DELK002 = Class(TLandUnit) {
    Weapons = {
        GatlingCannon = Class(TAAPhalanxWeapon)
        {
            PlayFxWeaponPackSequence = function(self)
                self.ExhaustEffects = EffectUtils.CreateBoneEffects(self.unit, 'Left_Muzzle', self.unit:GetArmy(), Effects.WeaponSteam01)
                self.ExhaustEffects = EffectUtils.CreateBoneEffects(self.unit, 'Right_Muzzle', self.unit:GetArmy(), Effects.WeaponSteam01)
                TAAPhalanxWeapon.PlayFxWeaponPackSequence(self)
            end,

            PlayFxRackSalvoReloadSequence = function(self)
                self.ExhaustEffects = EffectUtils.CreateBoneEffects(self.unit, 'Left_Muzzle', self.unit:GetArmy(), Effects.WeaponSteam01)
                self.ExhaustEffects = EffectUtils.CreateBoneEffects(self.unit, 'Right_Muzzle', self.unit:GetArmy(), Effects.WeaponSteam01)
                TAAPhalanxWeapon.PlayFxRackSalvoChargeSequence(self)
            end,
        },
    },
	
    OnStopBeingBuilt = function(self,builder,layer)
        TLandUnit.OnStopBeingBuilt(self,builder,layer)
		self.Trash:Add(CreateRotator(self, 'Left_Barrel', 'z', nil, 360, 0, 0))
        self.Trash:Add(CreateRotator(self, 'Right_Barrel', 'z', nil, 360, 0, 0))
    end,
}

TypeClass = DELK002
