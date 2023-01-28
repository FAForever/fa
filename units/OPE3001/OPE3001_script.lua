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
OPE3001 = ClassUnit(TWallStructureUnit) {
    FxDamage1 = import("/lua/effecttemplates.lua").NoEffects,
    FxDamage2 = import("/lua/effecttemplates.lua").NoEffects,
    FxDamage3 = import("/lua/effecttemplates.lua").NoEffects,
}

TypeClass = OPE3001