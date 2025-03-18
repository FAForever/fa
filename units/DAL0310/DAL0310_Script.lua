------------------------------------------------------------------------------
-- File     :  /cdimage/units/DAL0310/DAL0310_script.lua
-- Author(s):  Dru Staltman, Matt Vainio
-- Summary  :  Aeon Shield Disruptor Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------

--changes from ALandUnit to AHoverLandUnit
local AHoverLandUnit = import("/lua/aeonunits.lua").AHoverLandUnit
local ADFDisruptorCannonWeapon = import("/lua/aeonweapons.lua").ADFDisruptorWeapon

---@class DAL0310 : AHoverLandUnit
DAL0310 = ClassUnit(AHoverLandUnit) {
    Weapons = {
        MainGun = ClassWeapon(ADFDisruptorCannonWeapon) {}
    },
}
TypeClass = DAL0310

