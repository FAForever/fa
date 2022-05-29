#****************************************************************************
#**
#**  File     :  /cdimage/units/UAB3104/UAB3104_script.lua
#**  Author(s):  David Tomandl
#**
#**  Summary  :  Aeon Omni Sensor Suite Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local ARadarUnit = import('/lua/aeonunits.lua').ARadarUnit

UAB3104 = Class(ARadarUnit) {
    
    OnIntelDisabled = function(self)
        ARadarUnit.OnIntelDisabled(self)
        self.Rotator1:SetSpinDown(true)
        self.Rotator2:SetSpinDown(true)
        self.Rotator3:SetSpinDown(true)
    end,


    OnIntelEnabled = function(self)
        ARadarUnit.OnIntelEnabled(self)

        if not self.Rotator1 then
            self.Rotator1 = CreateRotator(self, 'B03', 'y')
            self.Trash:Add(self.Rotator1)
        end
        self.Rotator1:SetSpinDown(false)
        self.Rotator1:SetTargetSpeed(30)
        self.Rotator1:SetAccel(20)

        if not self.Rotator2 then
            self.Rotator2 = CreateRotator(self, 'B02', 'y')
            self.Trash:Add(self.Rotator2)
        end
        self.Rotator2:SetSpinDown(false)
        self.Rotator2:SetTargetSpeed(60)
        self.Rotator2:SetAccel(20)

        if not self.Rotator3 then
            self.Rotator3 = CreateRotator(self, 'B01', 'y')
            self.Trash:Add(self.Rotator3)
        end
        self.Rotator3:SetSpinDown(false)
        self.Rotator3:SetTargetSpeed(120)
        self.Rotator3:SetAccel(20)
    end,

}

TypeClass = UAB3104