#****************************************************************************
#**
#**  File     :  /cdimage/units/UEB3201/UEB3201_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  UEF Long Range Radar Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local TRadarUnit = import('/lua/terranunits.lua').TRadarUnit

UEB3201 = Class(TRadarUnit) {

    OnIntelDisabled = function(self)
        TRadarUnit.OnIntelDisabled(self)
        self.UpperRotator:SetTargetSpeed(0)
    end,


    OnIntelEnabled = function(self)
        TRadarUnit.OnIntelEnabled(self)
        if not self.UpperRotator then
            self.UpperRotator = CreateRotator(self, 'Upper_Array', 'z')
            self.Trash:Add(self.UpperRotator)
        end
        self.UpperRotator:SetTargetSpeed(10)
        self.UpperRotator:SetAccel(5)
    end,

}
TypeClass = UEB3201