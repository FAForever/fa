
--***************************************************************************
--**  Summary: Module is based on the AI economy logic at LOUD
--****************************************************************************

local Debug = false
function EnableDebugging()
    Debug = true
end

function DisableDebugging()
    Debug = false
end

-- upvalued for performance
local GetEconomyIncome = moho.aibrain_methods.GetEconomyIncome
local GetEconomyRequested = moho.aibrain_methods.GetEconomyRequested
local GetEconomyTrend = moho.aibrain_methods.GetEconomyTrend
local GetEconomyStoredRatio = moho.aibrain_methods.GetEconomyStoredRatio

local MathMin = math.min

---@class AIBrainEconomyData
---@field EnergyIncome table<number, number>
---@field EnergyRequested table<number, number>
---@field EnergyStorage table<number, number>
---@field EnergyTrend table<number, number>
---@field EnergyStoredRatio table<number, number>
---@field MassIncome table<number, number>
---@field MassRequested table<number, number>
---@field MassStorage table<number, number>
---@field MassTrend table<number, number>
---@field MassStoredRatio table<number, number>

---@class AIBrainEconomyOverTimeData
---@field EnergyIncome number
---@field EnergyRequested number
---@field EnergyEfficiencyOverTime number
---@field EnergyTrendOverTime number
---@field EnergyStoredRatioOverTime number
---@field MassIncome number
---@field MassRequested number
---@field MassEfficiencyOverTime number
---@field MassTrendOverTime number
---@field MassStoredRatioOverTime number

