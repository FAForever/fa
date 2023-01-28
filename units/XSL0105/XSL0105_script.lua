--****************************************************************************
--**
--**  File     :  /data/units/XSL0105/XSL0105_script.lua
--**  Author(s):  Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  Seraphim T1 Engineer Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SConstructionUnit = import("/lua/seraphimunits.lua").SConstructionUnit

---@class XSL0105 : SConstructionUnit
XSL0105 = ClassUnit(SConstructionUnit) {}

TypeClass = XSL0105