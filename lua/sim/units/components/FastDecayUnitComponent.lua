local TrashAdd = TrashBag.Add

--- Provides a method to make units decay quickly when they are at a low completion %.
--- This prevents unbuilt buildings from blocking pathfinding for a long time.
--- Used in T1 PD (##B2101), AA (##B2104), and torpedo launchers (##B2109).
---@class FastDecayComponent : Unit
FastDecayComponent = ClassSimple {
    --- Call this at the end of your OnCreate function.
    ---@param self FastDecayComponent
    StartFastDecayThread = function(self)
        TrashAdd(self.Trash, ForkThread(self.FastDecayThread, self))
    end,

    --- While the unit is at low completion and not actively being built, rapidly reduces its HP.
    --- Starting construction on the unit restores decayed HP.
    ---@param self FastDecayComponent
    FastDecayThread = function(self)
        local maxHealth = self:GetMaxHealth()
        local bpEcon = self.Blueprint.Economy
        -- compensate for natural decay rate
        local highestEcoStat = math.max(bpEcon.BuildCostEnergy, bpEcon.BuildCostMass, bpEcon.BuildTime)
        -- walls' highest cost is 20 energy, so they decay in 200 ticks total
        -- Make all units decay at this rate
        local decayPerTick = -maxHealth * (1 / 200 - 0.1 / highestEcoStat)
        local completionThreshold = 200 / highestEcoStat
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
