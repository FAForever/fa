--****************************************************************************
--**
--**  File     :  /cdimage/units/URA0303/URA0303_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Air Superiority Fighter Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CAirUnit = import("/lua/cybranunits.lua").CAirUnit
local CAAMissileNaniteWeapon = import("/lua/cybranweapons.lua").CAAMissileNaniteWeapon

---@class URA0303 : CAirUnit
URA0303 = ClassUnit(CAirUnit) {
    ExhaustBones = { 'Exhaust', },
    ContrailBones = { 'Contrail_L', 'Contrail_R', },
    Weapons = {
        Missiles1 = ClassWeapon(CAAMissileNaniteWeapon) {},
        Missiles2 = ClassWeapon(CAAMissileNaniteWeapon) {},
    },
    
}

TypeClass = URA0303
