#****************************************************************************
#**
#**  File     :  /cdimage/units/URB0102/URB0102_script.lua
#**  Author(s):  David Tomandl
#**
#**  Summary  :  Cybran Tier 1 Air Factory Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local CAirFactoryUnit = import('/lua/cybranunits.lua').CAirFactoryUnit

URB0102 = Class(CAirFactoryUnit) {
    PlatformBone = 'B01',
    LandUnitBuilt = false,
    UpgradeRevealArm1 = 'Arm01',
    UpgradeRevealArm2 = 'Arm04',
    UpgradeBuilderArm1 = 'Arm01_B02',
    UpgradeBuilderArm2 = 'Arm02_B02',
}

TypeClass = URB0102