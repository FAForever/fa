#****************************************************************************
#**
#**  Author(s):  Mikko Tyster
#**
#**  Summary  :  Cybran T3 Mobile AA
#**
#**  Copyright © 2008 Blade Braver!
#****************************************************************************

local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local CybranWeaponsFile = import('/lua/cybranweapons.lua')
local CAANanoDartWeapon = CybranWeaponsFile.CAANanoDartWeapon
local TargetingLaser = import('/lua/kirvesweapons.lua').TargetingLaser
local EffectUtils = import('/lua/effectutilities.lua')
local Effects = import('/lua/effecttemplates.lua')

DRLK001 = Class(CWalkingLandUnit) 
{
    Weapons = {
		AAGun = Class(CAANanoDartWeapon) {},    
		Lazor = Class(TargetingLaser) {
            FxMuzzleFlash = {'/effects/emitters/particle_cannon_muzzle_02_emit.bp'},
        },
		GroundGun = Class(CAANanoDartWeapon) {
			SetOnTransport = function(self, transportstate)
                CAANanoDartWeapon.SetOnTransport(self, transportstate)
                self.unit:SetScriptBit('RULEUTC_WeaponToggle', false)
            end,
		},
    },
	
	OnCreate = function(self)
        CWalkingLandUnit.OnCreate(self)
        self:SetWeaponEnabledByLabel('GroundGun', false)
    end,
	
	OnKilled = function(self, instigator, type, overkillRatio)
        self:SetWeaponEnabledByLabel('Lazor', false)
        CWalkingLandUnit.OnKilled(self, instigator, type, overkillRatio)
    end,
    
    OnScriptBitSet = function(self, bit)
        CWalkingLandUnit.OnScriptBitSet(self, bit)
        if bit == 1 then 
            self:SetWeaponEnabledByLabel('GroundGun', true)
            self:SetWeaponEnabledByLabel('AAGun', false)
			self:SetWeaponEnabledByLabel('Lazor', false)
            self:GetWeaponManipulatorByLabel('GroundGun'):SetHeadingPitch( self:GetWeaponManipulatorByLabel('AAGun'):GetHeadingPitch() )
        end
    end,

    OnScriptBitClear = function(self, bit)
        CWalkingLandUnit.OnScriptBitClear(self, bit)
        if bit == 1 then 
            self:SetWeaponEnabledByLabel('GroundGun', false)
            self:SetWeaponEnabledByLabel('AAGun', true)
			self:SetWeaponEnabledByLabel('Lazor', true)
            self:GetWeaponManipulatorByLabel('AAGun'):SetHeadingPitch( self:GetWeaponManipulatorByLabel('GroundGun'):GetHeadingPitch() )
        end
    end,
}

TypeClass = DRLK001