#****************************************************************************
#**
#**  File     :  /data/units/XSB3101/XSB3101_script.lua
#**  Author(s):  Jessica St. Croix
#**
#**  Summary  :  Seraphim T1 Radar Tower Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SRadarUnit = import('/lua/seraphimunits.lua').SRadarUnit

XSB3101 = Class(SRadarUnit) {

    OnIntelDisabled = function(self)
        SRadarUnit.OnIntelDisabled(self)
        
        self.Rotator1:SetSpinDown(true)
    end,

    OnIntelEnabled = function(self)
        SRadarUnit.OnIntelEnabled(self)
        
        if(not self.Rotator1) then
            self.Rotator1 = CreateRotator(self, 'Array', 'y')
            self.Trash:Add(self.Rotator1)
        end
        self.Rotator1:SetSpinDown(false)
        self.Rotator1:SetTargetSpeed(30)
        self.Rotator1:SetAccel(20)
    end,
}

TypeClass = XSB3101