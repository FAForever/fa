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
UAB1302 = ClassUnit(AMassCollectionUnit) {

    OnCreate = function(self)
        AMassCollectionUnit.OnCreate(self)
        self.ExtractionAnimManip = CreateAnimator(self)
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        local bp = self.Blueprint
        local trash = self.Trash

        self.ExtractionAnimManip:PlayAnim(bp.Display.AnimationActivate):SetRate(1)
        TrashBagAdd(trash,self.ExtractionAnimManip)
        AMassCollectionUnit.OnStopBeingBuilt(self, builder, layer)
        ChangeState(self, self.ActiveState)
    end,

    ActiveState = State {
        Main = function(self)
            local bp = self.Blueprint
            WaitFor(self.ExtractionAnimManip)
            while not self:IsDead() do
                self.ExtractionAnimManip:PlayAnim(bp.Display.AnimationActivate):SetRate(1)
                WaitFor(self.ExtractionAnimManip)
            end
        end,

        OnProductionPaused = function(self)
            AMassCollectionUnit.OnProductionPaused(self)
            ChangeState(self, self.InActiveState)
        end,
    },

    InActiveState = State {
        Main = function(self)
            WaitFor(self.ExtractionAnimManip)
            if self.ArmsUp == true then
                self.ExtractionAnimManip:SetRate(-1)
                WaitFor(self.ExtractionAnimManip)
                self.ArmsUp = false
            end
            WaitFor(self.ExtractionAnimManip)
        end,

        OnProductionUnpaused = function(self)
            AMassCollectionUnit.OnProductionUnpaused(self)
            ChangeState(self, self.ActiveState)
        end,
    },
}
TypeClass = UAB1302