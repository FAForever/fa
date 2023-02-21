-----------------------------------------------------------------
-- File     :  /cdimage/units/URS0202/URS0202_script.lua
-- Author(s):  David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Cruiser Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local CSeaUnit = import("/lua/cybranunits.lua").CSeaUnit
local CybranWeaponsFile = import("/lua/cybranweapons.lua")
local CDFProtonCannonWeapon = CybranWeaponsFile.CDFProtonCannonWeapon
local CAANanoDartWeapon = CybranWeaponsFile.CAANanoDartWeapon
local CAMZapperWeapon03 = CybranWeaponsFile.CAMZapperWeapon03
local TargetingLaser = import("/lua/kirvesweapons.lua").TargetingLaserInvisible

---@class URS0202 : CSeaUnit
URS0202 = ClassUnit(CSeaUnit) {
    Weapons = {
        TargetPainter = ClassWeapon(TargetingLaser) {
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
                -- Start with the AA gun off to reduce twitching of ground fire
                Main = function(self)
                    self.unit:SetWeaponEnabledByLabel('GroundGun', true)
                    self.unit:SetWeaponEnabledByLabel('AAGun', true)
                    self.AA = false
                    TargetingLaser.IdleState.Main(self)
                end,
            },
        },
        ParticleGun = ClassWeapon(CDFProtonCannonWeapon) {},
        AAGun = ClassWeapon(CAANanoDartWeapon) {},
        GroundGun = ClassWeapon(CAANanoDartWeapon) {},
        Zapper = ClassWeapon(CAMZapperWeapon03) {},
    },
}

TypeClass = URS0202
