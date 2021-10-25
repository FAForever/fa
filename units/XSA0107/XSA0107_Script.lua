-- ****************************************************************************
-- **
-- **  File     :  /cdimage/units/UAA0107/UAA0107_script.lua
-- **  Author(s):  John Comes
-- **
-- **  Summary  :  Aeon T1 Transport Script
-- **
-- **  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local AirTransport = import('/lua/defaultunits.lua').AirTransport
local DummyWeapon = import('/lua/aeonweapons.lua').AAASonicPulseBatteryWeapon

XSA0107 = Class(AirTransport) {

    Weapons = {
        GuidanceSystem = Class(DummyWeapon) {},
    },

}

TypeClass = XSA0107
