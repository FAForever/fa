---------------------------------------------------------------------------
-- File     :  /cdimage/units/UEB2104/UEB2104_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  Terran Anti-Air Gun Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------
local TAmphibiousStructureUnit = import('/lua/terranunits.lua').TAmphibiousStructureUnit
local TAALinkedRailgun = import('/lua/terranweapons.lua').TAALinkedRailgun

UEB2104 = Class(TAmphibiousStructureUnit) {
    Weapons = {
        AAGun = Class(TAALinkedRailgun) {},
    },
}

TypeClass = UEB2104
