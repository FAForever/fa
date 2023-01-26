--****************************************************************************
--**
--**  File     :  /cdimage/units/OPE2001/OPE3001_script.lua
--**  Author(s):  Brian Fricks
--**
--**  Summary  :  Arnold's Black Box
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TWallStructureUnit = import("/lua/terranunits.lua").TWallStructureUnit

---@class OPE3001 : TWallStructureUnit
OPE3001 = Class(TWallStructureUnit) {
    FxDamage1 = {},
    FxDamage2 = {},
    FxDamage3 = {},
}

TypeClass = OPE3001