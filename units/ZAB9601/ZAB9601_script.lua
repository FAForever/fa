#****************************************************************************
#**
#**  File     :  /cdimage/units/ZAB9601/ZAB9601_script.lua
#**  Author(s):  David Tomandl
#**
#**  Summary  :  Aeon Land Factory Tier 3 Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local ALandFactoryUnit = import('/lua/aeonunits.lua').ALandFactoryUnit
local SupportFactoryUnit = import('/lua/defaultunits.lua').SupportFactoryUnit

ZAB9601 = Class(ALandFactoryUnit, SupportFactoryUnit) {}

TypeClass = ZAB9601
