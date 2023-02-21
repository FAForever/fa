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

            -- Unit in range. Cease ground fire and turn on AA
            OnWeaponFired = function(self)
                if not self.AA then
                    self.unit:SetWeaponEnabledByLabel('GroundGun', false)
                    self.unit:SetWeaponEnabledByLabel('AAGun', true)
                    self.AA = true
                end
            TargetingLaser.OnWeaponFired(self)
            end,

            IdleState = State(TargetingLaser.IdleState) {
                -- Enable ground fire
                Main = function(self)
                    self.unit:SetWeaponEnabledByLabel('GroundGun', true)
                    self.unit:SetWeaponEnabledByLabel('AAGun', true)
                    self.AA = false
            TargetingLaser.IdleState.Main(self)
                end,
            },
        },
        AAGun = ClassWeapon(CAANanoDartWeapon) {},
        GroundGun = ClassWeapon(CAANanoDartWeapon) {},
    },
}
TypeClass = DRLK001