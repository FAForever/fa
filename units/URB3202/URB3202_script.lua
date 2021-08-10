#****************************************************************************
#**
#**  File     :  /cdimage/units/URB3202/URB3202_script.lua
#**  Author(s):  John Comes
#**
#**  Summary  :  Cybran Long Range Sonar Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CSonarUnit = import('/lua/cybranunits.lua').CSonarUnit

URB3202 = Class(CSonarUnit) {
    TimedSonarTTIdleEffects = {
        {
            Bones = {
                'URB3202',
            },
            Offset = {
                0,
                -0.8,
                0,
            },
            Type = 'SonarBuoy01',
        },
    },
}

TypeClass = URB3202