#****************************************************************************
#**
#**  File     :  /cdimage/units/URB1202/URB1202_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Cybran Tier 2 Mass Extractor Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CMassCollectionUnit = import('/lua/cybranunits.lua').CMassCollectionUnit

URB1302 = Class(CMassCollectionUnit) {

    OnStopBeingBuilt = function(self,builder,layer)
        CMassCollectionUnit.OnStopBeingBuilt(self,builder,layer)
        self.AnimationManipulator = CreateAnimator(self)
        self.Trash:Add(self.AnimationManipulator)
        self.AnimationManipulator:PlayAnim(self:GetBlueprint().Display.AnimationOpen, true)
    end,
    
    OnStartBuild = function(self, unitBeingBuilt, order)
        CMassCollectionUnit.OnStartBuild(self, unitBeingBuilt, order)
        if not self.AnimationManipulator then return end
        self.AnimationManipulator:SetRate(0)
        self.AnimationManipulator:Destroy()
        self.AnimationManipulator = nil
    end,
    
    OnProductionPaused = function(self)
        CMassCollectionUnit.OnProductionPaused(self)
        if not self.AnimationManipulator then return end
        self.AnimationManipulator:SetRate(0)
    end,

    OnProductionUnpaused = function(self)
        CMassCollectionUnit.OnProductionUnpaused(self)
        if not self.AnimationManipulator then return end
        self.AnimationManipulator:SetRate(1)
    end,
}

TypeClass = URB1302