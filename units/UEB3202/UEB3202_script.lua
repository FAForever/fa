--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB3202/UEB3202_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Long Range Sonar Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TSonarUnit = import("/lua/terranunits.lua").TSonarUnit

---@class UEB3202 : TSonarUnit
UEB3202 = ClassUnit(TSonarUnit) {
    TimedSonarTTIdleEffects = {
        {
            Bones = {
                'UEB3202',
            },
            Offset = {
                0,
                -1.3,
                0,
            },
            Type = 'SonarBuoy01',
        },
    },
}

TypeClass = UEB3202