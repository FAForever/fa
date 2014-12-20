#****************************************************************************
#**
#**  File     :  /cdimage/units/ZRB9602/ZRB9602_script.lua
#**  Author(s):  David Tomandl
#**
#**  Summary  :  Cybran Tier 3 Air Unit Factory Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local CAirFactoryUnit = import('/lua/cybranunits.lua').CAirFactoryUnit

ZRB9602 = Class(CAirFactoryUnit) {
    PlatformBone = 'B01',
}

TypeClass = ZRB9602