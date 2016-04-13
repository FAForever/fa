--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB0203/UEB0203_script.lua
--**  Author(s):  David Tomandl
--**
--**  Summary  :  UEF Tier 2 Naval Factory Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TSeaFactoryUnit = import('/lua/terranunits.lua').TSeaFactoryUnit

UEB0203 = Class(TSeaFactoryUnit) {
    OnCreate = function(self)
        TSeaFactoryUnit.OnCreate(self)
        self.BuildPointSlider = CreateSlider(self, self:GetBlueprint().Display.BuildAttachBone or 0, -5, 0, 0, -1)
        self.Trash:Add(self.BuildPointSlider)
    end,
}

TypeClass = UEB0203
