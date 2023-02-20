--****************************************************************************
--**
--**  File     :  /cdimage/units/XEC9002/XEC9002_script.lua
--**  Author(s):  Dru Staltman
--**
--**  Summary  :  Aeon Wall Piece Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TWallStructureUnit = import("/lua/terranunits.lua").TWallStructureUnit

---@class XEC9002 : TWallStructureUnit
XEC9002 = ClassUnit(TWallStructureUnit) {}

TypeClass = XEC9002