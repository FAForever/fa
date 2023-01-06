--****************************************************************************
--**
--**  File     :  /cdimage/units/XEC9001/XEC9001_script.lua
--**  Author(s):  Dru Staltman
--**
--**  Summary  :  Aeon Wall Piece Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TWallStructureUnit = import("/lua/terranunits.lua").TWallStructureUnit

---@class XEC9001 : TWallStructureUnit
XEC9001 = ClassUnit(TWallStructureUnit) {}

TypeClass = XEC9001