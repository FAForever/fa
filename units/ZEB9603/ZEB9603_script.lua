--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB0303/UEB0303_script.lua
--**  Author(s):  David Tomandl
--**
--**  Summary  :  UEF Tier 3 Naval Factory Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TSeaFactoryUnit = import('/lua/terranunits.lua').TSeaFactoryUnit

UEB0303 = Class(TSeaFactoryUnit) {
    OnCreate = function(self)
        TSeaFactoryUnit.OnCreate(self)
        self.BuildPointSlider = CreateSlider(self, self:GetBlueprint().Display.BuildAttachBone or 0, -15, 0, 0, -1)
        self.Trash:Add(self.BuildPointSlider)
    end,
}

TypeClass = UEB0303
