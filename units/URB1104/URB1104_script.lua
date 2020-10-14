#****************************************************************************
#**
#**  File     :  /cdimage/units/URB1104/URB1104_script.lua
#**  Author(s):  Jessica St. Croix, David Tomandl
#**
#**  Summary  :  Cybran Mass Fabricator
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local CMassFabricationUnit = import('/lua/cybranunits.lua').CMassFabricationUnit

URB1104 = Class(CMassFabricationUnit) {
    DestructionPartsLowToss = {'Blade',},

    OnStopBeingBuilt = function(self,builder,layer)
        CMassFabricationUnit.OnStopBeingBuilt(self,builder,layer)
        self.Rotator = CreateRotator(self, 'Blade', 'z')
        self.Trash:Add(self.Rotator)
        self.Rotator:SetAccel(40)
        self.Rotator:SetTargetSpeed(150)
    end,
    
    OnProductionUnpaused = function(self)
        CMassFabricationUnit.OnProductionUnpaused(self)
        self.Rotator:SetTargetSpeed(150)
    end,
    
    OnProductionPaused = function(self)
        CMassFabricationUnit.OnProductionPaused(self)
        self.Rotator:SetTargetSpeed(0)
    end,
}

TypeClass = URB1104