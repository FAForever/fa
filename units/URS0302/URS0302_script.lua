--****************************************************************************
--**
--**  File     :  /cdimage/units/URS0302/URS0302_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  Cybran Battleship Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local CSeaUnit = import("/lua/cybranunits.lua").CSeaUnit
local CybranWeaponsFile = import("/lua/cybranweapons.lua")
local CAAAutocannon = CybranWeaponsFile.CAAAutocannon
local CDFProtonCannonWeapon = CybranWeaponsFile.CDFProtonCannonWeapon
local CANNaniteTorpedoWeapon = CybranWeaponsFile.CANNaniteTorpedoWeapon
local CAMZapperWeapon03 = CybranWeaponsFile.CAMZapperWeapon03
       
---@class URS0302 : CSeaUnit
URS0302 = ClassUnit(CSeaUnit) {
    Weapons = {
        FrontCannon01 = ClassWeapon(CDFProtonCannonWeapon) {},
        BackCannon01 = ClassWeapon(CDFProtonCannonWeapon) {},
        Torpedo01 = ClassWeapon(CANNaniteTorpedoWeapon) {},
        Torpedo02 = ClassWeapon(CANNaniteTorpedoWeapon) {},
        AAGun01 = ClassWeapon(CAAAutocannon) {},
        AAGun02 = ClassWeapon(CAAAutocannon) {},
        LeftZapper = ClassWeapon(CAMZapperWeapon03) {},
        RightZapper = ClassWeapon(CAMZapperWeapon03) {},
    },
}
TypeClass = URS0302