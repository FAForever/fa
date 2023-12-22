--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB1302/UEB1302_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Tier 3 Mass Extractor Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TMassCollectionUnit = import("/lua/terranunits.lua").TMassCollectionUnit

-- Upvalue for performance
local CreateAnimator = CreateAnimator
local TrashBagAdd = TrashBag.Add


---@class UEB1302 : TMassCollectionUnit
UEB1302 = ClassUnit(TMassCollectionUnit) {

    PlayActiveAnimation = function(self)
        local bp = self.Blueprint
        local animManip = self.AnimationManipulator
        local trash = self.Trash

        TMassCollectionUnit.PlayActiveAnimation(self)
        if not animManip then
            animManip = CreateAnimator(self)
            TrashBagAdd(trash,animManip)
        end
        animManip:PlayAnim(bp.Display.AnimationOpen, true)
    end,

    OnStartBuild = function(self, unitBeingBuilt, order)
        TMassCollectionUnit.OnStartBuild(self, unitBeingBuilt, order)
        local animManip = self.AnimationManipulator
        if not animManip then return end
        animManip:SetRate(0)
        animManip:Destroy()
        animManip = nil
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

TypeClass = UEB1302