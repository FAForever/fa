--****************************************************************************
--**
--**  File     :  /cdimage/units/ZEB9503/ZEB9503_script.lua
--**  Author(s):  David Tomandl
--**
--**  Summary  :  UEF Tier 2 Naval Factory Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TSeaFactoryUnit = import('/lua/terranunits.lua').TSeaFactoryUnit

ZEB9503 = Class(TSeaFactoryUnit) {
    OnCreate = function(self)
        TSeaFactoryUnit.OnCreate(self)
        self.BuildPointSlider = CreateSlider(self, self:GetBlueprint().Display.BuildAttachBone or 0, -5, 0, 0, -1)
        self.Trash:Add(self.BuildPointSlider)
    end,
}

TypeClass = ZEB9503
