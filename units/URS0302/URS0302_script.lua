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
URS0302 = Class(CSeaUnit) {
    Weapons = {
        FrontCannon01 = Class(CDFProtonCannonWeapon) {},
        BackCannon01 = Class(CDFProtonCannonWeapon) {},
        Torpedo01 = Class(CANNaniteTorpedoWeapon) {},
        Torpedo02 = Class(CANNaniteTorpedoWeapon) {},
        AAGun01 = Class(CAAAutocannon) {},
        AAGun02 = Class(CAAAutocannon) {},
        LeftZapper = Class(CAMZapperWeapon03) {},
        RightZapper = Class(CAMZapperWeapon03) {},
    },
}
TypeClass = URS0302