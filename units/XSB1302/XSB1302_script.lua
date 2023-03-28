-- File     :  /cdimage/units/UAB1202/UAB1202_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Aeon Tier 2 Mass Extractor Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local SMassCollectionUnit = import("/lua/seraphimunits.lua").SMassCollectionUnit

---@class XSB1302 : SMassCollectionUnit
XSB1302 = ClassUnit(SMassCollectionUnit) {
    PlayActiveAnimation = function(self)
        SMassCollectionUnit.PlayActiveAnimation(self)
        if not self.AnimationManipulator then
            self.AnimationManipulator = CreateAnimator(self)
            self.Trash:Add(self.AnimationManipulator)
        end
        self.AnimationManipulator:PlayAnim(self.Blueprint.Display.AnimationActivate, true)
    end,

    OnProductionPaused = function(self)
        SMassCollectionUnit.OnProductionPaused(self)
        if not self.AnimationManipulator then return end
        self.AnimationManipulator:SetRate(0)
    end,

    OnProductionUnpaused = function(self)
        SMassCollectionUnit.OnProductionUnpaused(self)
        if not self.AnimationManipulator then return end
        self.AnimationManipulator:SetRate(1)
    end,
}

TypeClass = XSB1302