---@class AIBrainEconomyComponent : AIBrain
---@field EconomyData AIBrainEconomyData
---@field EconomySamples number
---@field EconomySampleRateInTicks number
---@field EconomyOverTimeCurrent AIBrainEconomyOverTimeData
---@field EconomyTicksMonitor number
---@field EconomyMonitorThread thread
AIBrainEconomyComponent = ClassSimple {

    ---@param self AIBrainEconomyComponent
    OnCreateAI = function(self)
        self.EconomySamples = 30
        self.EconomySampleRateInTicks = 10
        self.EconomyData = {
            EnergyIncome = {},
            EnergyRequested = {},
            EnergyStorage = {},
            EnergyTrend = {},
            EnergyStoredRatio = {},
            MassIncome = {},
            MassRequested = {},
            MassStorage = {},
            MassTrend = {},
            MassStoredRatio = {},
        }

        local economyData = self.EconomyData
        for k = 1, self.EconomySamples do
            economyData.EnergyIncome[k] = 0
            economyData.EnergyRequested[k] = 0
            economyData.EnergyStorage[k] = 0
            economyData.EnergyTrend[k] = 0
            economyData.EnergyStoredRatio[k] = 0
            economyData.MassIncome[k] = 0
            economyData.MassRequested[k] = 0
            economyData.MassStorage[k] = 0
            economyData.MassTrend[k] = 0
            economyData.MassStoredRatio[k] = 0
        end

        self.EconomyOverTimeCurrent = {
            EnergyIncome = 0,
            EnergyRequested = 0,
            EnergyEfficiencyOverTime = 0,
            EnergyTrendOverTime = 0,
            EnergyStoredRatioOverTime = 0,
            MassIncome = 0,
            MassRequested = 0,
            MassEfficiencyOverTime = 0,
            MassTrendOverTime = 0,
            MassStoredRatioOverTime = 0,
        }

        self:EconomyUpdate()
    end,

    ---@param self AIBrainEconomyComponent
    EconomyUpdate = function(self)
        ForkThread(self.EconomyUpdateThread, self)
    end,

    ---@param self AIBrainEconomyComponent
    EconomyUpdateThread = function(self)

        -- accumulated totals of the various fields
        local eIncome = 0
        local mIncome = 0
        local eRequested = 0
        local mRequested = 0
        local eRatio = 0
        local mRatio = 0
        local eTrend = 0
        local mTrend = 0

        local energyTrend, massTrend

        while true do

            -- local scope for quick access
            local EcoData = self.EconomyData
            local EcoDataEnergyIncome = EcoData.EnergyIncome
            local EcoDataMassIncome = EcoData.MassIncome
            local EcoDataEnergyRequested = EcoData.EnergyRequested
            local EcoDataMassRequested = EcoData.MassRequested
            local EcoDataEnergyTrend = EcoData.EnergyTrend
            local EcoDataMassTrend = EcoData.MassTrend
            local EcoDataEnergyStoredRatio = EcoData.EnergyStoredRatio
            local EcoDataMassStoredRatio = EcoData.MassStoredRatio

            for point = 1, self.EconomySamples do

                -- remove from accumulated totals
                eIncome = eIncome - EcoDataEnergyIncome[point]
                mIncome = mIncome - EcoDataMassIncome[point]
                eRequested = eRequested - EcoDataEnergyRequested[point]
                mRequested = mRequested - EcoDataMassRequested[point]
                eTrend = eTrend - EcoDataEnergyTrend[point]
                mTrend = mTrend - EcoDataMassTrend[point]
                eRatio = eRatio - EcoDataEnergyStoredRatio[point]
                mRatio = mRatio - EcoDataMassStoredRatio[point]

                -- add new data
                EcoDataEnergyIncome[point] = GetEconomyIncome(self, 'ENERGY')
                EcoDataMassIncome[point] = GetEconomyIncome(self, 'MASS')
                EcoDataEnergyRequested[point] = GetEconomyRequested(self, 'ENERGY')
                EcoDataMassRequested[point] = GetEconomyRequested(self, 'MASS')
                EcoDataEnergyStoredRatio[point] = GetEconomyStoredRatio(self, 'ENERGY')
                EcoDataMassStoredRatio[point] = GetEconomyStoredRatio(self, 'MASS')

                -- special case for trend
                energyTrend = GetEconomyTrend(self, 'ENERGY')
                massTrend = GetEconomyTrend(self, 'MASS')

                if energyTrend then
                    EcoDataEnergyTrend[point] = energyTrend
                else
                    EcoDataEnergyTrend[point] = 0.1
                end

                if massTrend then
                    EcoDataMassTrend[point] = massTrend
                else
                    EcoDataMassTrend[point] = 0.1
                end

                -- add the new data to totals
                eIncome = eIncome + EcoDataEnergyIncome[point]
                mIncome = mIncome + EcoDataMassIncome[point]
                eRequested = eRequested + EcoDataEnergyRequested[point]
                mRequested = mRequested + EcoDataMassRequested[point]
                eTrend = eTrend + EcoDataEnergyTrend[point]
                mTrend = mTrend + EcoDataMassTrend[point]
                eRatio = eRatio + EcoDataEnergyStoredRatio[point]
                mRatio = mRatio + EcoDataMassStoredRatio[point]

                -- calculate new over time values
                local sampleInverse =  (1 / self.EconomySamples)
                local economyOverTimeCurrent = self.EconomyOverTimeCurrent
                economyOverTimeCurrent.EnergyIncome = eIncome * sampleInverse
                economyOverTimeCurrent.MassIncome = mIncome * sampleInverse
                economyOverTimeCurrent.EnergyRequested = eRequested * sampleInverse
                economyOverTimeCurrent.MassRequested = mRequested * sampleInverse
                economyOverTimeCurrent.EnergyEfficiencyOverTime = MathMin((eIncome * sampleInverse) / (eRequested * sampleInverse), 2)
                economyOverTimeCurrent.MassEfficiencyOverTime = MathMin((mIncome * sampleInverse) / (mRequested * sampleInverse), 2)
                economyOverTimeCurrent.EnergyTrendOverTime = eTrend * sampleInverse
                economyOverTimeCurrent.MassTrendOverTime = mTrend * sampleInverse
                economyOverTimeCurrent.EnergyStoredRatioOverTime = eRatio * sampleInverse
                economyOverTimeCurrent.MassStoredRatioOverTime = mRatio * sampleInverse

                if Debug then
                    local army = self:GetArmyIndex()
                    local brainSync = Sync.AIBrainData
                    brainSync.EconomyData = brainSync.EconomyData or { }
                    brainSync.EconomyData[army] = economyOverTimeCurrent
                end

                coroutine.yield(self.EconomySampleRateInTicks)
            end
        end
    end,
}
