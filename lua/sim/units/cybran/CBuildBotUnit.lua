--**********************************************************************************
--** Copyright (c) 2023 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--**********************************************************************************

local DummyUnit = import('/lua/sim/units/defaultunits.lua').DummyUnit

--- The build bot class for drones. It removes a lot of
-- the basic functionality of a unit to save on performance.
---@class CBuildBotUnit : DummyUnit
CBuildBotUnit = ClassDummyUnit(DummyUnit) {

    -- Keep track of the builder that made the bot
    SpawnedBy = false,

    --- only initialise what we need (drones typically have some aim functionality)
    ---@param self CBuildBotUnit
    OnPreCreate = function(self) 
        self.Trash = TrashBag()
    end,         

    --- only initialise what we need
    ---@param self CBuildBotUnit
    OnCreate = function(self)
        DummyUnit.OnCreate(self)

        -- prevent drone from consuming anything
        UnitSetConsumptionActive(self, false)
    end,

    --- short-cut when being destroyed
    ---@param self CBuildBotUnit
    OnDestroy = function(self) 
        self.Dead = true
        self.Trash:Destroy()

        if self.SpawnedBy then 
            self.SpawnedBy.BuildBotsNext = self.SpawnedBy.BuildBotsNext - 1
        end
    end,

    ---@param self CBuildBotUnit
    Kill = function(self)
        -- make it go boom
        if self.PlayDestructionEffects then
            self:CreateDestructionEffects(1.0)
        end

        self:Destroy()
    end,

    --- prevent this type of operations
    ---@param self CBuildBotUnit
    ---@param target Unit unused
    OnStartCapture = function(self, target)
        IssueStop({self}) -- You can't capture!
    end,
    
    ---@param self CBuildBotUnit
    ---@param target Unit unused
    OnStartReclaim = function(self, target)
        IssueStop({self}) -- You can't reclaim!
    end,

    --- short cut - just get destroyed
    ---@param self CBuildBotUnit
    ---@param with any unused
    OnImpact = function(self, with)

        -- make it go boom
        if self.PlayDestructionEffects then
            self:CreateDestructionEffects(1.0)
        end

        -- make it sound boom
        self:PlayUnitSound('Destroyed')

        -- make it gone
        self:Destroy()
    end,
}