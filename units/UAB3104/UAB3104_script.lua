--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB3104/UAB3104_script.lua
--**  Author(s):  David Tomandl
--**
--**  Summary  :  Aeon Omni Sensor Suite Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local ARadarUnit = import("/lua/aeonunits.lua").ARadarUnit

-- upvalue for perfomance
local CreateRotator = CreateRotator
local TrashBagAdd = TrashBag.Add

---@class UAB3104 : ARadarUnit
UAB3104 = ClassUnit(ARadarUnit) {

    OnIntelDisabled = function(self, intel)
        ARadarUnit.OnIntelDisabled(self, intel)
        self.Rotator1:SetSpinDown(true)
        self.Rotator2:SetSpinDown(true)
        self.Rotator3:SetSpinDown(true)
    end,


    OnIntelEnabled = function(self, intel)
        ARadarUnit.OnIntelEnabled(self, intel)
        local rotator1 = self.Rotator1
        local rotator2 = self.Rotator2
        local rotator3 = self.Rotator3
        local trash = self.Trash

        if not rotator1 then
            rotator1 = CreateRotator(self, 'B03', 'y')
            TrashBagAdd(trash,rotator1)
        end
        rotator1:SetSpinDown(false)
        rotator1:SetTargetSpeed(30)
        rotator1:SetAccel(20)

        if not rotator2 then
            rotator2 = CreateRotator(self, 'B02', 'y')
            TrashBagAdd(trash,rotator2)
        end
        rotator2:SetSpinDown(false)
        rotator2:SetTargetSpeed(60)
        rotator2:SetAccel(20)

        if not rotator3 then
            rotator3 = CreateRotator(self, 'B01', 'y')
            TrashBagAdd(trash,rotator3)
        end
        rotator3:SetSpinDown(false)
        rotator3:SetTargetSpeed(120)
        rotator3:SetAccel(20)
    end,

}

TypeClass = UAB3104