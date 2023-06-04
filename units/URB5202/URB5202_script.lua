--****************************************************************************
--**
--**  File     :  /cdimage/units/URB5202/URB5202_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Cybran Air Staging Platform
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CAirStagingPlatformUnit = import("/lua/cybranunits.lua").CAirStagingPlatformUnit

---@class URB5202 : CAirStagingPlatformUnit
URB5202 = ClassUnit(CAirStagingPlatformUnit) {
}

TypeClass = URB5202