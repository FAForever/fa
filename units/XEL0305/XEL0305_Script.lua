--****************************************************************************
--**
--**  File     :  /cdimage/units/XEL0305/XEL0305_script.lua
--**
--**  Summary  :  UEF Siege Assault Bot Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TerranWeaponFile = import("/lua/terranweapons.lua")
local TWalkingLandUnit = import("/lua/terranunits.lua").TWalkingLandUnit
local TDFIonizedPlasmaCannon = TerranWeaponFile.TDFIonizedPlasmaCannon

---@class XEL0305 : TWalkingLandUnit
XEL0305 = ClassUnit(TWalkingLandUnit) {

    Weapons = {
        PlasmaCannon01 = ClassWeapon(TDFIonizedPlasmaCannon) {},
    },

}

TypeClass = XEL0305