#****************************************************************************
#**
#**  File     :  /cdimage/units/UAB3102/UAB3102_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Aeon Light Sonar Installation Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SSonarUnit = import('/lua/seraphimunits.lua').SSonarUnit

XSB3102 = Class(SSonarUnit) {
    TimedSonarTTIdleEffects = {
        {
            Bones = {
                0,
            },
            Type = 'SonarBuoy01',
        },
    },
}

TypeClass = XSB3102