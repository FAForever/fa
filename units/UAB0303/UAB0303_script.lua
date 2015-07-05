#****************************************************************************
#**
#**  File     :  /cdimage/units/UAB0303/UAB0303_script.lua
#**  Author(s):  John Comes, David Tomandl, Gordon Duclos
#**
#**  Summary  :  Aeon Tier 3 Naval Factory Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local ASeaFactoryUnit = import('/lua/aeonunits.lua').ASeaFactoryUnit
UAB0303 = Class(ASeaFactoryUnit) {    
    OnCreate = function(self)
        ASeaFactoryUnit.OnCreate(self)
        self.BuildPointSlider = CreateSlider(self, self:GetBlueprint().Display.BuildAttachBone or 0, -15, 0, 0, -1)
        self.Trash:Add(self.BuildPointSlider)
    end,
}

TypeClass = UAB0303

