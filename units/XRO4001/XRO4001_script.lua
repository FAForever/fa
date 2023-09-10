--****************************************************************************
--**
--**  File     :  /data/units/XRO4001/XRO4001_script.lua
--**  Author(s):  Jessica St. Croix
--**
--**  Summary  :  Dostya's Remains
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CWallStructureUnit = import("/lua/cybranunits.lua").CWallStructureUnit

---@class XRO4001 : CWallStructureUnit
XRO4001 = ClassUnit(CWallStructureUnit) {
    FxDamage1 = { },
    FxDamage2 = { },
    FxDamage3 = { },
}

TypeClass = XRO4001