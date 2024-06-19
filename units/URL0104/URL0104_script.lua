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

TypeClass = URL0104
