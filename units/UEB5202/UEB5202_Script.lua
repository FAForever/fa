--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB5202/UEB5202_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  UEF Air Staging Platform
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TAirStagingPlatformUnit = import("/lua/terranunits.lua").TAirStagingPlatformUnit

---@class UEB5202 : TAirStagingPlatformUnit
UEB5202 = ClassUnit(TAirStagingPlatformUnit) {}
TypeClass = UEB5202