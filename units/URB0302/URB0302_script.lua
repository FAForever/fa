#****************************************************************************
#**
#**  File     :  /cdimage/units/URB0302/URB0302_script.lua
#**  Author(s):  David Tomandl
#**
#**  Summary  :  Cybran Tier 3 Air Unit Factory Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local CAirFactoryUnit = import('/lua/cybranunits.lua').CAirFactoryUnit

URB0302 = Class(CAirFactoryUnit) {
    PlatformBone = 'B01',
}

TypeClass = URB0302