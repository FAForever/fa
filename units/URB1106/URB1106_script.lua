#****************************************************************************
#**
#**  File     :  /cdimage/units/URB1106/URB1106_script.lua
#**  Author(s):  Jessica St. Croix, David Tomandl
#**
#**  Summary  :  Cybran Mass Storage
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CMassStorageUnit = import('/lua/cybranunits.lua').CMassStorageUnit

URB1106 = Class(CMassStorageUnit) {
    OnStopBeingBuilt = function(self,builder,layer)
        CMassStorageUnit.OnStopBeingBuilt(self,builder,layer)
        self:ForkThread(self.AnimThread)
        local myBlueprint = self:GetBlueprint()
        if myBlueprint.Audio.Activate then
            self:PlaySound(myBlueprint.Audio.Activate)
        end
    end,

    AnimThread = function(self)
        local sliderManip = CreateStorageManip(self, 'B01', 'MASS', 0, 0, 0, 0, 0, .61)
    end,
}

TypeClass = URB1106