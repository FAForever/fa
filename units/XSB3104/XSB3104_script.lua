--****************************************************************************
--**
--**  File     :  /data/units/XSB3104/XSB3104_script.lua
--**  Author(s):  Jessica St. Croix
--**
--**  Summary  :  Seraphim T3 Radar Tower Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SRadarUnit = import("/lua/seraphimunits.lua").SRadarUnit

---@class XSB3104 : SRadarUnit
XSB3104 = ClassUnit(SRadarUnit) {
    
    OnIntelDisabled = function(self, intel)
        SRadarUnit.OnIntelDisabled(self, intel)
    end,

    OnIntelEnabled = function(self, intel)
        SRadarUnit.OnIntelEnabled(self, intel)

        if(not self.Rotator1) then
            self.Rotator1 = CreateRotator(self, 'Array03', 'y')
            self.Trash:Add(self.Rotator1)
        end
        self.Rotator1:SetTargetSpeed(30)
        self.Rotator1:SetAccel(20)
        
        if(not self.Rotator2) then
            self.Rotator2 = CreateRotator(self, 'Array02', 'y')
            self.Trash:Add(self.Rotator2)
        end
        self.Rotator2:SetTargetSpeed(-20)
        self.Rotator2:SetAccel(20)
        
        if(not self.Rotator3) then
            self.Rotator3 = CreateRotator(self, 'Array01', 'y')
            self.Trash:Add(self.Rotator3)
        end
        self.Rotator3:SetTargetSpeed(10)
        self.Rotator3:SetAccel(20)
    end,
}

TypeClass = XSB3104