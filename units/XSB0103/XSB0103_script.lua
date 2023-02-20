--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB0103/UAB0103_script.lua
--**  Author(s):  John Comes, David Tomandl, Gordon Duclos
--**
--**  Summary  :  Aeon Unit Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SSeaFactoryUnit = import("/lua/seraphimunits.lua").SSeaFactoryUnit
---@class XSB0103 : SSeaFactoryUnit
XSB0103 = ClassUnit(SSeaFactoryUnit) {
    OnCreate = function(self)
        SSeaFactoryUnit.OnCreate(self)
        self.Rotator1 = CreateRotator(self, 'Pod01', 'y', nil, 5, 0, 0)
        self.Trash:Add(self.Rotator1)
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        self.Rotator1:SetSpeed(0)
        SSeaFactoryUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

}

TypeClass = XSB0103
