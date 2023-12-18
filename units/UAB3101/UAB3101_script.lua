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

-- upvalaue for perfomance
local CreateRotator = CreateRotator
local TrashBagAdd = TrashBag.Add

---@class UAB3101 : ARadarUnit
UAB3101 = ClassUnit(ARadarUnit) {

    ---@param self UAB3101
    ---@param intel any
    OnIntelDisabled = function(self, intel)
        ARadarUnit.OnIntelDisabled(self, intel)
        self.Rotator1:SetSpinDown(true)
    end,

    OnIntelEnabled = function(self, intel)
        local rotator = self.Rotator1
        local trash = self.Trash

        ARadarUnit.OnIntelEnabled(self, intel)
        if not rotator then
            rotator= CreateRotator(self, 'B01', 'y')
            TrashBagAdd(trash,rotator)
        end
        rotator:SetSpinDown(false)
        rotator:SetTargetSpeed(30)
        rotator:SetAccel(20)
    end,
}

TypeClass = UAB3101