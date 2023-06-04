--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB3101/UAB3101_script.lua
--**  Author(s):  David Tomandl
--**
--**  Summary  :  Aeon Radar Tower Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local ARadarUnit = import("/lua/aeonunits.lua").ARadarUnit

---@class UAB3101 : ARadarUnit
UAB3101 = ClassUnit(ARadarUnit) {    
    OnIntelDisabled = function(self, intel)
        ARadarUnit.OnIntelDisabled(self, intel)
        self.Rotator1:SetSpinDown(true)
    end,

    OnIntelEnabled = function(self, intel)
        ARadarUnit.OnIntelEnabled(self, intel)
        if not self.Rotator1 then
            self.Rotator1 = CreateRotator(self, 'B01', 'y')
            self.Trash:Add(self.Rotator1)
        end
        self.Rotator1:SetSpinDown(false)
        self.Rotator1:SetTargetSpeed(30)
        self.Rotator1:SetAccel(20)
    end,
}

TypeClass = UAB3101