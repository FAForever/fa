--****************************************************************************
--**
--**  File     :  /cdimage/units/URA0103/URA0103_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Cybran Bomber Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CAirUnit = import("/lua/cybranunits.lua").CAirUnit
local CIFBombNeutronWeapon = import("/lua/cybranweapons.lua").CIFBombNeutronWeapon

---@class URA0103 : CAirUnit
URA0103 = ClassUnit(CAirUnit) {
    Weapons = {
        Bomb = ClassWeapon(CIFBombNeutronWeapon) {},
        },
    ExhaustBones = {'Exhaust_L','Exhaust_R',},
    ContrailBones = {'Contrail_L','Contrail_R',},
}

TypeClass = URA0103