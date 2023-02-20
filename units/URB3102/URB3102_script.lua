--****************************************************************************
--**
--**  File     :  /cdimage/units/URB3102/URB3102_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Cybran Sonar Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CSonarUnit = import("/lua/cybranunits.lua").CSonarUnit

---@class URB3102 : CSonarUnit
URB3102 = ClassUnit(CSonarUnit) {
    TimedSonarTTIdleEffects = {
        {
            Bones = {
                'URB3102',
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

TypeClass = URB3102