--****************************************************************************
--**
--**  File     :  /cdimage/units/UES0202/UES0202_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Cruiser Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local EffectTemplate = import("/lua/effecttemplates.lua")
local TSeaUnit = import("/lua/terranunits.lua").TSeaUnit
local WeaponFile = import("/lua/terranweapons.lua")
local TSAMLauncher = WeaponFile.TSAMLauncher
local TDFGaussCannonWeapon = WeaponFile.TDFGaussCannonWeapon
local TAMPhalanxWeapon = WeaponFile.TAMPhalanxWeapon
local TIFCruiseMissileLauncher = WeaponFile.TIFCruiseMissileLauncher

---@class UES0202 : TSeaUnit
UES0202 = ClassUnit(TSeaUnit) {
    Weapons = {
        FrontTurret01 = ClassWeapon(TDFGaussCannonWeapon) {},
        BackTurret02 = ClassWeapon(TSAMLauncher) {
            FxMuzzleFlash = EffectTemplate.TAAMissileLaunchNoBackSmoke,
        },
        PhalanxGun01 = ClassWeapon(TAMPhalanxWeapon) {
            PlayFxWeaponUnpackSequence = function(self)
                if not self.SpinManip then 
                    self.SpinManip = CreateRotator(self.unit, 'Center_Turret_Barrel', 'z', nil, 270, 180, 60)
                    self.SpinManip:SetPrecedence(10)
                    self.unit.Trash:Add(self.SpinManip)
                end
                if self.SpinManip then
                    self.SpinManip:SetTargetSpeed(270)
                end
                TAMPhalanxWeapon.PlayFxWeaponUnpackSequence(self)
            end,

            PlayFxWeaponPackSequence = function(self)
                if self.SpinManip then
                    self.SpinManip:SetTargetSpeed(0)
                end
                TAMPhalanxWeapon.PlayFxWeaponPackSequence(self)
            end,
        },
        
        CruiseMissile = ClassWeapon(TIFCruiseMissileLauncher) {
            OnCreate = function(self)
                TIFCruiseMissileLauncher.OnCreate(self)
                self.RackToUse = 1
            end,

            CreateProjectileAtMuzzle = function(self, muzzle)
                muzzle = self.Blueprint.RackBones[self.RackToUse].MuzzleBones[1]
                if self.RackToUse >= 8 then
                    self.RackToUse = 1
                else
                    self.RackToUse = self.RackToUse + 1
                end

                return TIFCruiseMissileLauncher.CreateProjectileAtMuzzle(self, muzzle)
            end,

            PlayFxMuzzleSequence = function(self, muzzle)
                muzzle = self.Blueprint.RackBones[self.RackToUse].MuzzleBones[1]
                TIFCruiseMissileLauncher.PlayFxMuzzleSequence(self, muzzle)
            end,
        },
    },

    OnStopBeingBuilt = function(self, builder,layer)
        TSeaUnit.OnStopBeingBuilt(self, builder,layer)
        self:ForkThread(self.RadarThread)
        self.Trash:Add(CreateRotator(self, 'Spinner01', 'y', nil, 45, 0, 0))
        self.Trash:Add(CreateRotator(self, 'Spinner03', 'y', nil, -30, 0, 0))
        self.Trash:Add(CreateRotator(self, 'Spinner04', 'y', nil, 0, 30, -45))
    end,
}

TypeClass = UES0202
