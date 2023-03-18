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
        ParticleGun = ClassWeapon(CDFProtonCannonWeapon) {},
        AAGun = ClassWeapon(CAANanoDartWeapon) {

            IdleState = State (CAANanoDartWeapon.IdleState) {
                ---@param self CAANanoDartWeapon
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

            ---@param self CAANanoDartWeapon
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
        Zapper = ClassWeapon(CAMZapperWeapon03) {},
    },
}

TypeClass = URS0202
