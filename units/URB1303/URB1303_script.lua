--****************************************************************************
--**
--**  File     :  /cdimage/units/URB1303/URB1303_script.lua
--**  Author(s):  Jessica St. Croix, David Tomandl
--**
--**  Summary  :  Cybran T3 Mass Fabricator
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CMassFabricationUnit = import('/lua/cybranunits.lua').CMassFabricationUnit

URB1303 = Class(CMassFabricationUnit) {

    OnStopBeingBuilt = function(self,builder,layer)
        CMassFabricationUnit.OnStopBeingBuilt(self,builder,layer)
        self.Rotator = CreateRotator(self, 'Spinner', 'z')
        self.Rotator:SetAccel(10)
        self.Rotator:SetTargetSpeed(60)
        self.Trash:Add(self.Rotator)
    end,

    OnProductionUnpaused = function(self)
        -- guard for eco manager mod
        if self:GetFractionComplete() == 1.0 then 
            CMassFabricationUnit.OnProductionUnpaused(self)
            self.Rotator:SetTargetSpeed(60)
        end
    end,

    OnProductionPaused = function(self)
        -- guard for eco manager mod
        if self:GetFractionComplete() == 1.0 then 
            CMassFabricationUnit.OnProductionPaused(self)
            self.Rotator:SetTargetSpeed(0)
        end
    end,
}

TypeClass = URB1303