--****************************************************************************
--**
--**  File     :  /cdimage/units/UAL0202/UAL0202_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  Aeon Heavy Tank Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local ALandUnit = import("/lua/aeonunits.lua").ALandUnit
local ADFCannonQuantumWeapon = import("/lua/aeonweapons.lua").ADFCannonQuantumWeapon

---@class UAL0202 : ALandUnit
UAL0202 = ClassUnit(ALandUnit) {

    Weapons = {
        MainGun = ClassWeapon(ADFCannonQuantumWeapon) {}
    },
    
}
TypeClass = UAL0202