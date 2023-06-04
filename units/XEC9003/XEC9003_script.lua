--****************************************************************************
--**
--**  File     :  /cdimage/units/XEC9003/XEC9003_script.lua
--**  Author(s):  Dru Staltman
--**
--**  Summary  :  Aeon Wall Piece Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TWallStructureUnit = import("/lua/terranunits.lua").TWallStructureUnit

---@class XEC9003 : TWallStructureUnit
XEC9003 = ClassUnit(TWallStructureUnit) {}

TypeClass = XEC9003