--****************************************************************************
--**
--**  File     :  /cdimage/units/UES0302/UES0302_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Battleship Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TSeaUnit = import("/lua/terranunits.lua").TSeaUnit
local WeaponsFile = import("/lua/terranweapons.lua")
local TAALinkedRailgun = WeaponsFile.TAALinkedRailgun
local TAMPhalanxWeapon = WeaponsFile.TAMPhalanxWeapon
local TDFGaussCannonWeapon = WeaponsFile.TDFShipGaussCannonWeapon

---@class UES0302 : TSeaUnit
UES0302 = Class(TSeaUnit) {


    Weapons = {
        RightAAGun01 = Class(TAALinkedRailgun) {},
        RightAAGun02 = Class(TAALinkedRailgun) {},
        LeftAAGun01 = Class(TAALinkedRailgun) {},
        LeftAAGun02 = Class(TAALinkedRailgun) {},
        RightPhalanxGun01 = Class(TAMPhalanxWeapon) {
            PlayFxWeaponUnpackSequence = function(self)
                if not self.SpinManip then 
                    self.SpinManip = CreateRotator(self.unit, 'Right_Turret02_Barrel', 'z', nil, 270, 180, 60)
                    self.unit.Trash:Add(self.SpinManip)
                end
                if self.SpinManip then
                    self.SpinManip:SetTargetSpeed(500):SetPrecedence(100)
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
        LeftPhalanxGun01 = Class(TAMPhalanxWeapon) {
            PlayFxWeaponUnpackSequence = function(self)
                if not self.SpinManip then 
                    self.SpinManip = CreateRotator(self.unit, 'Left_Turret02_Barrel', 'z', nil, 270, 180, 60)
                    self.unit.Trash:Add(self.SpinManip)
                end
                if self.SpinManip then
                    self.SpinManip:SetTargetSpeed(500):SetPrecedence(100)
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
        FrontTurret01 = Class(TDFGaussCannonWeapon) {},
        FrontTurret02 = Class(TDFGaussCannonWeapon) {},
        BackTurret = Class(TDFGaussCannonWeapon) {},
    },

    OnStopBeingBuilt = function(self,builder,layer)
        TSeaUnit.OnStopBeingBuilt(self,builder,layer)
        self.Trash:Add(CreateRotator(self, 'Spinner01', 'y', nil, -45))
        self.Trash:Add(CreateRotator(self, 'Spinner02', 'y', nil, 90))
    end,
}

TypeClass = UES0302