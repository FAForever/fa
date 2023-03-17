--****************************************************************************
--**
--**  File     :  /cdimage/units/UAL0111/UAL0111_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Mobile Missile Launcher Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local ALandUnit = import("/lua/aeonunits.lua").ALandUnit
local AIFMissileTacticalSerpentineWeapon = import("/lua/aeonweapons.lua").AIFMissileTacticalSerpentineWeapon

---@class UAL0111 : ALandUnit
UAL0111 = ClassUnit(ALandUnit) {
    Weapons = {
        MissileRack = ClassWeapon(AIFMissileTacticalSerpentineWeapon) {},
    },
}

TypeClass = UAL0111