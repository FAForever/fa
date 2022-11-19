local GetEconomyStoredRatio = moho.aibrain_methods.GetEconomyStoredRatio
local GetEconomyIncome = moho.aibrain_methods.GetEconomyIncome
local GetEconomyRequested = moho.aibrain_methods.GetEconomyRequested
local GetEconomyStored = moho.aibrain_methods.GetEconomyStored
local GetEconomyStoredRatio = moho.aibrain_methods.GetEconomyStoredRatio
local GetEconomyTrend = moho.aibrain_methods.GetEconomyTrend

local TableGetn = table.getn
local TableInsert = table.insert
local TableRemove = table.remove
local TableSort = table.sort

StructureManager = Class {
    Create = function(self, brain)
        -- Setting default properties on the Structure Manager
        -- Each structure type will have its own data table with various configuration values
        -- The UpgradeStrategy will be used to manipulate how the AI focuses on upgrades, different personalities start with different strategies
        self.Brain = brain
        self.Initialized = false
        self.Debug = false
        self.UpgradeStrategy = 'balanced'
        self.ExtractorData = {
            EconomyUpgradeSpendDefault = 0.20,
            CurrentEconomyUpgradeSpend = 0.30,
            ExtractorsUpgrading = { TECH1 = 0, TECH2 = 0 },
            CurrentExtractorCount = { TECH1 = 0, TECH2 = 0, TECH3 = 0},
            EcoMassUpgradeTimeout = 180,
            TotalExtractorSpend = 0
        }
        if brain.CheatEnabled then
            self.EcoMultiplier = tonumber(ScenarioInfo.Options.CheatMult) or 1.0
        else
            self.EcoMultiplier = 1.0
        end
        local per = ScenarioInfo.ArmySetup[self.Name].AIPersonality
        if per == 'turtle' or per == 'turtlecheat' then
            self.UpgradeStrategy = 'eco'
            CurrentEconomyUpgradeSpend = 0.35
        end
    end,

    Run = function(self)
        self:ForkThread(self.ExtractorUpgradeThread, self.Brain)
        if self.Debug then
            self:ForkThread(self.StructureDebugThread)
        end
        self.Initialized = true
    end,

    ForkThread = function(self, fn, ...)
        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.Brain.Trash:Add(thread)
            return thread
        else
            return nil
        end
    end,

    --- Main extractor upgrade loop, this checks economic metrics and upgrades extractors
    ---@param self Structure Manager
    ExtractorUpgradeThread = function(self)
    -- Keep track of how many extractors are currently upgrading
    -- Right now this is less about making the best decision to upgrade and more about managing the economy while that upgrade is happening.
        WaitTicks(Random(5,20))
        while true do
            local gameTime = GetGameTimeSeconds()
            local upgradeTrigger = false
            -- We figure out how much mass we have to spend and use this a primary trigger. 
            local upgradeSpend = (self.Brain.EconomyOverTimeCurrent.MassIncome*10)*self.ExtractorData.CurrentEconomyUpgradeSpend
            -- We want a minimum spend or a timeout.
            if upgradeSpend > 5 or gameTime > (420 / self.EcoMultiplier) then
                upgradeTrigger = true
            end
            -- After a certain time we'll put more into eco. Should be dictated by upgrade strategy. Seperate function?
            if gameTime > (480 / self.EcoMultiplier) and self.CurrentEconomyUpgradeSpend < 0.35 and self.UpgradeStrategy ~= 'eco' then
                self.CurrentEconomyUpgradeSpend = 0.30
            end
            local extractorTable = self:ExtractorsBeingUpgraded()
            LOG('Total Spend is '..self.TotalExtractorSpend..' income with ratio is '..upgradeSpend)
            local massStorage = GetEconomyStored( self.Brain, 'MASS')
            local energyStorage = GetEconomyStored( self.Brain, 'ENERGY')
            -- We have alot of excess mass and no upgrading T2 extractors, lets upgrade one and dump the mass into that
            if massStorage > 2500 and energyStorage > 8000 and self.Brain.EconomyOverTimeCurrent.EnergyEfficiencyOverTime >= 1.05 and self.ExtractorData.ExtractorsUpgrading.TECH2 < 1 then
                self:SelectClosestExtractor(extractorTable, true)
                WaitTicks(60)
                continue
            end
            if self.ExtractorData.ExtractorsUpgrading.TECH1 < 2 and self.ExtractorData.ExtractorsUpgrading.TECH2 < 1 and upgradeTrigger then
                -- Check if we can upgrade an extractor now with available upgrade spend and energy efficiency over time
                if self.TotalExtractorSpend < upgradeSpend and self.Brain.EconomyOverTimeCurrent.EnergyEfficiencyOverTime >= 1.05 then
                    -- Logic for comparing ratios and income to decide to we should try T1 upgrades only or T1 and T2.
                    if (self.ExtractorData.CurrentExtractorCount.TECH1 / self.ExtractorData.CurrentExtractorCount.TECH2 >= 1.2) and upgradeSpend - self.TotalExtractorSpend > self.T3ExtractorCost then
                        self:SelectClosestExtractor(extractorTable, true)
                    elseif (self.ExtractorData.CurrentExtractorCount.TECH1 / self.ExtractorData.CurrentExtractorCount.TECH2 >= 1.7) or upgradeSpend < 15 then
                        -- Extractor Ratio of T1 to T2 is >= 1.5 or upgrade spend under 15
                        self:SelectClosestExtractor(extractorTable, false)
                    else
                        -- Else all tiers upgrade
                        self:SelectClosestExtractor(extractorTable, true)
                    end
                end
                WaitTicks(30)
                -- We have more than a few extractors upgrading. Do we still have excess mass? Lets try more T1 Extractors
            elseif self.ExtractorData.ExtractorsUpgrading.TECH1 < 5 and massStorage > 150 and upgradeTrigger then
                if self.TotalExtractorSpend < upgradeSpend and self.Brain.EconomyOverTimeCurrent.EnergyEfficiencyOverTime >= 1.05 then
                    self:SelectClosestExtractor(extractorTable, false)
                    WaitTicks(30)
                end
                -- We still have excess mass? Lets try another T2 extractor
            elseif massStorage > 500 and energyStorage > 3000 and self.ExtractorData.ExtractorsUpgrading.TECH2 < 2 then
                if self.Brain.EconomyOverTimeCurrent.MassEfficiencyOverTime >= 1.05 and self.Brain.EconomyOverTimeCurrent.EnergyEfficiencyOverTime >= 1.05 then
                    -- 'We Could upgrade an extractor now with over time
                    local massIncome = GetEconomyIncome(self.Brain, 'MASS')
                    local massRequested = GetEconomyRequested(self.Brain, 'MASS')
                    local energyIncome = GetEconomyIncome(self.Brain, 'ENERGY')
                    local energyRequested = GetEconomyRequested(self.Brain, 'ENERGY')
                    local massEfficiency = math.min(massIncome / massRequested, 2)
                    local energyEfficiency = math.min(energyIncome / energyRequested, 2)
                    if energyEfficiency >= 1.05 and massEfficiency >= 1.05 then
                        -- We Could upgrade an extractor now with instant energyefficiency and mass efficiency
                        if self.ExtractorData.CurrentExtractorCount.TECH1 / self.ExtractorData.CurrentExtractorCount.TECH2 >= 1.5 or upgradeSpend < 15 then
                            -- Trigger all tiers false
                            self:SelectClosestExtractor(extractorTable, false)
                        else
                            -- Trigger all tiers true
                            self:SelectClosestExtractor(extractorTable, true)
                        end
                    end
                    WaitTicks(30)
                end
                -- We have alot of excess mass, chances are we just reclaimed something big. Lets throw it at an upgrade.
            elseif massStorage > 2500 and energyStorage > 8000 then
                if self.Brain.EconomyOverTimeCurrent.MassEfficiencyOverTime >= 0.8 and self.Brain.EconomyOverTimeCurrent.EnergyEfficiencyOverTime >= 1.05 then
                    -- We Could upgrade an extractor now with over time efficiency
                    local massIncome = GetEconomyIncome(self.Brain, 'MASS')
                    local massRequested = GetEconomyRequested(self.Brain, 'MASS')
                    local energyIncome = GetEconomyIncome(self.Brain, 'ENERGY')
                    local energyRequested = GetEconomyRequested(self.Brain, 'ENERGY')
                    local massEfficiency = math.min(massIncome / massRequested, 2)
                    local energyEfficiency = math.min(energyIncome / energyRequested, 2)
                    if energyEfficiency >= 1.0 and massEfficiency >= 0.8 then
                        -- We Could upgrade an extractor now with instant efficiency
                        -- Trigger all tiers true
                        self:SelectClosestExtractor(extractorTable, true)
                    end
                    WaitTicks(30)
                end
            end
            WaitTicks(30)
        end
    end,


    --- Triggers an extractor upgrade after identifying the closest.
    ---@param self Structure Manager
    ---@param cats extractorTable a table of extractors that should be available for upgrade
    ---@param allTiers boolean true/false consider T1 and T2 extractors or just T1
    SelectClosestExtractor = function(self, extractorTable, allTiers)
        -- We are going to find the closest extractor to the main base that isn't already upgrading
        -- You could do smart things select safer extractors here but thats what the initial delay is supposed to do
        -- This could be done smarter leveraging the IMAP, using the ring system on a 10km map it would check approx 60-70 units radius around the position.
        local UnitPos
        local DistanceToBase
        local LowestDistanceToBase
        local lowestUnit = false
        local BasePosition = self.Brain.BuilderManagers['MAIN'].Position
        if extractorTable then            
            if not allTiers then
                for _, c in extractorTable.TECH1 do
                    if c and not c.Dead then
                        if c.InitialDelayCompleted then
                            if not c:IsUnitState('Upgrading') then
                                UnitPos = c:GetPosition()
                                DistanceToBase = VDist2Sq(BasePosition[1] or 0, BasePosition[3] or 0, UnitPos[1] or 0, UnitPos[3] or 0)
                                if not LowestDistanceToBase or DistanceToBase < LowestDistanceToBase then
                                    LowestDistanceToBase = DistanceToBase
                                    lowestUnit = c
                                end
                            end
                        end
                    end
                end
            else
                for _, c in extractorTable.TECH1 do
                    if c and not c.Dead then
                        if c.InitialDelayCompleted then
                            if not c:IsUnitState('Upgrading') then
                                UnitPos = c:GetPosition()
                                DistanceToBase = VDist2Sq(BasePosition[1] or 0, BasePosition[3] or 0, UnitPos[1] or 0, UnitPos[3] or 0)
                                if not LowestDistanceToBase or DistanceToBase < LowestDistanceToBase then
                                    LowestDistanceToBase = DistanceToBase
                                    lowestUnit = c
                                end
                            end
                        end
                    end
                end
                for _, c in extractorTable.TECH2 do
                    if c and not c.Dead then
                        if c.InitialDelayCompleted then
                            if not c:IsUnitState('Upgrading') then
                                UnitPos = c:GetPosition()
                                DistanceToBase = VDist2Sq(BasePosition[1] or 0, BasePosition[3] or 0, UnitPos[1] or 0, UnitPos[3] or 0)
                                if not LowestDistanceToBase or DistanceToBase < LowestDistanceToBase then
                                    LowestDistanceToBase = DistanceToBase
                                    lowestUnit = c
                                end
                            end
                        end
                    end
                end
            end
            if lowestUnit then
                lowestUnit.CentralBrainExtractorUpgrade = true
                lowestUnit.DistanceToBase = LowestDistanceToBase
                if not self.CentralBrainExtractorUnitUpgradeClosest then
                    self.CentralBrainExtractorUnitUpgradeClosest = lowestUnit
                end
                self:ForkThread(self.UpgradeExtractor, lowestUnit, LowestDistanceToBase)
            else
                -- There is no lowestUnit
            end
        end
    end,
    
    --- Upgrades an extractor and pauses extractor upgrades if economy is hurting
    ---@param self Structure Manager
    ---@param extractorUnit unit Extractor that is going to be upgraded
    ---@param distanceToBase integer Extractors distance to the main base
    UpgradeExtractor = function(self, extractorUnit, distanceToBase)
        -- This triggers the actual upgrade and then will try to manager it
        -- While the extractor is below 65% upgraded it will try to keep its economy above a certain number to minimum production impact
        -- This works well in the T1 phase but not so well in the T3 phase when the AI can have wild swings due to mass per second requirements being so different for different structures.
        -- It will focus on whichever extractor is closest to the AI main base. This should idealy be a primary rather than closest so it could be more intelligent about selection.
        local upgradeID = extractorUnit.Blueprint.General.UpgradesTo or false
        if upgradeID then
            IssueUpgrade({extractorUnit}, upgradeID)
            WaitTicks(2)
            local fractionComplete
            local upgradeTimeStamp = GetGameTimeSeconds()
            local bypassEcoManager = false
            local extractorUpgradeTimeoutReached = false
            local upgradedExtractor = extractorUnit.UnitBeingBuilt
            if not upgradedExtractor.Dead then
                fractionComplete = upgradedExtractor:GetFractionComplete()
            end
            while extractorUnit and not extractorUnit.Dead and fractionComplete < 1 do
                if not self.CentralBrainExtractorUnitUpgradeClosest or self.CentralBrainExtractorUnitUpgradeClosest.Dead then
                    self.CentralBrainExtractorUnitUpgradeClosest = extractorUnit
                elseif self.CentralBrainExtractorUnitUpgradeClosest.DistanceToBase > distanceToBase then
                    self.CentralBrainExtractorUnitUpgradeClosest = extractorUnit
                end
                if not bypassEcoManager and fractionComplete < 0.65 then
                    if (GetEconomyTrend(self.Brain, 'MASS') <= 0.0 and GetEconomyStored(self.Brain, 'MASS') <= 150) or GetEconomyStored( self.Brain, 'ENERGY') < 200 then
                        if not extractorUnit:IsPaused() then
                            extractorUnit:SetPaused(true)
                            WaitTicks(10)
                        end
                    else
                        if extractorUnit:IsPaused() then
                            if self.ExtractorData.ExtractorsUpgrading.TECH1 > 1 or self.ExtractorData.ExtractorsUpgrading.TECH2 > 0 then
                                if self.CentralBrainExtractorUnitUpgradeClosest and not self.CentralBrainExtractorUnitUpgradeClosest.Dead 
                                and self.CentralBrainExtractorUnitUpgradeClosest.DistanceToBase == distanceToBase then
                                    extractorUnit:SetPaused(false)
                                    WaitTicks(30)
                                elseif self.ExtractorData.ExtractorsUpgrading.TECH2 > 0 and EntityCategoryContains(categories.TECH1, extractorUnit) then
                                    extractorUnit:SetPaused(false)
                                    if extractorUpgradeTimeoutReached then
                                        WaitTicks(30)
                                    end
                                    WaitTicks(30)
                                elseif GetEconomyStored(self.Brain, 'MASS') > 250 then
                                    extractorUnit:SetPaused(false)
                                    WaitTicks(30)
                                end
                            else
                                extractorUnit:SetPaused(false)
                                WaitTicks(20)
                            end
                        end
                    end
                end
                WaitTicks(30)
                if upgradedExtractor and not upgradedExtractor.Dead then
                    fractionComplete = upgradedExtractor:GetFractionComplete()
                end
                if not extractorUpgradeTimeoutReached then
                    if GetGameTimeSeconds() - upgradeTimeStamp > self.ExtractorData.EcoMassUpgradeTimeout then
                        extractorUpgradeTimeoutReached = true
                    end
                end
                if fractionComplete < 1 and extractorUpgradeTimeoutReached and (self.CentralBrainExtractorUnitUpgradeClosest.DistanceToBase == distanceToBase or extractorUnit.MAINBASE) then
                    bypassEcoManager = true
                    if extractorUnit:IsPaused() then
                        extractorUnit:SetPaused(false)
                    end
                end
            end
            if upgradedExtractor and not upgradedExtractor.Dead then
                if VDist3Sq(upgradedExtractor:GetPosition(), self.Brain.BuilderManagers['MAIN'].Position) < 6400 then
                    upgradedExtractor.MAINBASE = true
                end
            end
        else
            WARN('No upgrade id provided to UpgradeExtractor, unit id is '..extractorUnit.UnitId)
        end
        WaitTicks(80)
    end,

    --- Stops the unit from being upgraded until it has been alive for a certain amount of time
    ---@param self Structure Manager
    ---@param unit unit Extractor
    ExtractorInitialDelay = function(self, unit)
        local initial_delay = 0
        local ecoStartTime = GetGameTimeSeconds()
        local ecoTimeOut = 300

        unit.InitialDelayCompleted = false
        unit.InitialDelayStarted = true
        while initial_delay < (50 / self.EcoMultiplier) do
            if not IsDestroyed(unit) then
                if GetEconomyStored( self.Brain, 'ENERGY') >= 150 and unit:GetFractionComplete() == 1 then
                    initial_delay = initial_delay + 10
                    if (GetGameTimeSeconds() - ecoStartTime) > ecoTimeOut then
                        initial_delay = 50
                    end
                end
            else
                return
            end
            WaitTicks(100)
        end
        unit.InitialDelayCompleted = true
    end,

    ExtractorsBeingUpgraded = function(self)
        -- Returns number of extractors upgrading
        local ALLBPS = __blueprints
        local extractors = self.Brain:GetListOfUnits(categories.MASSEXTRACTION, false)
        local tech1ExtNumBuilding = 0
        local tech2ExtNumBuilding = 0
        local tech1Total = 0
        local tech2Total = 0
        local tech3Total = 0
        local totalSpend = 0
        local extractorTable = {
            TECH1 = {},
            TECH2 = {}
        }

        -- loop over all units and search for upgrading units
        for _, extractor in extractors do
            if not IsDestroyed(extractor) and extractor:GetFractionComplete() == 1 then
                if not extractor.InitialDelayStarted then
                    self:ForkThread(self.ExtractorInitialDelay, extractor)
                end
                if extractor.Blueprint.CategoriesHash.TECH1 then
                    tech1Total = tech1Total + 1
                    if not self.T2ExtractorCost then
                        local upgradeId = extractor.Blueprint.General.UpgradesTo
                        self.T2ExtractorCost = (ALLBPS[upgradeId].Economy.BuildCostMass / ALLBPS[upgradeId].Economy.BuildTime * (ALLBPS[extractor.UnitId].Economy.BuildRate * self.EcoMultiplier))
                    end
                    if extractor:IsUnitState('Upgrading') then
                        local upgradeId = extractor.Blueprint.General.UpgradesTo
                        totalSpend = totalSpend +  (ALLBPS[upgradeId].Economy.BuildCostMass / ALLBPS[upgradeId].Economy.BuildTime * (ALLBPS[extractor.UnitId].Economy.BuildRate * self.EcoMultiplier))
                        tech1ExtNumBuilding = tech1ExtNumBuilding + 1
                    else
                        TableInsert(extractorTable.TECH1, extractor)
                    end
                elseif extractor.Blueprint.CategoriesHash.TECH2 then
                    tech2Total = tech2Total + 1
                    if not self.T3ExtractorCost then
                        local upgradeId = extractor.Blueprint.General.UpgradesTo
                        self.T3ExtractorCost = (ALLBPS[upgradeId].Economy.BuildCostMass / ALLBPS[upgradeId].Economy.BuildTime * (ALLBPS[extractor.UnitId].Economy.BuildRate * self.EcoMultiplier))
                    end
                    if extractor:IsUnitState('Upgrading') then
                        local upgradeId = extractor.Blueprint.General.UpgradesTo
                        totalSpend = totalSpend + (ALLBPS[upgradeId].Economy.BuildCostMass / ALLBPS[upgradeId].Economy.BuildTime * (ALLBPS[extractor.UnitId].Economy.BuildRate * self.EcoMultiplier))
                        tech2ExtNumBuilding = tech2ExtNumBuilding + 1
                    else
                        TableInsert(extractorTable.TECH2, extractor)
                    end
                elseif extractor.Blueprint.CategoriesHash.TECH3 then
                    tech3Total = tech3Total + 1
                end
            end
        end
        self.TotalExtractorSpend = totalSpend
        self.ExtractorData.ExtractorsUpgrading.TECH1 = tech1ExtNumBuilding
        self.ExtractorData.ExtractorsUpgrading.TECH2 = tech2ExtNumBuilding
        self.ExtractorData.CurrentExtractorCount.TECH1 = tech1Total
        self.ExtractorData.CurrentExtractorCount.TECH2 = tech2Total
        self.ExtractorData.CurrentExtractorCount.TECH3 = tech3Total
        return extractorTable
    end,
}

function CreateStructureManager(brain)
    local sm 
    sm = StructureManager()
    sm:Create(brain)
    return sm
end

function GetStructureManager(brain)
    return brain.StructureManager
end