-- File     :  /cdimage/units/UAB1103/UAB1103_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Aeon Mass Extractor Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local AMassCollectionUnit = import("/lua/aeonunits.lua").AMassCollectionUnit

-- upvalue for perfomance
local CreateAnimator = CreateAnimator
local TrashBagAdd = TrashBag.Add


---@class UAB1103 : AMassCollectionUnit
UAB1103 = ClassUnit(AMassCollectionUnit) {
    OnStartBuild = function(self, unitBeingBuilt, order)
        AMassCollectionUnit.OnStartBuild(self, unitBeingBuilt, order)
        if not self.AnimationManipulator then return end
        self.AnimationManipulator:SetRate(0)
        self.AnimationManipulator:Destroy()
        self.AnimationManipulator = nil
    end,

    PlayActiveAnimation = function(self)
        AMassCollectionUnit.PlayActiveAnimation(self)
        local trash = self.trash

        if not self.AnimationManipulator then
            self.AnimationManipulator = CreateAnimator(self)
            TrashBagAdd(trash,self.AnimationManipulator)
        end
        self.AnimationManipulator:PlayAnim(self.Blueprint.Display.AnimationActivate, true)
    end,

    OnProductionPaused = function(self)
        AMassCollectionUnit.OnProductionPaused(self)
        if not self.AnimationManipulator then return end
        self.AnimationManipulator:SetRate(0)
    end,

    OnProductionUnpaused = function(self)
        AMassCollectionUnit.OnProductionUnpaused(self)
        if not self.AnimationManipulator then return end
        self.AnimationManipulator:SetRate(1)
    end,
}


TypeClass = UAB1103