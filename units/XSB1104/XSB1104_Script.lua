--****************************************************************************
--**
--**  File     :  /data/units/XSB1104/XSB1104_script.lua
--**  Author(s):  Jessica St. Croix
--**
--**  Summary  :  Seraphim Mass Fabricator
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SMassFabricationUnit = import('/lua/seraphimunits.lua').SMassFabricationUnit

XSB1104 = Class(SMassFabricationUnit) {

    OnCreate = function(self)
        SMassFabricationUnit.OnCreate(self)
        self.Trash:Add(self.Rotator)
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        SMassFabricationUnit.OnStopBeingBuilt(self,builder,layer)
        self.Rotator = CreateRotator(self, 'Blades', 'y', nil, 0, 50, 0)
        ChangeState(self, self.ActiveState)
    end,

    ActiveState = State {
        Main = function(self)
            -- guard for eco manager mod
            if self.isFinishedUnit then 
                self.Rotator:SetSpinDown(false)
                self.Rotator:SetTargetSpeed(180)
            end
        end,

        OnProductionPaused = function(self)
            SMassFabricationUnit.OnProductionPaused(self)
            ChangeState(self, self.InActiveState)
        end,
    },

    InActiveState = State {
        Main = function(self)
            -- guard for eco manager mod
            if self.isFinishedUnit then 
                self.Rotator:SetSpinDown(true)
                WaitFor(self.Rotator)
            end
        end,

        OnProductionUnpaused = function(self)
            SMassFabricationUnit.OnProductionUnpaused(self)
            ChangeState(self, self.ActiveState)
        end,
    },
}

TypeClass = XSB1104