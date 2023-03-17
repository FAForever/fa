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
local SeraphimWeapons = import("/lua/seraphimweapons.lua")
local SAAShleoCannonWeapon = SeraphimWeapons.SAAShleoCannonWeapon

---@class XSA0107 : AirTransport
XSA0107 = ClassUnit(AirTransport) {

    Weapons = {
        GuidanceSystem = ClassWeapon(DummyWeapon) {},
        AALeft = ClassWeapon(SAAShleoCannonWeapon) {},
    },

}

TypeClass = XSA0107
