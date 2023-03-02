-----------------------------------------------------------------
-- File     :  /cdimage/units/URL0104/URL0104_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  Cybran Anti-Air Tank Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local CLandUnit = import("/lua/cybranunits.lua").CLandUnit
local CybranWeaponsFile = import("/lua/cybranweapons.lua")
local CAANanoDartWeapon = CybranWeaponsFile.CAANanoDartWeapon
local TargetingLaser = import("/lua/kirvesweapons.lua").TargetingLaserInvisible

---@class URL0104 : CLandUnit
URL0104 = ClassUnit(CLandUnit) {
    Weapons = {
       AAGun = ClassWeapon(CAANanoDartWeapon) {
            IdleState = State (CAANanoDartWeapon.IdleState) {
                OnGotTarget = function(self)
                    CAANanoDartWeapon.IdleState.OnGotTarget(self)
                    LOG("OnGotTarget")
                    self.unit:SetWeaponEnabledByLabel('GroundGun', false)
                    self.unit:GetWeaponManipulatorByLabel('AAGun'):SetHeadingPitch(self.unit:GetWeaponManipulatorByLabel('GroundGun'):GetHeadingPitch())
                end,
            },

            OnLostTarget = function(self)
                CAANanoDartWeapon.OnLostTarget(self)
                LOG("OnLostTarget")
                self.unit:SetWeaponEnabledByLabel('GroundGun', true)
                self.unit:GetWeaponManipulatorByLabel('GroundGun'):SetHeadingPitch(self.unit:GetWeaponManipulatorByLabel('AAGun'):GetHeadingPitch())
            end,
        },
        GroundGun = ClassWeapon(CAANanoDartWeapon) {},
    },
}

TypeClass = URL0104
