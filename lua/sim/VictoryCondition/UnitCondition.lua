--******************************************************************************************************
--** Copyright (c) 2025 Willem 'Jip' Wijnia
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
--******************************************************************************************************

local AbstractVictoryCondition = import("/lua/sim/victorycondition/AbstractVictoryCondition.lua").AbstractVictoryCondition

-- upvalue for performance
local TableGetn = table.getn
local TableInsert = table.insert


---@class UnitCondition : AbstractVictoryCondition
---@operator call(EntityCategory): UnitCondition
---@field UnitCategories EntityCategory
UnitCondition = Class(AbstractVictoryCondition) {

    ---@param self UnitCondition
    ---@param unitCategories EntityCategory
    __init = function(self, unitCategories)
        AbstractVictoryCondition.__init(self)

        self.UnitCategories = unitCategories
    end,

    ---@param self UnitCondition
    EvaluateVictoryCondition = function(self)
        -- see if there are defeated brains
        local aliveBrains = {}
        local defeatedBrains = {}
        local aiBrains = self:GetEligibleArmyBrains()
        for k = 1, TableGetn(aiBrains) do
            local aiBrain = aiBrains[k]

            if not self:BrainHasEligibleUnits(aiBrain, self.UnitCategories) then
                TableInsert(defeatedBrains, aiBrain)
            else
                TableInsert(aliveBrains, aiBrain)
            end
        end

        -- defeated brains must be processed first to sync game results to be sent to server
        local numDefeated = TableGetn(defeatedBrains)
        if numDefeated > 0 then
            for k = 1, numDefeated do
                local defeatedBrain = defeatedBrains[k]
                self:DefeatForArmy(defeatedBrain)
            end
            -- Give other brains some time to be defeated for a draw
            WaitTicks(6) -- 6 ticks due to random 0-6 tick delay in Unit death thread
            return self:EvaluateVictoryCondition()
        end

        -- no remaining players, end the game as the conditions below require living players
        if table.empty(aliveBrains) then
            if self.EnabledSpewing then
                SPEW("All players are defeated, game will end")
            end

            self:EndGame()
            return
        end

        -- check if all remaining players want to forfeit
        if self:RemainingBrainsForfeit(aliveBrains) then
            if self.EnabledSpewing then
                SPEW("All remaining players want to forfeit, game will end")
            end

            for k = 1, TableGetn(aliveBrains) do
                local aliveBrain = aliveBrains[k]
                self:DrawForArmy(aliveBrain)
            end

            self:EndGame()
            return
        end

        -- check if all remaining players are allied
        if self:RemainingBrainsAreAllied(aliveBrains) then
            if self.EnabledSpewing then
                SPEW("All remaining players are allied, game will end")
            end

            for k = 1, TableGetn(aliveBrains) do
                local aliveBrain = aliveBrains[k]
                self:VictoryForArmy(aliveBrain)
            end

            self:EndGame()
            return
        end
    end,
}
