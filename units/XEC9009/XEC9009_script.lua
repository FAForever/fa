--****************************************************************************
--**
--**  File     :  /cdimage/units/XEC9009/XEC9009_script.lua
--**  Author(s):  Dru Staltman
--**
--**  Summary  :  Aeon Wall Piece Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TWallStructureUnit = import("/lua/terranunits.lua").TWallStructureUnit

---@class XEC9009 : TWallStructureUnit
XEC9009 = ClassUnit(TWallStructureUnit) {}

TypeClass = XEC9009