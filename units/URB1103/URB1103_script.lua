#****************************************************************************
#**
#**  File     :  /cdimage/units/URB1103/URB1103_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Cybran Tier 1 Mass Extractor Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CMassCollectionUnit = import('/lua/cybranunits.lua').CMassCollectionUnit

URB1103 = Class(CMassCollectionUnit) {
    OnStartBuild = function(self, unitBeingBuilt, order)
        CMassCollectionUnit.OnStartBuild(self, unitBeingBuilt, order)
        if not self.AnimationManipulator then return end
        self.AnimationManipulator:SetRate(0)
        self.AnimationManipulator:Destroy()
        self.AnimationManipulator = nil
    end,

    PlayActiveAnimation = function(self)
        CMassCollectionUnit.PlayActiveAnimation(self)
        if not self.AnimationManipulator then
            self.AnimationManipulator = CreateAnimator(self)
            self.Trash:Add(self.AnimationManipulator)
        end
        self.AnimationManipulator:PlayAnim(self:GetBlueprint().Display.AnimationOpen, true)
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

TypeClass = URB1103