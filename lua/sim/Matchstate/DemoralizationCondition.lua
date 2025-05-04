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

local AbstractVictoryCondition = import("/lua/sim/Matchstate/AbstractVictoryCondition.lua").AbstractVictoryCondition

---@class DemoralizationCondition : AbstractVictoryCondition
---@field UnitCategories EntityCategory
DemoralizationCondition = Class(AbstractVictoryCondition) {

    UnitCategories = categories.COMMAND,

    ---@param self DemoralizationCondition
    ProcessGameState = function(self)
        -- see if there are defeated brains
        local aliveBrains = {}
        local defeatedBrains = {}
        local aiBrains = self:GetArmyBrains()
        for k = 1, table.getn(aiBrains) do
            local aiBrain = aiBrains[k]

            if not self:BrainHasFinishedUnitsOfCategory(aiBrain, self.UnitCategories) then
                table.insert(defeatedBrains, aiBrain)
            else
                table.insert(aliveBrains, aiBrain)
            end
        end

        -- process all defeated brains
        for k = 1, table.getn(defeatedBrains) do
            local defeatedBrain = defeatedBrains[k]
            self:DefeatForArmy(defeatedBrain)
        end

        -- check if all remaining players want to forfeit
        if self:RemainingBrainsForfeit(aliveBrains) then
            for k = 1, table.getn(aliveBrains) do
                local aliveBrain = aliveBrains[k]
                self:DrawForArmy(aliveBrain)
            end

            self:EndGame()
            return
        end

        -- check if all remaining players are allied
        if self:RemainingBrainsAreAllied(aliveBrains) then
            for k = 1, table.getn(aliveBrains) do
                local aliveBrain = aliveBrains[k]
                self:VictoryForArmy(aliveBrain)
            end

            self:EndGame()
            return
        end
    end,

}

---@return DemoralizationCondition
CreateDemoralizationCondition = function()
    return DemoralizationCondition()
end