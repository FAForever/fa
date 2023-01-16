--****************************************************************************
--**
--**  File     :  /cdimage/units/XEC9004/XEC9004_script.lua
--**  Author(s):  Dru Staltman
--**
--**  Summary  :  Aeon Wall Piece Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TWallStructureUnit = import("/lua/terranunits.lua").TWallStructureUnit

---@class XEC9004 : TWallStructureUnit
XEC9004 = ClassUnit(TWallStructureUnit) {}

TypeClass = XEC9004