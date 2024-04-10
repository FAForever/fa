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
        local animManip = self.AnimationManipulator
        if animManip then
            animManip:SetRate(0)
            animManip:Destroy()
            self.AnimationManipulator = nil
        end
    end,

    PlayActiveAnimation = function(self)
        AMassCollectionUnit.PlayActiveAnimation(self)
        local trash = self.Trash

        local animManip = self.AnimationManipulator
        if not animManip then
            animManip = CreateAnimator(self)
            TrashBagAdd(trash, animManip)
            self.AnimationManipulator = animManip
        end
        
        animManip:PlayAnim(self.Blueprint.Display.AnimationActivate, true)
    end,

    OnProductionPaused = function(self)
        AMassCollectionUnit.OnProductionPaused(self)

        local animManip = self.AnimationManipulator
        if animManip then
            animManip:SetRate(0)
        end
    end,

    OnProductionUnpaused = function(self)
        AMassCollectionUnit.OnProductionUnpaused(self)

        local animManip = self.AnimationManipulator
        if animManip then
            animManip:SetRate(1)
        end
    end,
}


TypeClass = UAB1103