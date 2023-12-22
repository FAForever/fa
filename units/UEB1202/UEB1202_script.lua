--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB1202/UEB1202_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Tier 2 Mass Extractor Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TMassCollectionUnit = import("/lua/terranunits.lua").TMassCollectionUnit

-- upvalue for perfomance
local TrashBagAdd = TrashBag.Add



---@class UEB1202 : TMassCollectionUnit
UEB1202 = ClassUnit(TMassCollectionUnit) {

    OnStartBuild = function(self, unitBeingBuilt, order)
        TMassCollectionUnit.OnStartBuild(self, unitBeingBuilt, order)
        local animManip = self.AnimationManipulator

        if not animManip then return end
        animManip:SetRate(0)
        animManip:Destroy()
        animManip = nil
    end,

    PlayActiveAnimation = function(self)
        TMassCollectionUnit.PlayActiveAnimation(self)
        local trash = self.Trash
        local animManip = self.AnimationManipulator
        local bp = self.Blueprint

        if not animManip then
            animManip = CreateAnimator(self)
            TrashBagAdd(trash,animManip)
        end
        animManip:PlayAnim(bp.Display.AnimationOpen, true)
    end,

    OnProductionPaused = function(self)
        TMassCollectionUnit.OnProductionPaused(self)
        local animManip = self.AnimationManipulator
        if not animManip then return end
        animManip:SetRate(0)
    end,

    OnProductionUnpaused = function(self)
        TMassCollectionUnit.OnProductionUnpaused(self)
        local animManip = self.AnimationManipulator
        if not animManip then return end
        animManip:SetRate(1)
    end,
}

TypeClass = UEB1202