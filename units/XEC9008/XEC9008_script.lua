--****************************************************************************
--**
--**  File     :  /cdimage/units/XEC9008/XEC9008_script.lua
--**  Author(s):  Dru Staltman
--**
--**  Summary  :  Aeon Wall Piece Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TWallStructureUnit = import("/lua/terranunits.lua").TWallStructureUnit

---@class XEC9008 : TWallStructureUnit
XEC9008 = ClassUnit(TWallStructureUnit) {}

TypeClass = XEC9008