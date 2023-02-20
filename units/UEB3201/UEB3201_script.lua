--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB3201/UEB3201_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Long Range Radar Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TRadarUnit = import("/lua/terranunits.lua").TRadarUnit

---@class UEB3201 : TRadarUnit
---@field UpperRotator? moho.RotateManipulator
UEB3201 = ClassUnit(TRadarUnit) {

    ---@param self UEB3201
    OnIntelDisabled = function(self, intel)
        TRadarUnit.OnIntelDisabled(self, intel)
        if self.UpperRotator then
            self.UpperRotator:SetTargetSpeed(0)
        end 
    end,

    ---@param self UEB3201
    OnIntelEnabled = function(self, intel)
        TRadarUnit.OnIntelEnabled(self, intel)
        if not self.UpperRotator then
            self.UpperRotator = CreateRotator(self, 'Upper_Array', 'z')
            self.Trash:Add(self.UpperRotator)
        end
        self.UpperRotator:SetTargetSpeed(10)
        self.UpperRotator:SetAccel(5)
    end,

}
TypeClass = UEB3201