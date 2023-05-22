--****************************************************************************
--**
--**  File     :  /cdimage/units/UAL0106/UAL0106_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Light Assault Bot Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AWalkingLandUnit = import("/lua/aeonunits.lua").AWalkingLandUnit
local ADFSonicPulsarWeapon = import("/lua/aeonweapons.lua").ADFSonicPulsarWeapon

---@class UAL0106 : AWalkingLandUnit
UAL0106 = ClassUnit(AWalkingLandUnit) {
    Weapons = {
        ArmLaserTurret = ClassWeapon(ADFSonicPulsarWeapon) {}
    },

}
TypeClass = UAL0106