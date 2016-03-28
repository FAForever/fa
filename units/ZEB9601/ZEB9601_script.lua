#****************************************************************************
#**
#**  File     :  /cdimage/units/ZEB9601/ZEB9601_script.lua
#**  Author(s):  David Tomandl
#**
#**  Summary  :  Terran Unit Script
#**
#**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local TLandFactoryUnit = import('/lua/terranunits.lua').TLandFactoryUnit
local SupportFactoryUnit = import('/lua/defaultunits.lua').SupportFactoryUnit

ZEB9601 = Class(TLandFactoryUnit, SupportFactoryUnit) {}

TypeClass = ZEB9601
