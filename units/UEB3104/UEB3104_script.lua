--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB3104/UEB3104_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Omni Sensor Suite Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TRadarUnit = import("/lua/terranunits.lua").TRadarUnit

---@class UEB3104 : TRadarUnit
---@field UpperRotator? moho.RotateManipulator
---@field LowerRotator? moho.RotateManipulator
UEB3104 = ClassUnit(TRadarUnit) {

    ---@param self UEB3104
    OnIntelDisabled = function(self)
        TRadarUnit.OnIntelDisabled(self)
        if self.UpperRotator then
            self.UpperRotator:SetTargetSpeed(0)
        end
        if self.LowerRotator then 
            self.LowerRotator:SetTargetSpeed(0)
        end
    end,

    ---@param self UEB3104
    OnIntelEnabled = function(self)
        TRadarUnit.OnIntelEnabled(self)
        if not self.UpperRotator then
            self.UpperRotator = CreateRotator(self, 'Upper_Array', 'z')
            self.Trash:Add(self.UpperRotator)
            self.UpperRotator:SetAccel(5)
        end
        self.UpperRotator:SetTargetSpeed(10)
        
        if not self.LowerRotator then
            self.LowerRotator = CreateRotator(self, 'Lower_Array_Detail', 'z')
            self.Trash:Add(self.LowerRotator)
            self.LowerRotator:SetAccel(5)
        end
        self.LowerRotator:SetTargetSpeed(-10)
    end,
}

TypeClass = UEB3104