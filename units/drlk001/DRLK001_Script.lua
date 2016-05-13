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
		AAGun = Class(CAANanoDartWeapon) {
            IdleState = State(CAANanoDartWeapon.IdleState) {
                Main = function(self)
                    self.unit:SetWeaponEnabledByLabel('GroundGun', true)
                    self.unit:GetWeaponManipulatorByLabel('GroundGun'):SetHeadingPitch(self:GetWeaponManipulatorByLabel('AAGun'):GetHeadingPitch())
                    CAANanoDartWeapon.IdleState.Main(self)
                end,
                
                OnGotTarget = function(self)
                    self.unit:SetWeaponEnabledByLabel('GroundGun', false)
                    CAANanoDartWeapon.IdleState.OnGotTarget(self)
                end,
                
                OnFire = function(self)
                    self.unit:SetWeaponEnabledByLabel('GroundGun', false)
                    CAANanoDartWeapon.IdleState.OnFire(self)
                end,
            },
        },    
		Lazor = Class(TargetingLaser) {
            FxMuzzleFlash = {'/effects/emitters/particle_cannon_muzzle_02_emit.bp'},
            
            IdleState = State(TargetingLaser.IdleState) {
                Main = function(self)
                    self.unit:SetWeaponEnabledByLabel('GroundGun', true)
                    self.unit:GetWeaponManipulatorByLabel('GroundGun'):SetHeadingPitch(self:GetWeaponManipulatorByLabel('AAGun'):GetHeadingPitch())
                    TargetingLaser.IdleState.Main(self)
                end,
                
                OnGotTarget = function(self)
                    self.unit:SetWeaponEnabledByLabel('GroundGun', false)
                    TargetingLaser.IdleState.OnGotTarget(self)
                end,
                
                OnFire = function(self)
                    self.unit:SetWeaponEnabledByLabel('GroundGun', false)
                    TargetingLaser.IdleState.OnFire(self)
                end,
            },
            
        },
		GroundGun = Class(CAANanoDartWeapon) {
            IdleState = State(CAANanoDartWeapon.IdleState) {
                Main = function(self)
                    self.unit:SetWeaponEnabledByLabel('AAGun', true)
                    self.unit:GetWeaponManipulatorByLabel('AAGun'):SetHeadingPitch(self:GetWeaponManipulatorByLabel('GroundGun'):GetHeadingPitch())
                    CAANanoDartWeapon.IdleState.Main(self)
                end,
                
                OnGotTarget = function(self)
                    self.unit:SetWeaponEnabledByLabel('AAGun', false)
                    CAANanoDartWeapon.IdleState.OnGotTarget(self)
                end,
                
                OnFire = function(self)
                    self.unit:SetWeaponEnabledByLabel('AAGun', false)
                    CAANanoDartWeapon.IdleState.OnFire(self)
                end,
            },
		},
    },
}

TypeClass = DRLK001
