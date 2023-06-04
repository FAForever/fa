--****************************************************************************
--**
--**  File     :  /cdimage/units/XEC9007/XEC9007_script.lua
--**  Author(s):  Dru Staltman
--**
--**  Summary  :  Aeon Wall Piece Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TWallStructureUnit = import("/lua/terranunits.lua").TWallStructureUnit

---@class XEC9007 : TWallStructureUnit
XEC9007 = ClassUnit(TWallStructureUnit) {}

TypeClass = XEC9007