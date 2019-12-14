local TWalkingLandUnit = import('/lua/terranunits.lua').TWalkingLandUnit
local TWeapons = import('/lua/terranweapons.lua')
local TDFPlasmaCannonWeapon = TWeapons.TDFPlasmaCannonWeapon
local TIFFragLauncherWeapon = TWeapons.TDFFragmentationGrenadeLauncherWeapon
local EffectUtils = import('/lua/effectutilities.lua')
local Effects = import('/lua/effecttemplates.lua')

DEL0204 = Class(TWalkingLandUnit) 
{
    Weapons = {
        GatlingCannon = Class(TDFPlasmaCannonWeapon) 
        {
            PlayFxWeaponPackSequence = function(self)
                self.ExhaustEffects = EffectUtils.CreateBoneEffects( self.unit, 'Left_Arm_Barrel_Muzzle', self.unit:GetArmy(), Effects.WeaponSteam01 )
                TDFPlasmaCannonWeapon.PlayFxWeaponPackSequence(self)
            end,           
            
            PlayFxRackSalvoReloadSequence = function(self)
                self.ExhaustEffects = EffectUtils.CreateBoneEffects( self.unit, 'Left_Arm_Barrel_Muzzle', self.unit:GetArmy(), Effects.WeaponSteam01 )
                TDFPlasmaCannonWeapon.PlayFxRackSalvoChargeSequence(self)
            end,
        },
        
        Grenade = Class(TIFFragLauncherWeapon) {}
    },

    OnStopBeingBuilt = function(self,builder,layer)
        TWalkingLandUnit.OnStopBeingBuilt(self,builder,layer)

	self.Trash:Add(CreateRotator(self, 'Left_Arm_Barrel', 'z', nil, 270, 0, 0))
    end,
}

TypeClass = DEL0204