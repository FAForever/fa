--#****************************************************************************
--#**
--#**  File     :  /cdimage/units/URB1303/URB1303_script.lua
--#**  Author(s):  Jessica St. Croix, David Tomandl
--#**
--#**  Summary  :  Cybran T3 Mass Fabricator
--#**
--#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--#****************************************************************************

local CMassFabricationUnit = import('/lua/cybranunits.lua').CMassFabricationUnit

URB1303 = Class(CMassFabricationUnit) {

    OnCreate = function(self)
        CMassFabricationUnit.OnCreate(self)
        self.Rotator = CreateRotator(self, 'Spinner', 'z')
        self.Trash:Add(self.Rotator)
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        CMassFabricationUnit.OnStopBeingBuilt(self, builder, layer)
        self.Rotator:SetAccel(10)
        self.Rotator:SetTargetSpeed(60)
    end,

    OnProductionUnpaused = function(self)
        CMassFabricationUnit.OnProductionUnpaused(self)
        self.Rotator:SetTargetSpeed(60)
    end,

    OnProductionPaused = function(self)
        CMassFabricationUnit.OnProductionPaused(self)
        self.Rotator:SetTargetSpeed(0)
    end,
}

TypeClass = URB1303