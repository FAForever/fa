local TStructureUnit = import('/lua/terranunits.lua').TStructureUnit
local TDFHeavyPlasmaCannonWeapon = import('/lua/terranweapons.lua').TDFHeavyPlasmaGatlingCannonWeapon

local EffectUtils = import('/lua/effectutilities.lua')
local Effects = import('/lua/effecttemplates.lua')

XEB2306 = Class(TStructureUnit) {
    Weapons = {
        MainGun = Class(TDFHeavyPlasmaCannonWeapon) 
        {       
            PlayFxWeaponPackSequence = function(self)
                self.ExhaustEffects = EffectUtils.CreateBoneEffects( self.unit, 'Exhaust', self.unit:GetArmy(), Effects.WeaponSteam01 )
                TDFHeavyPlasmaCannonWeapon.PlayFxWeaponPackSequence(self)
            end,
            
            PlayFxRackSalvoReloadSequence = function(self)
                self.ExhaustEffects = EffectUtils.CreateBoneEffects( self.unit, 'Exhaust', self.unit:GetArmy(), Effects.WeaponSteam01 )
                TDFHeavyPlasmaCannonWeapon.PlayFxRackSalvoChargeSequence(self)
            end,    
        }
    },

    OnStopBeingBuilt = function(self,builder,layer)
        TStructureUnit.OnStopBeingBuilt(self,builder,layer)

	self.Trash:Add(CreateRotator(self, 'Gun_Barrel', 'z', nil, 270, 0, 0))
    end,
}
TypeClass = XEB2306