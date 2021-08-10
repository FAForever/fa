#****************************************************************************
#**
#**  File     :  /units/XSB0102/XSB0102_script.lua
#**
#**  Summary  :  Seraphim T1 Air FactoryScript
#**
#**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local SAirFactoryUnit = import('/lua/seraphimunits.lua').SAirFactoryUnit

XSB0102 = Class(SAirFactoryUnit) {

    RollOffBones = { 'Pod01',},

    
    OnCreate = function(self)
        SAirFactoryUnit.OnCreate(self)
        self.Rotator1 = CreateRotator(self, 'Pod01', 'y', nil, 5, 0, 0)
        self.Trash:Add(self.Rotator1)
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        self.Rotator1:SetSpeed(0)
        SAirFactoryUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

}

TypeClass = XSB0102
