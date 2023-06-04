-- ****************************************************************************
-- **
-- **  File     :  /cdimage/units/UAA0107/UAA0107_script.lua
-- **  Author(s):  John Comes
-- **
-- **  Summary  :  Aeon T1 Transport Script
-- **
-- **  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local AirTransport = import("/lua/defaultunits.lua").AirTransport
local DummyWeapon = import("/lua/aeonweapons.lua").AAASonicPulseBatteryWeapon

---@class XSA0107 : AirTransport
XSA0107 = ClassUnit(AirTransport) {

    Weapons = {
        GuidanceSystem = ClassWeapon(DummyWeapon) {},
    },

}

TypeClass = XSA0107
