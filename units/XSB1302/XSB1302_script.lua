#****************************************************************************
#**
#**  File     :  /cdimage/units/UAB1202/UAB1202_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Aeon Tier 2 Mass Extractor Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SMassCollectionUnit = import('/lua/seraphimunits.lua').SMassCollectionUnit

XSB1302 = Class(SMassCollectionUnit) {

    OnCreate = function(self)
        SMassCollectionUnit.OnCreate(self)
        self.ExtractionAnimManip = CreateAnimator(self)
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        self.ExtractionAnimManip:PlayAnim(self:GetBlueprint().Display.AnimationActivate):SetRate(1)
        self.Trash:Add(self.ExtractionAnimManip)
        SMassCollectionUnit.OnStopBeingBuilt(self,builder,layer)
        ChangeState(self, self.ActiveState)
    end,

    ActiveState = State {
        Main = function(self)
            WaitFor(self.ExtractionAnimManip)
            while not self:IsDead() do
                
                self.ExtractionAnimManip:PlayAnim(self:GetBlueprint().Display.AnimationActivate):SetRate(1)
                WaitFor(self.ExtractionAnimManip)
            end
        end,

        OnProductionPaused = function(self)
            SMassCollectionUnit.OnProductionPaused(self)
            ChangeState(self, self.InActiveState)
        end,
    },

    InActiveState = State {
        Main = function(self)
            WaitFor(self.ExtractionAnimManip)
            if self.ArmsUp == true then
                self.ExtractionAnimManip:SetRate(-1)
                WaitFor(self.ExtractionAnimManip)
                self.ArmsUp = false
            end
            WaitFor(self.ExtractionAnimManip)
        end,

        OnProductionUnpaused = function(self)
            SMassCollectionUnit.OnProductionUnpaused(self)
            ChangeState(self, self.ActiveState)
        end,
    },
}

TypeClass = XSB1302
    
    
    