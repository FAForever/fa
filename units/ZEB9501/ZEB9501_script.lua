#****************************************************************************
#**
#**  File     :  /cdimage/units/UEB0201/UEB0201_script.lua
#**  Author(s):  David Tomandl
#**
#**  Summary  :  UEF Tier 2 Land Factory Script
#**
#**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local TLandFactoryUnit = import('/lua/terranunits.lua').TLandFactoryUnit
local SupportFactoryUnit = import('/lua/defaultunits.lua').SupportFactoryUnit

UEB0201 = Class(TLandFactoryUnit, SupportFactoryUnit) {}

TypeClass = UEB0201
