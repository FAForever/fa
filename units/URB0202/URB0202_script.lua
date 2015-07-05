#****************************************************************************
#**
#**  File     :  /cdimage/units/URB0202/URB0202_script.lua
#**  Author(s):  David Tomandl
#**
#**  Summary  :  Cybran Tier 2 Air Unit Factory Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local CAirFactoryUnit = import('/lua/cybranunits.lua').CAirFactoryUnit

URB0202 = Class(CAirFactoryUnit) {
    PlatformBone = 'B01',
    UpgradeRevealArm1 = 'Arm03',
    UpgradeRevealArm2 = 'Arm06',
    UpgradeBuilderArm1 = 'Arm03_B02',
    UpgradeBuilderArm2 = 'Arm04_B02',

}
TypeClass = URB0202