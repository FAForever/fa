--****************************************************************************
--**
--**  File     :  /cdimage/units/OPE2001/OPE2001_script.lua
--**  Author(s):  David Tomandl
--**
--**  Summary  :  Civilian Center for Operation E2
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TWallStructureUnit = import("/lua/terranunits.lua").TWallStructureUnit

---@class OPE2001 : TWallStructureUnit
OPE2001 = ClassUnit(TWallStructureUnit) {
}

TypeClass = OPE2001