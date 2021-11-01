#****************************************************************************
#**
#**  File     :  /cdimage/units/UEB1103/UEB1103_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  UEF Tier 1 Mass Extractor Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

-- Automatically upvalued moho functions for performance
local CAnimationManipulatorMethods = _G.moho.AnimationManipulator
local CAnimationManipulatorMethodsPlayAnim = CAnimationManipulatorMethods.PlayAnim
local CAnimationManipulatorMethodsSetRate = CAnimationManipulatorMethods.SetRate
-- End of automatically upvalued moho functions

local TMassCollectionUnit = import('/lua/terranunits.lua').TMassCollectionUnit

UEB1103 = Class(TMassCollectionUnit)({

    OnStartBuild = function(self, unitBeingBuilt, order)
        TMassCollectionUnit.OnStartBuild(self, unitBeingBuilt, order)
        if not self.AnimationManipulator then
            return
        end
        CAnimationManipulatorMethodsSetRate(self.AnimationManipulator, 0)
        self.AnimationManipulator:Destroy()
        self.AnimationManipulator = nil
    end,

    PlayActiveAnimation = function(self)
        TMassCollectionUnit.PlayActiveAnimation(self)
        if not self.AnimationManipulator then
            self.AnimationManipulator = CreateAnimator(self)
            self.Trash:Add(self.AnimationManipulator)
        end
        CAnimationManipulatorMethodsPlayAnim(self.AnimationManipulator, self:GetBlueprint().Display.AnimationOpen, true)
    end,

    OnProductionPaused = function(self)
        TMassCollectionUnit.OnProductionPaused(self)
        if not self.AnimationManipulator then
            return
        end
        CAnimationManipulatorMethodsSetRate(self.AnimationManipulator, 0)
    end,

    OnProductionUnpaused = function(self)
        TMassCollectionUnit.OnProductionUnpaused(self)
        if not self.AnimationManipulator then
            return
        end
        CAnimationManipulatorMethodsSetRate(self.AnimationManipulator, 1)
    end,
})

TypeClass = UEB1103