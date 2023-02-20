--****************************************************************************
--**
--**  File     :  /cdimage/units/XEC9005/XEC9005_script.lua
--**  Author(s):  Dru Staltman
--**
--**  Summary  :  Aeon Wall Piece Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TWallStructureUnit = import("/lua/terranunits.lua").TWallStructureUnit

---@class XEC9005 : TWallStructureUnit
XEC9005 = ClassUnit(TWallStructureUnit) {}

TypeClass = XEC9005