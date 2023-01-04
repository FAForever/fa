--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB0101/UAB0101_script.lua
--**  Author(s):  David Tomandl, Gordon Duclos
--**
--**  Summary  :  Aeon Land Factory Tier 1 Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SLandFactoryUnit = import("/lua/seraphimunits.lua").SLandFactoryUnit

---@class XSB0101 : SLandFactoryUnit
XSB0101 = ClassUnit(SLandFactoryUnit) {
    OnCreate = function(self)
        SLandFactoryUnit.OnCreate(self)
        self.Rotator1 = CreateRotator(self, 'Pod01', 'y', nil, 5, 0, 0)
        self.Trash:Add(self.Rotator1)
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        self.Rotator1:SetSpeed(0)
        SLandFactoryUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

}

TypeClass = XSB0101