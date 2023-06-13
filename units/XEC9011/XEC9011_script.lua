--****************************************************************************
--**
--**  File     :  /cdimage/units/XEC9011/XEC9011_script.lua
--**  Author(s):  Dru Staltman
--**
--**  Summary  :  Aeon Wall Piece Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TWallStructureUnit = import("/lua/terranunits.lua").TWallStructureUnit

---@class XEC9011 : TWallStructureUnit
XEC9011 = ClassUnit(TWallStructureUnit) {}

TypeClass = XEC9011