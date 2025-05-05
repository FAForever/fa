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

local DebugComponent = import("/lua/shared/components/DebugComponent.lua").DebugComponent
local SyncGameResult = import("/lua/simsyncutils.lua").SyncGameResult

---@class AbstractVictoryCondition : DebugComponent, Destroyable
---@field Trash TrashBag
AbstractVictoryCondition = Class(DebugComponent) {

    ---@param self AbstractVictoryCondition
    __init = function(self)
        self.Trash = TrashBag()
    end,

    ---@param self AbstractVictoryCondition
    Destroy = function(self)
        self:OnDestroy()
    end,

    ---@param self AbstractVictoryCondition
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,

    --- A utility function that returns whether a unit is eligible to be considered in the game for the victory condition.
    ---@param self AbstractVictoryCondition
    ---@param unit Unit
    ---@return boolean
    UnitIsEligible = function(self, unit)

        -- this can happen occasionally, note that we explicitly do **not** use the `.Dead` property! The
        -- use of that property depends on the execution order in Lua. It is deterministic, but it will
        -- generate strange results when for example two ACUs die in the same tick. Using `.Dead` will
        -- re-introduce the 'draw bug' that bugged the community for years.

        if IsDestroyed(unit) then
            return false
        end

        -- only units that are finished are taken into account.

        if unit:GetFractionComplete() <= 1.0 then
            return false
        end

        -- only units that are not recalling are taken into account.

        if unit.RecallingAfterDefeat then
            return false
        end

        return true
    end,

    --- A utility function that returns whether the given brain has any eligible units of the given category.
    ---@param self AbstractVictoryCondition
    ---@param aiBrain AIBrain
    ---@param categories EntityCategory
    ---@return boolean
    BrainHasEligibleUnits = function(self, aiBrain, categories)
        local units = aiBrain:GetListOfUnits(categories, false)
        if (units) then
            for k = 1, table.getn(units) do
                local unit = units[k]
                if self:UnitIsEligible(unit) then
                    return true
                end
            end
        end

        return false
    end,

    --- A utility function that retrieves all brains that are still participating in the match.
    ---@param self AbstractVictoryCondition
    ---@return AIBrain[]
    GetArmyBrains = function(self)
        local participatingArmyBrains = {}
        for k, aiBrain in ArmyBrains do
            if not (ArmyIsOutOfGame(aiBrain:GetArmyIndex() or aiBrain:IsDefeated())) then
                table.insert(participatingArmyBrains, aiBrain)
            end
        end

        return participatingArmyBrains
    end,

    --- Utility function to help determine if all the given brains are allied and are requesting allied victory.
    ---@param self AbstractVictoryCondition
    ---@param aiBrains AIBrain[]
    ---@return boolean
    RemainingBrainsAreAllied = function(self, aiBrains)
        local victorious = true
        for a = 1, table.getn(aiBrains) do
            local aBrain = aiBrains[a]
            local aIndex = aBrain:GetArmyIndex()

            for b = 1, table.getn(aiBrains) do
                local bBrain = aiBrains[b]
                local bIndex = bBrain:GetArmyIndex()

                if aIndex ~= bIndex then
                    victorious = victorious and IsAlly(aIndex, bIndex) and aBrain.RequestingAlliedVictory and bBrain.RequestingAlliedVictory
                end
            end
        end

        return victorious
    end,

    --- Utility function to help determine if all the given brains want to draw.
    ---@param self AbstractVictoryCondition
    ---@param aiBrains AIBrain[]
    ---@return boolean
    RemainingBrainsForfeit = function(self, aiBrains)
        for k = 1, table.getn(aiBrains) do
            local brain = aiBrains[k]
            if not brain.OfferingDraw then
                return false
            end
        end

        return true
    end,

    ---@param self AbstractVictoryCondition
    Setup = function(self)
        self.Trash:Add(ForkThread(self.ProcessGameStateThread, self))
    end,

    ---@param self AbstractVictoryCondition
    ProcessGameStateThread = function(self)
        while not IsGameOver() do
            self:ProcessGameState(ArmyBrains)
            WaitTicks(4)
        end
    end,

    ---@param self AbstractVictoryCondition
    ---@param aiBrains AIBrain[]
    ProcessGameState = function(self, aiBrains)
        error("Missing implementation of ProcessGameState")
    end,

    --- Ends the game.
    ---@param self AbstractVictoryCondition
    EndGame = function(self)
        self.Trash:Add(ForkThread(self.EndGameThread, self))
    end,

    --- Ends the game.
    ---@param self AbstractVictoryCondition
    EndGameThread = function(self)
        WaitTicks(30)

        for _, v in GameOverListeners do
            pcall(v)
        end

        Sync.GameEnded = true
        WaitTicks(1)
        EndGame()
    end,

    --- Utility function for the logic to remove an army from the game by turning it into an observer.
    ---@param self AbstractVictoryCondition
    ---@param aiBrain AIBrain
    ToObserver = function(self, aiBrain)
        local brainIndex = aiBrain:GetArmyIndex()
        SetArmyOutOfGame(brainIndex)
    end,

    --- Processes the army as if it forfeit/drew.
    ---@param self AbstractVictoryCondition
    ---@param aiBrain AIBrain
    DrawForArmy = function(self, aiBrain)
        self:ToObserver(aiBrain)
        aiBrain:OnDraw()

        local brainIndex = aiBrain:GetArmyIndex()
        SyncGameResult({ brainIndex, "victory 10" })
    end,

    --- Processes the army as if it was victorious.
    ---@param self AbstractVictoryCondition
    ---@param aiBrain AIBrain
    VictoryForArmy = function(self, aiBrain)
        self:ToObserver(aiBrain)
        aiBrain:OnVictory()

        local brainIndex = aiBrain:GetArmyIndex()
        SyncGameResult({ brainIndex, "victory 10" })
    end,

    --- Processes the army as if it was defeated.
    ---@param self AbstractVictoryCondition
    ---@param aiBrain AIBrain
    DefeatForArmy = function(self, aiBrain)
        self:ToObserver(aiBrain)
        aiBrain:OnDefeat()

        local brainIndex = aiBrain:GetArmyIndex()
        SyncGameResult({ brainIndex, "victory 10" })
    end,

}
