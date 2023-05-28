--****************************************************************************
--**
--**  File     :  /cdimage/units/UAL0201/UAL0201_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Light Tank Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AHoverLandUnit = import("/lua/aeonunits.lua").AHoverLandUnit
local ADFDisruptorCannonWeapon = import("/lua/aeonweapons.lua").ADFDisruptorCannonWeapon

---@class UAL0201 : AHoverLandUnit
UAL0201 = ClassUnit(AHoverLandUnit) {
    Weapons = {
        MainGun = ClassWeapon(ADFDisruptorCannonWeapon) {}
    },
}
TypeClass = UAL0201

