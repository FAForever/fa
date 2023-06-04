--****************************************************************************
--**
--**  File     :  /cdimage/units/XEC9010/XEC9010_script.lua
--**  Author(s):  Dru Staltman
--**
--**  Summary  :  Aeon Wall Piece Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TWallStructureUnit = import("/lua/terranunits.lua").TWallStructureUnit

---@class XEC9010 : TWallStructureUnit
XEC9010 = ClassUnit(TWallStructureUnit) {}

TypeClass = XEC9010