--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB3102/UAB3102_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Light Sonar Installation Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local ASonarUnit = import("/lua/aeonunits.lua").ASonarUnit

---@class UAB3102 : ASonarUnit
UAB3102 = ClassUnit(ASonarUnit) {
    TimedSonarTTIdleEffects = {
        {
            Bones = {
                'Probe',
            },
            Type = 'SonarBuoy01',
        },
    },
}

TypeClass = UAB3102