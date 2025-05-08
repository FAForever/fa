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

-- upvalue for performance
local TableGetn = table.getn
local TableInsert = table.insert

---@class AbstractVictoryCondition : DebugComponent, Destroyable
---@field Trash TrashBag
---@field ProcessGameStateThreadInstance? thread
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

        if unit:GetFractionComplete() < 1.0 then
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
        local units = aiBrain:GetListOfUnits(categories)
        if (units) then
            for k = 1, TableGetn(units) do
                local unit = units[k]
                if self:UnitIsEligible(unit) then
                    return true
                end
            end
        end

        return false
    end,

    --- A utility function that returns whether a brain is eligible to be considered for victory conditions.
    ---@param self AbstractVictoryCondition
    ---@param aiBrain AIBrain
    ---@return boolean
    BrainIsEligible = function(self, aiBrain)
        if aiBrain:IsDefeated() then
            return false
        end

        if ArmyIsCivilian(aiBrain.Army) then
            return false
        end

        return true
    end,

    --- A utility function that retrieves all brains that are still participating in the match.
    ---@param self AbstractVictoryCondition
    ---@return AIBrain[]
    GetEligibleArmyBrains = function(self)
        local participatingArmyBrains = {}
        for k, aiBrain in ArmyBrains do
            if self:BrainIsEligible(aiBrain) then
                TableInsert(participatingArmyBrains, aiBrain)
            end
        end

        return participatingArmyBrains
    end,

    --- Utility function to help determine if all the given brains are allied and are requesting allied victory.
    ---@param self AbstractVictoryCondition
    ---@param aiBrains AIBrain[]
    ---@return boolean
    RemainingBrainsAreAllied = function(self, aiBrains)
        -- defaults to false when no brains are provided
        if table.empty(aiBrains) then
            return false
        end

        local victorious = true
        for a = 1, TableGetn(aiBrains) do
            local aBrain = aiBrains[a]
            local aIndex = aBrain.Army

            for b = 1, TableGetn(aiBrains) do
                local bBrain = aiBrains[b]
                local bIndex = bBrain.Army

                if aIndex ~= bIndex then
                    victorious = victorious and (IsAlly(aIndex, bIndex) and aBrain.RequestingAlliedVictory and bBrain.RequestingAlliedVictory)
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
        -- defaults to false when no brains are provided
        if table.empty(aiBrains) then
            return false
        end

        for k = 1, TableGetn(aiBrains) do
            local brain = aiBrains[k]
            if not brain.OfferingDraw then
                return false
            end
        end

        return true
    end,

    --- Starts the monitoring of the victory condition.
    ---@param self AbstractVictoryCondition
    StartMonitoring = function(self)
        if self.ProcessGameStateThreadInstance then
            KillThread(self.ProcessGameStateThreadInstance)
        end

        self.ProcessGameStateThreadInstance = self.Trash:Add(ForkThread(self.MonitoringThread, self))
    end,

    --- Monitors the victory condition.
    ---@param self AbstractVictoryCondition
    MonitoringThread = function(self)
        while not IsGameOver() do
            self:EvaluateVictoryCondition()
            WaitTicks(4)
        end
    end,

    --- Evaluates the victory condition of individual players.
    ---@param self AbstractVictoryCondition
    EvaluateVictoryCondition = function(self)
        error("Missing implementation of ProcessGameState")
    end,

    --- Ends the game by starting a thread that ends the game 3 seconds later.
    ---@param self AbstractVictoryCondition
    EndGame = function(self)
        -- stop checking the game state
        if (self.ProcessGameStateThreadInstance) then
            KillThread(self.ProcessGameStateThreadInstance)
            self.ProcessGameStateThreadInstance = nil
        end

        self.Trash:Add(ForkThread(self.EndGameThread, self))
    end,

    --- Ends the game.
    ---@param self AbstractVictoryCondition
    EndGameThread = function(self)
        WaitSeconds(3)

        for _, v in GameOverListeners do
            pcall(v)
        end

        Sync.GameEnded = true
        WaitTicks(2)
        EndGame()
    end,

    --- Utility function for the logic to remove an army from the game by turning it into an observer.
    ---@param self AbstractVictoryCondition
    ---@param aiBrain AIBrain
    ToObserver = function(self, aiBrain)
        local brainIndex = aiBrain.Army
        SetArmyOutOfGame(brainIndex)

        if not ScenarioInfo.Options.AllowObservers then return end

        -- we need to map the brains to the command source index. Since we don't have access to `GetClients` 
        -- in the sim, we try and decipher it manually by checking if a brain is a human. We only want
        -- the command sources of allied humans.

        local commandSourceIndex = 0
        local commandSourceIndices = {}

        for i, data in ArmyBrains do
            if data.BrainType == 'Human' then
                if IsAlly(aiBrain.Army, data.Army) then
                    if not ArmyIsOutOfGame(data.Army) then
                        LOG("We have an allied source still going strong, can't remove")
                        return
                    end

                    table.insert(commandSourceIndices, commandSourceIndex)
                end

                -- brain is a human, always increment the command source index
                commandSourceIndex = commandSourceIndex + 1
            end
        end

        -- since this command source is defeated, we remove it from all existing armies.

        for _, commandSource in commandSourceIndices do
            for _, data in ArmyBrains do
                SetCommandSource(data.Army - 1, commandSource, false)
            end
        end
    end,

    --- Processes the army as if it forfeit/drew.
    ---@param self AbstractVictoryCondition
    ---@param aiBrain AIBrain
    DrawForArmy = function(self, aiBrain)
        self:ToObserver(aiBrain)
        aiBrain:OnDraw()

        local brainIndex = aiBrain.Army
        SyncGameResult({ brainIndex, "draw 0" })
    end,

    --- Processes the army as if it was victorious.
    ---@param self AbstractVictoryCondition
    ---@param aiBrain AIBrain
    VictoryForArmy = function(self, aiBrain)
        self:ToObserver(aiBrain)
        aiBrain:OnVictory()

        local brainIndex = aiBrain.Army
        SyncGameResult({ brainIndex, "victory 10" })
    end,

    --- Processes the army as if it was defeated.
    ---@param self AbstractVictoryCondition
    ---@param aiBrain AIBrain
    DefeatForArmy = function(self, aiBrain)
        self:ToObserver(aiBrain)
        aiBrain:OnDefeat()

        local brainIndex = aiBrain.Army
        SyncGameResult({ brainIndex, "defeat -10" })
    end,

}
