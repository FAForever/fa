--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB3201/UAB3201_script.lua
--**  Author(s):  David Tomandl
--**
--**  Summary  :  Aeon Long Range Radar Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local ARadarUnit = import("/lua/aeonunits.lua").ARadarUnit

-- upvalue for performance
local CreateRotator = CreateRotator
local TrashBagAdd = TrashBag.Add

---@class UAB3201 : ARadarUnit
UAB3201 = ClassUnit(ARadarUnit) {

    OnIntelDisabled = function(self, intel)
        ARadarUnit.OnIntelDisabled(self, intel)
        local rotator1 = self.Rotator1
        local rotator2 = self.Rotator2

        rotator1:SetSpinDown(true)
        rotator1:SetAccel(60)
        rotator2:SetSpinDown(true)
        rotator2:SetAccel(60)
    end,

    OnIntelEnabled = function(self, intel)
        ARadarUnit.OnIntelEnabled(self, intel)
        local rotator1 = self.Rotator1
        local rotator2 = self.Rotator2
        local trash = self.Trash

        if not rotator1 then
            rotator1 = CreateRotator(self, 'B02', 'y')
            TrashBagAdd(trash,rotator1)
        end
        rotator1:SetSpinDown(false)
        rotator1:SetTargetSpeed(30)
        rotator1:SetAccel(20)


        if not rotator2 then
            rotator2 = CreateRotator(self, 'B01', 'y')
            TrashBagAdd(trash,rotator2)
        end
        rotator2:SetSpinDown(false)
        rotator2:SetTargetSpeed(60)
        rotator2:SetAccel(20)
    end,
}

TypeClass = UAB3201