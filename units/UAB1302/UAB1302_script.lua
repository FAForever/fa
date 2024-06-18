-- File     :  /cdimage/units/UAB1202/UAB1202_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Aeon Tier 2 Mass Extractor Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local AMassCollectionUnit = import("/lua/aeonunits.lua").AMassCollectionUnit

-- upvalue for perfomance
local TrashBagAdd = TrashBag.Add
local Waitfor = WaitFor


---@class UAB1302 : AMassCollectionUnit
---@field ExtractionAnimManip moho.AnimationManipulator
---@field ArmsUp boolean
UAB1302 = ClassUnit(AMassCollectionUnit) {

    OnCreate = function(self)
        AMassCollectionUnit.OnCreate(self)
        self.ExtractionAnimManip = CreateAnimator(self)
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        local animationActivate = self.Blueprint.Display.AnimationActivate
        local trash = self.Trash
        local extractionAnimManip = self.ExtractionAnimManip

        extractionAnimManip:PlayAnim(animationActivate):SetRate(1)
        TrashBagAdd(trash, extractionAnimManip)
        AMassCollectionUnit.OnStopBeingBuilt(self, builder, layer)
        ChangeState(self, self.ActiveState)
    end,

    ActiveState = State {
        Main = function(self)
            local animationActivate = self.Blueprint.Display.AnimationActivate
            local extractionAnimManip = self.ExtractionAnimManip

            WaitFor(extractionAnimManip)
            while not self:IsDead() do
                self.ExtractionAnimManip:PlayAnim(animationActivate):SetRate(1)
                WaitFor(extractionAnimManip)
            end
        end,

        OnProductionPaused = function(self)
            AMassCollectionUnit.OnProductionPaused(self)
            ChangeState(self, self.InActiveState)
        end,
    },

    InActiveState = State {
        Main = function(self)
            local extractionAnimManip = self.ExtractionAnimManip

            WaitFor(extractionAnimManip)
            if self.ArmsUp == true then
                extractionAnimManip:SetRate(-1)
                WaitFor(extractionAnimManip)
                self.ArmsUp = false
            end
            WaitFor(extractionAnimManip)
        end,

        OnProductionUnpaused = function(self)
            AMassCollectionUnit.OnProductionUnpaused(self)
            ChangeState(self, self.ActiveState)
        end,
    },
}
TypeClass = UAB1302