local TrashAdd = TrashBag.Add

--- Provides a method to make units decay quickly when they are at a low completion %.
--- This prevents unbuilt buildings from blocking pathfinding for a long time.
--- Used in T1 PD (##B2101), AA (##B2104), and torpedo launchers (##B2109).
---@class FastDecayComponent : Unit
FastDecayComponent = ClassSimple {
    --- Call this at the end of your OnCreate function.
    ---@param self FastDecayComponent
    ---@param decayPercentPerTick? number # %HP lost per tick when unit is decaying quickly. Defaults to wall decay rate.
    ---@param decayCompletionThreshold? number # Below this % completion, units decay quickly. Defaults to 200 resources invested.
    StartFastDecayThread = function(self, decayPercentPerTick, decayCompletionThreshold)
        TrashAdd(self.Trash, ForkThread(self.FastDecayThread, self, decayPercentPerTick, decayCompletionThreshold))
    end,

    --- While the unit is at low completion and not actively being built, rapidly reduces its HP.
    --- Starting construction on the unit restores decayed HP.
    ---@param self FastDecayComponent
    ---@param decayPercentPerTick? number # %HP lost per tick when unit is decaying quickly.
    ---@param decayCompletionThreshold? number # Below this % completion, units decay quickly.
    FastDecayThread = function(self, decayPercentPerTick, decayCompletionThreshold)
        local maxHealth = self:GetMaxHealth()
        local bpEcon = self.Blueprint.Economy
        local highestEcoStat = math.max(bpEcon.BuildCostEnergy, bpEcon.BuildCostMass, bpEcon.BuildTime)

        -- Defaults to decaying as fast as walls naturally decay (their highest cost is 20 energy)
        local healthPercentDecayPerTick = decayPercentPerTick or (0.1 / 20)
        -- Compensate for engine's decay of 0.1 resource/tick of the highest cost resource
        local naturalPercentDecayPerTick = 0.1 / highestEcoStat
        local decayPerTick = -maxHealth * (healthPercentDecayPerTick - naturalPercentDecayPerTick)
        -- Defaults to a limit of 200 resources invested
        local completionThreshold = decayCompletionThreshold or (200 / highestEcoStat)

        if decayPerTick < 0 then
            local decayedHp = 0
            while self:IsBeingBuilt() and not (self.Dead or IsDestroyed(self)) do
                -- units actively being built cannot be reclaimed
                if not self:IsUnitState("NoReclaim") and self:GetFractionComplete() < completionThreshold then
                    decayedHp = decayedHp + decayPerTick
                    self:AdjustHealth(self, decayPerTick)
                else
                    -- Natural decay decays build progress so decayed hp gets restored with building
                    -- We need to restore our artificially decayed hp too so that the final unit is max hp
                    self:AdjustHealth(self, -decayedHp)
                    decayedHp = 0
                end
                WaitTicks(1)
            end
        end
    end,
}
