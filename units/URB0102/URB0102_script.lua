--****************************************************************************
--**
--**  File     :  /cdimage/units/URB0102/URB0102_script.lua
--**  Author(s):  David Tomandl
--**
--**  Summary  :  Cybran Tier 1 Air Factory Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local CAirFactoryUnit = import("/lua/cybranunits.lua").CAirFactoryUnit

--Change by IceDreamer: Increased platform animation speed so roll-off time is the same as UEF Air Factory

---@class URB0102 : CAirFactoryUnit
URB0102 = Class(CAirFactoryUnit) {}

TypeClass = URB0102
