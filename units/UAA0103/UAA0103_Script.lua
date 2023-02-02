--****************************************************************************
--**
--**  File     :  /cdimage/units/UAA0103/UAA0103_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Bomber Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AAirUnit = import("/lua/aeonunits.lua").AAirUnit
local AIFBombGravitonWeapon = import("/lua/aeonweapons.lua").AIFBombGravitonWeapon

---@class UAA0103 : AAirUnit
UAA0103 = ClassUnit(AAirUnit) {
    Weapons = {
        Bomb = ClassWeapon(AIFBombGravitonWeapon) {},
    },
}

TypeClass = UAA0103

