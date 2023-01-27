-- File     :  /cdimage/units/UAA0107/UAA0107_script.lua
-- Author(s):  John Comes
-- Summary  :  Aeon T1 Transport Script
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local AirTransport = import("/lua/defaultunits.lua").AirTransport
local DummyWeapon = import("/lua/aeonweapons.lua").AAASonicPulseBatteryWeapon

---@class UAA0107 : AirTransport
UAA0107 = ClassUnit(AirTransport) {
    Weapons = {
        GuidanceSystem = ClassWeapon(DummyWeapon) {},
    },
}
TypeClass = UAA0107