-----------------------------------------------------------------
-- File     :  /cdimage/units/UES0304/UES0304_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  UEF Strategic Missile Submarine Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local TSubUnit = import("/lua/terranunits.lua").TSubUnit
local WeaponFile = import("/lua/terranweapons.lua")
local TIFCruiseMissileLauncherSub = WeaponFile.TIFCruiseMissileLauncherSub
local TIFStrategicMissileWeapon = WeaponFile.TIFStrategicMissileWeapon
local EffectTemplate = import('/lua/effecttemplates.lua')

---@class UES0304 : TSubUnit
UES0304 = ClassUnit(TSubUnit) {
    DeathThreadDestructionWaitTime = 0,
    Weapons = {
        CruiseMissiles = ClassWeapon(TIFCruiseMissileLauncherSub) {
            PlayFxMuzzleChargeSequence = function(self, muzzle)
                --We don't need to wait for the rotator to finish because MuzzleChargeDelay = 1 in the bp will do that for us.
                self.Rotator = CreateRotator(self.unit, self:GetBlueprint().RackBones[self.CurrentRackSalvoNumber].RackBone, 'z', 90, 90, 90, 90)
                TIFCruiseMissileLauncherSub.PlayFxMuzzleChargeSequence(self, muzzle)
            end,

            PlayFxRackReloadSequence = function(self)
                self.Trash:Add(ForkThread(function()
                    -- Wait 1 second for the missile to clear the hatch.
                    WaitSeconds(1)
                    self.Rotator:SetGoal(0)
                    WaitFor(self.Rotator)
                    self.Rotator:Destroy()
                    self.Rotator = nil
                end))
                TIFCruiseMissileLauncherSub.PlayFxRackReloadSequence(self)
            end,
        },

        NukeMissiles = ClassWeapon(TIFStrategicMissileWeapon) {
            FxMuzzleFlash = EffectTemplate.TIFCruiseMissileLaunchUnderWater,

            PlayFxMuzzleChargeSequence = function(self, muzzle)
                --We don't need to wait for the rotator to finish because MuzzleChargeDelay = 1 in the bp will do that for us.
                self.Rotator = CreateRotator(self.unit, self:GetBlueprint().RackBones[self.CurrentRackSalvoNumber].RackBone, 'z', 90, 90, 90, 90)
                TIFCruiseMissileLauncherSub.PlayFxMuzzleChargeSequence(self, muzzle)
            end,

            PlayFxRackReloadSequence = function(self)
                self.Trash:Add(ForkThread(function()
                    -- Wait 1 second for the missile to clear the hatch.
                    WaitSeconds(1)
                    self.Rotator:SetGoal(0)
                    WaitFor(self.Rotator)
                    self.Rotator:Destroy()
                    self.Rotator = nil
                end))
                TIFCruiseMissileLauncherSub.PlayFxRackReloadSequence(self)
            end,
        },
    },
}

TypeClass = UES0304
