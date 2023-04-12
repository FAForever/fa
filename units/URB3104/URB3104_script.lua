--****************************************************************************
--**
--**  File     :  /cdimage/units/URB3104/URB3104_script.lua
--**  Author(s):  David Tomandl
--**
--**  Summary  :  Cybran Omni Sensor Suite Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CRadarUnit = import("/lua/cybranunits.lua").CRadarUnit

---@class URB3104 : CRadarUnit
---@field MainRotator moho.RotateManipulator
URB3104 = ClassUnit(CRadarUnit) {

    ---@param self URB3104
    ---@param intel IntelType
    OnIntelDisabled = function(self, intel)
        CRadarUnit.OnIntelDisabled(self, intel)

        local mainRotator = self.MainRotator
        if mainRotator then
            self.MainRotator:SetTargetSpeed(0)
            self.MainRotator:SetAccel(1)
        end
    end,

    ---@param self URB3104
    ---@param intel IntelType
    OnIntelEnabled = function(self, intel)
        CRadarUnit.OnIntelEnabled(self, intel)

        local mainRotator = self.MainRotator
        if not mainRotator then
            mainRotator = CreateRotator(self, 'Spinner', 'z')
            self.MainRotator = mainRotator
            self.Trash:Add(mainRotator)
        end

        mainRotator:SetTargetSpeed(3)
        mainRotator:SetAccel(0.1)
    end,
}

TypeClass = URB3104
