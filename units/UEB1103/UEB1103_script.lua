--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB1103/UEB1103_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Tier 1 Mass Extractor Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TMassCollectionUnit = import("/lua/terranunits.lua").TMassCollectionUnit

-- upvalue for performance
local TrashBadAdd = TrashBag.Add


---@class UEB1103 : TMassCollectionUnit
UEB1103 = ClassUnit(TMassCollectionUnit) {

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
        local bp = self.Blueprint
        local animManip = self.AnimationManipulator

        if not animManip then
            animManip = CreateAnimator(self)
            TrashBadAdd(trash,animManip)
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

TypeClass = UEB1103