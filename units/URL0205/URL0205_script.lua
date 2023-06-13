--****************************************************************************
--**
--**  File     :  /cdimage/units/URL0205/URL0205_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Mobile Flak Artillery Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CLandUnit = import("/lua/cybranunits.lua").CLandUnit
local CAABurstCloudFlakArtilleryWeapon = import("/lua/cybranweapons.lua").CAABurstCloudFlakArtilleryWeapon

---@class URL0205 : CLandUnit
URL0205 = ClassUnit(CLandUnit) {
    DestructionPartsLowToss = {'Turret',},

    Weapons = {
        AAGun = ClassWeapon(CAABurstCloudFlakArtilleryWeapon) {},
    },
}

TypeClass = URL0205