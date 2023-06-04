----------------------------------------------------------------------------
--
--  File     :  /cdimage/units/UES0307/UES0307_script.lua
--  Author(s):  Drew Staltman, Gordon Duclos, Greg Kohne
--
--  Summary  :  UEF Battleship Script
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------
local TSeaUnit = import("/lua/terranunits.lua").TSeaUnit
local WeaponsFile = import("/lua/terranweapons.lua")
local TAMPhalanxWeapon = WeaponsFile.TAMPhalanxWeapon
local TDFHiroPlasmaCannon = WeaponsFile.TDFHiroPlasmaCannon
local TANTorpedoAngler = WeaponsFile.TANTorpedoAngler
local TIFSmartCharge = WeaponsFile.TIFSmartCharge

---@class UES0302 : TSeaUnit
UES0302 = ClassUnit(TSeaUnit) {
    Weapons = {
        HiroCannonFront = ClassWeapon(TDFHiroPlasmaCannon) {},
        HiroCannonBack = ClassWeapon(TDFHiroPlasmaCannon) {},
        AntiTorpedo = ClassWeapon(TIFSmartCharge) {},
        TorpedoLeft01 = ClassWeapon(TANTorpedoAngler) {},
        TorpedoRight01 = ClassWeapon(TANTorpedoAngler) {},
        PhalanxGun = ClassWeapon(TAMPhalanxWeapon) {
            PlayFxWeaponUnpackSequence = function(self)
                if not self.SpinManip then
                    self.SpinManip = CreateRotator(self.unit, 'Front_Turret01_Barrel', 'z', nil, 270, 180, 60)
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
    },



        OnKilled = function(self, instigator, type, overkillRatio)
            if not self.Dead then
                local wep1 = self:GetWeaponByLabel('HiroCannonFront')
                local bp1 = wep1:GetBlueprint()
                if bp1.Audio.BeamStop then
                    wep1:PlaySound(bp1.Audio.BeamStop)
                end
                if bp1.Audio.BeamLoop and wep1.Beams[1].Beam then
                    wep1.Beams[1].Beam:SetAmbientSound(nil, nil)
                end
                for k, v in wep1.Beams do
                    v.Beam:Disable()
                end

                local wep2 = self:GetWeaponByLabel('HiroCannonBack')
                local bp2 = wep2:GetBlueprint()
                if bp2.Audio.BeamStop then
                    wep2:PlaySound(bp2.Audio.BeamStop)
                end
                if bp2.Audio.BeamLoop and wep2.Beams[1].Beam then
                    wep2.Beams[1].Beam:SetAmbientSound(nil, nil)
                end
                for k, v in wep2.Beams do
                    v.Beam:Disable()
                end
            end
            TSeaUnit.OnKilled(self, instigator, type, overkillRatio)
        end,
}
TypeClass = UES0302