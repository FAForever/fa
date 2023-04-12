-- File     :  /cdimage/units/URB1202/URB1202_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Tier 2 Mass Extractor Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local CMassCollectionUnit = import("/lua/cybranunits.lua").CMassCollectionUnit

---@class URB1202 : CMassCollectionUnit
---@field AnimationManipulator moho.AnimationManipulator
URB1202 = ClassUnit(CMassCollectionUnit) {
    OnStopBeingBuilt = function(self, builder, layer)
        CMassCollectionUnit.OnStopBeingBuilt(self, builder, layer)
        local audio = self.Blueprint.Audio.DoneBeingBuilt
        if audio then
            self:PlaySound(audio)
        end
    end,

    PlayActiveAnimation = function(self)
        CMassCollectionUnit.PlayActiveAnimation(self)

        local animationManipulator = self.AnimationManipulator
        if not animationManipulator then
            animationManipulator = CreateAnimator(self)
            self.Trash:Add(animationManipulator)
            self.AnimationManipulator = animationManipulator
        end

        animationManipulator:PlayAnim(self.Blueprint.Display.AnimationOpen, true)
    end,

    OnProductionPaused = function(self)
        CMassCollectionUnit.OnProductionPaused(self)
        local animationManipulator = self.AnimationManipulator
        if not animationManipulator then return end
        animationManipulator:SetRate(0)
    end,

    OnProductionUnpaused = function(self)
        CMassCollectionUnit.OnProductionUnpaused(self)
        local animationManipulator = self.AnimationManipulator
        if not animationManipulator then return end
        animationManipulator:SetRate(1)
    end,

}

TypeClass = URB1202
