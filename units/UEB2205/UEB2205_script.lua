--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB2205/UEB2205_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Heavy Torpedo Launcher Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TStructureUnit = import("/lua/terranunits.lua").TStructureUnit
local TANTorpedoAngler = import("/lua/terranweapons.lua").TANTorpedoAngler

---@class UEB2205 : TStructureUnit
UEB2205 = ClassUnit(TStructureUnit) {
    Weapons = {
         Torpedo = ClassWeapon(TANTorpedoAngler) {
       },
    },
}

TypeClass = UEB2205