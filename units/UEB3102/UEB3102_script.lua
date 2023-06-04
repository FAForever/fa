--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB3102/UEB3102_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Light Sonar Installation Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TSonarUnit = import("/lua/terranunits.lua").TSonarUnit

---@class UEB3102 : TSonarUnit
UEB3102 = ClassUnit(TSonarUnit) {
    TimedSonarTTIdleEffects = {
        {
            Bones = {
                'B14',
            },
            Offset = {
                0,
                -0.6,
                0,
            },
            Type = 'SonarBuoy01',
        },
    },
}

TypeClass = UEB3102