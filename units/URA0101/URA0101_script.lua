--****************************************************************************
--**
--**  File     :  /cdimage/units/URA0101/URA0101_script.lua
--**  Author(s):  David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Scout Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local CAirUnit = import("/lua/cybranunits.lua").CAirUnit

---@class URA0101 : CAirUnit
URA0101 = ClassUnit(CAirUnit) {}
TypeClass = URA0101