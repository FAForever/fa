--****************************************************************************
--**
--**  File     :  /cdimage/units/UAL0101/UAL0101_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Land Scout Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AHoverLandUnit = import("/lua/aeonunits.lua").AHoverLandUnit
local ADFLaserLightWeapon = import("/lua/aeonweapons.lua").ADFLaserLightWeapon

---@class UAL0101 : AHoverLandUnit
UAL0101 = ClassUnit(AHoverLandUnit) {
    Weapons = {
        LaserTurret = ClassWeapon(ADFLaserLightWeapon) {}
    },
}

TypeClass = UAL0101