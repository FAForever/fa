--****************************************************************************
--**
--**  File     :  /cdimage/units/UEL0205/UEL0205_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Mobile Flak Artillery Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TLandUnit = import("/lua/terranunits.lua").TLandUnit
local TAAFlakArtilleryCannon = import("/lua/terranweapons.lua").TAAFlakArtilleryCannon

---@class UEL0205 : TLandUnit
UEL0205 = ClassUnit(TLandUnit) {
    Weapons = {
        AAGun = ClassWeapon(TAAFlakArtilleryCannon) {},
    },
}

TypeClass = UEL0205