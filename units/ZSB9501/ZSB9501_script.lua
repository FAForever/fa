-- File     :  /cdimage/units/UAB0201/UAB0201_script.lua
-- Author(s):  David Tomandl
-- Summary  :  Aeon Land Factory Tier 2 Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local SLandFactoryUnit = import("/lua/seraphimunits.lua").SLandFactoryUnit

---@class ZSB9501 : SLandFactoryUnit
ZSB9501 = ClassUnit(SLandFactoryUnit) {
    OnCreate = function(self)
        SLandFactoryUnit.OnCreate(self)
        self.Rotator1 = CreateRotator(self, 'Pod01', 'y', nil, 5, 0, 0)
        self.Trash:Add(self.Rotator1)
        self.Rotator2 = CreateRotator(self, 'Pod02', 'y', nil, 8, 0, 0)
        self.Trash:Add(self.Rotator2)
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        self.Rotator1:SetSpeed(0)
        self.Rotator2:SetSpeed(0)
        SLandFactoryUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

}

TypeClass = ZSB9501
