--****************************************************************************
--**
--**  File     :  /cdimage/units/UEL0105/UEL0105_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Terran Tech 1 Engineer
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TConstructionUnit = import("/lua/terranunits.lua").TConstructionUnit

---@class UEL0105 : TConstructionUnit
UEL0105 = ClassUnit(TConstructionUnit) {}

TypeClass = UEL0105