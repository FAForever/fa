-----------------------------------
-- Author(s):  Mikko Tyster
-- Summary  :  Cybran T3 Mobile AA
-- Copyright © 2008 Blade Braver!
-----------------------------------
local CWalkingLandUnit = import("/lua/cybranunits.lua").CWalkingLandUnit
local CybranWeaponsFile = import("/lua/cybranweapons.lua")
local CAANanoDartWeapon = CybranWeaponsFile.CAANanoDartWeapon
local TargetingLaser = import("/lua/kirvesweapons.lua").TargetingLaser
local Effects = import("/lua/effecttemplates.lua")

---@class DRLK001 : CWalkingLandUnit
DRLK001 = ClassUnit(CWalkingLandUnit) {
    Weapons = {
        TargetPainter = ClassWeapon(TargetingLaser) {
            FxMuzzleFlash = {'/effects/emitters/particle_cannon_muzzle_02_emit.bp'}, 
        },
        
	AAGun = ClassWeapon(CAANanoDartWeapon) {
            IdleState = State (CAANanoDartWeapon.IdleState) {
                OnGotTarget = function(self)
                    CAANanoDartWeapon.IdleState.OnGotTarget(self)

                    -- copy over heading / pitch from ground gun to aa gun
                    local unit = self.unit
                    local aa = unit:GetWeaponManipulatorByLabel('AAGun') --[[@as moho.AimManipulator]]
                    local ground = unit:GetWeaponManipulatorByLabel('GroundGun') --[[@as moho.AimManipulator]]
                    aa:SetHeadingPitch(ground:GetHeadingPitch())

                    unit:SetWeaponEnabledByLabel('GroundGun', false)
                end,
            },

            OnLostTarget = function(self)
                CAANanoDartWeapon.OnLostTarget(self)

                -- copy over heading / pitch from aa gun to ground gun
                local unit = self.unit
                local aa = unit:GetWeaponManipulatorByLabel('AAGun') --[[@as moho.AimManipulator]]
                local ground = unit:GetWeaponManipulatorByLabel('GroundGun') --[[@as moho.AimManipulator]]
                ground:SetHeadingPitch(aa:GetHeadingPitch())

                -- reset heading / pitch of aa gun to prevent twitching
                aa:SetHeadingPitch(0, 0)

                unit:SetWeaponEnabledByLabel('GroundGun', true)
            end,
        },
        GroundGun = ClassWeapon(CAANanoDartWeapon) {},
    },
}
TypeClass = DRLK001