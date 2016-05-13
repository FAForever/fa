-----------------------------------
-- Author(s):  Mikko Tyster
-- Summary  :  Cybran T3 Mobile AA
-- Copyright © 2008 Blade Braver!
-----------------------------------

local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local CybranWeaponsFile = import('/lua/cybranweapons.lua')
local CAANanoDartWeapon = CybranWeaponsFile.CAANanoDartWeapon
local TargetingLaser = import('/lua/kirvesweapons.lua').TargetingLaser
local Effects = import('/lua/effecttemplates.lua')

DRLK001 = Class(CWalkingLandUnit) {
    Weapons = {
		AAGun = Class(CAANanoDartWeapon) {},    
		Lazor = Class(TargetingLaser) {
            FxMuzzleFlash = {'/effects/emitters/particle_cannon_muzzle_02_emit.bp'},
            
            IdleState = State(TargetingLaser.IdleState) {
            
                -- Start with the AA gun off to reduce twitching of ground fire
                Main = function(self)
                    WARN('Idle')
                    self.unit:SetWeaponEnabledByLabel('GroundGun', true)
                    self.unit:SetWeaponEnabledByLabel('AAGun', false)
                    self.unit:GetWeaponManipulatorByLabel('GroundGun'):SetHeadingPitch(self.unit:GetWeaponManipulatorByLabel('AAGun'):GetHeadingPitch())
                    TargetingLaser.IdleState.Main(self)
                end,
                
                -- Unit in range. Ceasee ground fire and turn on AA
                OnFire = function(self)
                    self.unit:SetWeaponEnabledByLabel('GroundGun', false)
                    self.unit:SetWeaponEnabledByLabel('AAGun', true)
                    self.unit:GetWeaponManipulatorByLabel('AAGun'):SetHeadingPitch(self.unit:GetWeaponManipulatorByLabel('GroundGun'):GetHeadingPitch())
                    TargetingLaser.IdleState.OnFire(self)
                end,
            },
            
        },
		GroundGun = Class(CAANanoDartWeapon) {},
    },
}

TypeClass = DRLK001
