
local StructureUnit = import("/lua/sim/units/structureunit.lua").StructureUnit

---@class MassCollectionUnit : StructureUnit
---@field ConsumptionActive boolean
---@field UpgradeWatcher thread
MassCollectionUnit = ClassUnit(StructureUnit) {

    ---@param self MassCollectionUnit
    OnConsumptionActive = function(self)
        StructureUnit.OnConsumptionActive(self)
        self:ApplyAdjacencyBuffs()
        self.ConsumptionActive = true
    end,

    ---@param self MassCollectionUnit
    OnConsumptionInActive = function(self)
        StructureUnit.OnConsumptionInActive(self)
        self:RemoveAdjacencyBuffs()
        self.ConsumptionActive = false
    end,

    ---@param self MassCollectionUnit
    ---@param builder Unit
    ---@param layer string
    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
    end,

    ---comment
    ---@param self MassCollectionUnit
    ---@param unitbuilding MassCollectionUnit
    ---@param order boolean
    OnStartBuild = function(self, unitbuilding, order)
        StructureUnit.OnStartBuild(self, unitbuilding, order)
        self:AddCommandCap('RULEUCC_Stop')
        self.UpgradeWatcher = self:ForkThread(self.WatchUpgradeConsumption)
    end,

    ---@param self MassCollectionUnit
    ---@param unitbuilding MassCollectionUnit
    ---@param order boolean
    OnStopBuild = function(self, unitbuilding, order)
        StructureUnit.OnStopBuild(self, unitbuilding, order)
        self:RemoveCommandCap('RULEUCC_Stop')
        if self.UpgradeWatcher then
            KillThread(self.UpgradeWatcher)
            self:SetConsumptionPerSecondMass(0)
            self:SetProductionPerSecondMass((self.Blueprint.Economy.ProductionPerSecondMass or 0) * (self.MassProdAdjMod or 1))
        end
    end,

    -- Band-aid on lack of multiple separate resource requests per unit...
    -- If mass econ is depleted, take all the mass generated and use it for the upgrade
    -- Old WatchUpgradeConsumption replaced with this on, enabling mex to not use resources when paused
    ---@param self MassCollectionUnit
    WatchUpgradeConsumption = function(self)
        local bp = self.Blueprint
        local massConsumption = self:GetConsumptionPerSecondMass()

        -- Fix for weird mex behaviour when upgrading with depleted resource stock or while paused [100]
        -- Replaced Gowerly's fix with this which is very much inspired by his code. My code looks much better and
        -- seems to work a little better aswell.
        local aiBrain = self:GetAIBrain()

        local CalcEnergyFraction = function()
            local fraction = 1
            if aiBrain:GetEconomyStored('ENERGY') < self:GetConsumptionPerSecondEnergy() then
                fraction = math.min(1, aiBrain:GetEconomyIncome('ENERGY') / aiBrain:GetEconomyRequested('ENERGY'))
            end
            return fraction
        end

        local CalcMassFraction = function()
            local fraction = 1
            if aiBrain:GetEconomyStored('MASS') < self:GetConsumptionPerSecondMass() then
                fraction = math.min(1, aiBrain:GetEconomyIncome('MASS') / aiBrain:GetEconomyRequested('MASS'))
            end
            return fraction
        end

        while not self.Dead do
            local massProduction = bp.Economy.ProductionPerSecondMass * (self.MassProdAdjMod or 1)
            if self:IsPaused() then
                -- Paused mex upgrade (another bug here that caused paused upgrades to continue use resources)
                self:SetConsumptionPerSecondMass(0)
                self:SetProductionPerSecondMass(massProduction * CalcEnergyFraction())
            elseif aiBrain:GetEconomyStored('MASS') < 1 then
                -- Mex upgrade while out of mass (this is where the engine code has a bug)
                self:SetConsumptionPerSecondMass(massConsumption)
                self:SetProductionPerSecondMass(massProduction / CalcMassFraction())
                -- To use Gowerly's words; the above division cancels the engine bug like matter and anti-matter.
                -- The engine seems to do the exact opposite of this division.
            else
                -- Mex upgrade while enough mass (don't care about energy, that works fine)
                self:SetConsumptionPerSecondMass(massConsumption)
                self:SetProductionPerSecondMass(massProduction * CalcEnergyFraction())
            end

            WaitTicks(1)
        end
    end,

    ---@param self MassCollectionUnit
    OnProductionPaused = function(self)
        StructureUnit.OnProductionPaused(self)
        self:StopUnitAmbientSound('ActiveLoop')
    end,

    ---@param self MassCollectionUnit
    OnProductionUnpaused = function(self)
        StructureUnit.OnProductionUnpaused(self)
        self:PlayUnitAmbientSound('ActiveLoop')
    end,
}
