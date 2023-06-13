--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB3202/UAB3202_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Long Range Sonar Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local ASonarUnit = import("/lua/aeonunits.lua").ASonarUnit

---@class UAB3202 : ASonarUnit
UAB3202 = ClassUnit(ASonarUnit) {
    TimedSonarTTIdleEffects = {
        {
            Bones = {
                'Probe',
            },
            Type = 'SonarBuoy01',
        },
    },
}

TypeClass = UAB3202