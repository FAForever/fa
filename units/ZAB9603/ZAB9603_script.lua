-- File     :  /cdimage/units/ZAB9603/ZAB9603_script.lua
-- Author(s):  John Comes, David Tomandl, Gordon Duclos
-- Summary  :  Aeon Tier 3 Naval Factory Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local ASeaFactoryUnit = import("/lua/aeonunits.lua").ASeaFactoryUnit
---@class ZAB9603 : ASeaFactoryUnit
ZAB9603 = ClassUnit(ASeaFactoryUnit) {
    OnCreate = function(self)
        ASeaFactoryUnit.OnCreate(self)
        self.BuildPointSlider = CreateSlider(self, self.Blueprint.Display.BuildAttachBone or 0, -15, 0, 0, -1)
        self.Trash:Add(self.BuildPointSlider)
    end,
}

TypeClass = ZAB9603

