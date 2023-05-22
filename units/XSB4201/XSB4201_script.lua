--****************************************************************************
--**
--**  File     :  /units/XSB4201/XSB4201_script.lua
--**
--**  Summary  :  Seraphim anti-TML Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SStructureUnit = import("/lua/seraphimunits.lua").SStructureUnit
local SAMElectrumMissileDefense = import("/lua/seraphimweapons.lua").SAMElectrumMissileDefense

---@class XSB4201 : SStructureUnit
XSB4201 = ClassUnit(SStructureUnit) {
    Weapons = {
        AntiMissile = ClassWeapon(SAMElectrumMissileDefense) {},
    },
}

TypeClass = XSB4201

