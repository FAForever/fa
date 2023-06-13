--****************************************************************************
--**
--**  File     :  /data/units/XSB3201/XSB3201_script.lua
--**  Author(s):  Jessica St. Croix
--**
--**  Summary  :  Seraphim T2 Radar Tower Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SRadarUnit = import("/lua/seraphimunits.lua").SRadarUnit

---@class XSB3201 : SRadarUnit
XSB3201 = ClassUnit(SRadarUnit) {

    OnIntelDisabled = function(self, intel)
        SRadarUnit.OnIntelDisabled(self, intel)
        if self.Rotator1 then
            self.Rotator1:SetSpinDown(true)
        end
        
        if self.Rotator2 then
            self.Rotator2:SetSpinDown(true)
        end
    end,

    OnIntelEnabled = function(self, intel)
        SRadarUnit.OnIntelEnabled(self, intel)

        if(not self.Rotator1) then
            self.Rotator1 = CreateRotator(self, 'Array01', 'y')
            self.Trash:Add(self.Rotator1)
        end            
        self.Rotator1:SetSpinDown(false)
        self.Rotator1:SetTargetSpeed(15)
        self.Rotator1:SetAccel(10)
        
        if(not self.Rotator2) then
            self.Rotator2 = CreateRotator(self, 'Array02', 'y')
            self.Trash:Add(self.Rotator2)
        end            
        self.Rotator2:SetSpinDown(false)
        self.Rotator2:SetTargetSpeed(30)
        self.Rotator2:SetAccel(20)
    end,
}

TypeClass = XSB3201