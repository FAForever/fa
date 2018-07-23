--****************************************************************************
--**  File     :  /lua/sim/EngineerManager.lua
--**  Summary  : Manage engineers for a location
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local BuilderManager = import('/lua/sim/BuilderManager.lua').BuilderManager
local SUtils = import('/lua/AI/sorianutilities.lua')
local AIUtils = import('/lua/ai/aiutilities.lua')
local Builder = import('/lua/sim/Builder.lua')
local AIBuildUnits = import('/lua/ai/aibuildunits.lua')

EngineerManager = Class(BuilderManager) {
    Create = function(self, brain, lType, location, radius)
        BuilderManager.Create(self,brain)

        if not lType or not location or not radius then
            error('*PLATOOM FORM MANAGER ERROR: Invalid parameters; requires locationType, location, and radius')
            return false
        end

        self.Location = location
        self.Radius = radius
        self.LocationType = lType

        self.ConsumptionUnits = {
            Engineers = { Category = categories.ENGINEER, Units = {}, UnitsList = {}, Count = 0, },
            Fabricators = { Category = categories.MASSFABRICATION * categories.STRUCTURE, Units = {}, UnitsList = {}, Count = 0, },
            Shields = { Category = categories.SHIELD * categories.STRUCTURE, Units = {}, UnitsList = {}, Count = 0, },
            MobileShields = { Category = categories.SHIELD * categories.MOBILE, Units = {}, UnitsList = {}, Count = 0, },
            Intel = { Category = categories.STRUCTURE * (categories.SONAR + categories.RADAR + categories.OMNI), Units = {}, UnitsList = {}, Count = 0, },
            MobileIntel = { Category = categories.MOBILE - categories.ENGINEER - categories.SHIELD, Units = {}, UnitsList = {}, Count = 0, },
        }

        self:AddBuilderType('Any')
    end,

    -- ================================== --
    --     Universal on/off functions
    -- ================================== --
    EnableGroup = function(self, group)
        for k,v in group.Units do
            if not v.Status and v.Unit and not v.Unit.Dead then
                v.Unit:OnUnpaused()
                v.Status = true
            end
        end
    end,

    -- Check to see if the unit is buildings something in the category given
    ProductionCheck = function(unit, econ, pauseVal, category)
        local beingBuilt = false
        if not unit or unit.Dead or not IsUnit(unit) then
            return false
        end
        if unit:IsUnitState('Building') then
            beingBuilt = unit.UnitBeingBuilt
            return false
        elseif unit:IsUnitState('Guarding') then
            local guardedUnit = unit:GetGuardedUnit()
            if guardedUnit and not guardedUnit.Dead and IsUnit(guardedUnit) and guardedUnit:IsUnitState('Building') then
                beingBuilt = guardedUnit.UnitBeingBuilt
            end
        end
        -- If built unit is of the category passed in return true
        if beingBuilt and EntityCategoryContains(category, beingBuilt) then
            return true
        end
        return false
    end,

    -- only pause the assisters of experimentals
    ExperimentalCheck = function(unit, econ, pauseVal, category)
        local beingBuilt = false
        if not unit or unit.Dead or not IsUnit(unit) then
            return false
        end
        if unit:IsUnitState('Guarding') then
            local guardedUnit = unit:GetGuardedUnit()
            if guardedUnit and not guardedUnit.Dead and IsUnit(guardedUnit) and guardedUnit:IsUnitState('Building') then
                beingBuilt = guardedUnit.UnitBeingBuilt
            end
        end
        -- If built unit is of the category passed in return true
        if beingBuilt and EntityCategoryContains(categories.EXPERIMENTAL, beingBuilt) then
            return true
        end
        return false
    end,

    AssistCheck = function(unit, econ, pauseVal, category)
    end,

    -- ====================================================== --
    --     Functions for when an AI Brain's mass runs dry
    -- ====================================================== --
    LowMass = function(self)
        local econ = AIUtils.AIGetEconomyNumbers(self.Brain)
        local pauseVal = 0

        self.Brain.LowMassMode = true

        --LOG('*AI DEBUG: Shutting down units for mass needs')

        -- Disable engineers building defenses
        pauseVal = self:DisableMassGroup(self.ConsumptionUnits.Engineers, econ, pauseVal, self.ProductionCheck, categories.DEFENSE)

        -- Disable shields
        if pauseVal != true then
            pauseVal = self:DisableMassGroup(self.ConsumptionUnits.Engineers, econ, pauseVal, self.ProductionCheck, categories.SHIELD)
        end

        -- Disable factory builders
        if pauseVal != true then
            pauseVal = self:DisableMassGroup(self.ConsumptionUnits.Engineers, econ, pauseVal, self.ProductionCheck, categories.FACTORY * (categories.TECH2 + categories.TECH3))
        end

        -- Disable those building mobile units (through assist or experimental)
        if pauseVal != true then
            --pauseVal = self:DisableMassGroup(self.ConsumptionUnits.Engineers, econ, pauseVal, self.ExperimentalCheck)
        end

        -- Disable those building mobile units (through assist or experimental)
        if pauseVal != true then
            --pauseVal = self:DisableMassGroup(self.ConsumptionUnits.Engineers, econ, pauseVal, self.ProductionCheck, categories.MOBILE - categories.EXPERIMENTAL)
        end

        -- Disable those building mobile units (through assist or experimental)
        if pauseVal != true then
            --pauseVal = self:DisableMassGroup(self.ConsumptionUnits.Engineers, econ, pauseVal, self.ProductionCheck, categories.STRUCTURE - categories.MASSEXTRACTION - categories.ENERGYPRODUCTION - categories.FACTORY - categories.EXPERIMENTAL)
        end

        self:ForkThread(self.LowMassRepeatThread)
    end,

    LowMassRepeatThread = function(self)
        WaitSeconds(3)
        if self.Brain.LowMassMode then
            self:LowMass()
        end
    end,

    RestoreMass = function(self)
        --LOG('*AI DEBUG: Activating Shut down mass units')
        self.Brain.LowMassMode = false

        -- enable engineers
        self:EnableGroup(self.ConsumptionUnits.Engineers)
    end,

    MassCheck = function(self, econ, pauseVal)
        local massRequest = econ.MassRequestOverTime - pauseVal
        if econ.MassIncome > (massRequest * 0.9) then
            --LOG('*AI DEBUG: Under the cutoff')
            return true
        end
        return false
    end,

    DisableMassGroup = function(self, group, econ, pauseVal, unitCheckFunc, category)
        for k,v in group.Units do
            if not v.Unit.Dead and not EntityCategoryContains(categories.COMMAND, v.Unit) and (not unitCheckFunc or unitCheckFunc(v.Unit, econ, pauseVal, category)) then
                --LOG('*AI DEBUG: Disabling unit')
                v.Unit:OnPaused()
                pauseVal = pauseVal + v.Unit:GetConsumptionPerSecondMass()
                v.Status = false
            end
            if self:MassCheck(econ, pauseVal) then
                return true
            end
        end
        return pauseVal
    end,

    -- ======================================================== --
    --     Functions for when an AI Brain's energy runs dry
    -- ======================================================== --
    EnergyCheck = function(self, econ, pauseVal)
        local energyRequest = econ.EnergyRequestOverTime - pauseVal
        if econ.EnergyIncome > (energyRequest * 0.9) then
            --LOG('*AI DEBUG: Under the cutoff')
            return true
        end
        return false
    end,


    DisableEnergyGroup = function(self, group, econ, pauseVal, unitCheckFunc, category)
        for k,v in group.Units do
            if not v.Unit.Dead and not EntityCategoryContains(categories.COMMAND, v.Unit) and (not unitCheckFunc or unitCheckFunc(v.Unit, econ, pauseVal, category)) then
                --LOG('*AI DEBUG: Disabling unit')
                v.Unit:OnPaused()
                pauseVal = pauseVal + v.Unit:GetConsumptionPerSecondEnergy()
                v.Status = false
            end
            if self:EnergyCheck(econ, pauseVal) then
                return true
            end
        end
        return pauseVal
    end,

    LowEnergy = function(self)
        local econ = AIUtils.AIGetEconomyNumbers(self.Brain)
        local pauseVal = 0

        self.Brain.LowEnergyMode = true

        --LOG('*AI DEBUG: Shutting down units for energy needs')

        -- Disable fabricators if mass in > mass out until 10% under
        if pauseVal != true then
            pauseVal = self:DisableEnergyGroup(self.ConsumptionUnits.Fabricators, econ, pauseVal, self.MassDrainCheck)
        end

        if pauseVal != true then
            pauseVal = self:DisableEnergyGroup(self.ConsumptionUnits.MobileIntel, econ, pauseVal)
        end

        -- Disable engineers assisting non-econ until 10% under
        if pauseVal != true then
            pauseVal = self:DisableEnergyGroup(self.ConsumptionUnits.Engineers, econ, pauseVal, self.ProductionCheck, categories.ALLUNITS - categories.ENERGYPRODUCTION - categories.MASSPRODUCTION)
        end

        -- Disable Intel if mass in > mass out until 10% under
        if pauseVal != true then
            pauseVal = self:DisableEnergyGroup(self.ConsumptionUnits.Intel, econ, pauseVal)
        end

        -- Disable fabricators until 10% under
        if pauseVal != true then
            pauseVal = self:DisableEnergyGroup(self.ConsumptionUnits.Fabricators, econ, pauseVal)
        end

        -- Disable engineers until 10% under
        if pauseVal != true then
            pauseVal = self:DisableEnergyGroup(self.ConsumptionUnits.Engineers, econ, pauseVal, self.ProductionCheck, categories.ALLUNITS - categories.ENERGYPRODUCTION)
        end

        self:ForkThread(self.LowEnergyRepeatThread)
    end,

    LowEnergyRepeatThread = function(self)
        WaitSeconds(3)
        if self.Brain.LowEnergyMode then
            self:LowEnergy()
        end
    end,

    RestoreEnergy = function(self)
        --LOG('*AI DEBUG: Activating Shut down energy units')
        self.Brain.LowEnergyMode = false

        -- enable intel
        self:EnableGroup(self.ConsumptionUnits.Intel)

        -- enable mobile intel
        self:EnableGroup(self.ConsumptionUnits.MobileIntel)

        -- enable fabricators
        self:EnableGroup(self.ConsumptionUnits.Fabricators)

        -- enable engineers
        self:EnableGroup(self.ConsumptionUnits.Engineers)
    end,

    -- Check if turning off this fabricator would destroy the mass income
    MassDrainCheck = function(unit, econ, pauseVal)
        if econ.MassIncome > econ.MassRequestOverTime then
            return true
        end
    end,


    ProductionCheckSorian = function(unit, econ, pauseVal, category)
        local beingBuilt = false
        if not unit or unit.Dead or not IsUnit(unit) then
            return false
        end
        if unit:IsUnitState('Building') then
            beingBuilt = unit.UnitBeingBuilt
            --return false
        elseif unit:IsUnitState('Guarding') then
            local guardedUnit = unit:GetGuardedUnit()
            if guardedUnit and not guardedUnit.Dead and IsUnit(guardedUnit) and guardedUnit:IsUnitState('Building') then
                beingBuilt = guardedUnit.UnitBeingBuilt
            end
        end
        -- If built unit is of the category passed in return true
        if beingBuilt and EntityCategoryContains(category, beingBuilt) then
            return true
        end
        return false
    end,

    -- ================================== --
    --     Universal on/off functions
    -- ================================== --
    EnableGroupSorian = function(self, group)
        for k,v in group.Units do
            if not v.Status and v.Unit and not v.Unit.Dead then
                LOG('*AI DEBUG: Enabling units')
                --v.Unit:OnUnpaused()
                IssuePause(v.Unit)
                v.Status = true
            end
        end
    end,

    -- ====================================================== --
    --     Functions for when an AI Brain's mass runs dry
    -- ====================================================== --
    LowMassSorian = function(self)
        local econ = AIUtils.AIGetEconomyNumbers(self.Brain)
        local pauseVal = 0

        self.Brain.LowMassMode = true

        LOG('*AI DEBUG: Shutting down units for mass needs')

        -- Disable engineers building defenses
        pauseVal = self:DisableMassGroupSorian(self.ConsumptionUnits.Engineers, econ, pauseVal, self.ProductionCheckSorian, categories.DEFENSE)

        -- Disable shields
        if pauseVal != true then
            pauseVal = self:DisableMassGroupSorian(self.ConsumptionUnits.Engineers, econ, pauseVal, self.ProductionCheckSorian, categories.SHIELD)
        end

        -- Disable factory builders
        if pauseVal != true then
            pauseVal = self:DisableMassGroupSorian(self.ConsumptionUnits.Engineers, econ, pauseVal, self.ProductionCheckSorian, categories.FACTORY * (categories.TECH2 + categories.TECH3))
        end

        -- Disable those building mobile units (through assist or experimental)
        if pauseVal != true then
            --pauseVal = self:DisableMassGroupSorian(self.ConsumptionUnits.Engineers, econ, pauseVal, self.ExperimentalCheck)
        end

        -- Disable those building mobile units (through assist or experimental)
        if pauseVal != true then
            --pauseVal = self:DisableMassGroupSorian(self.ConsumptionUnits.Engineers, econ, pauseVal, self.ProductionCheckSorian, categories.MOBILE - categories.EXPERIMENTAL)
        end

        -- Disable those building mobile units (through assist or experimental)
        if pauseVal != true then
            --pauseVal = self:DisableMassGroupSorian(self.ConsumptionUnits.Engineers, econ, pauseVal, self.ProductionCheckSorian, categories.STRUCTURE - categories.MASSEXTRACTION - categories.ENERGYPRODUCTION - categories.FACTORY - categories.EXPERIMENTAL)
        end

        self:ForkThread(self.LowMassRepeatThreadSorian)
    end,

    LowMassRepeatThreadSorian = function(self)
        WaitSeconds(3)
        if self.Brain.LowMassMode then
            self:LowMassSorian()
        end
    end,

    RestoreMassSorian = function(self)
        LOG('*AI DEBUG: Activating Shut down mass units')
        self.Brain.LowMassMode = false

        -- enable engineers
        self:EnableGroupSorian(self.ConsumptionUnits.Engineers)
    end,

    DisableMassGroupSorian = function(self, group, econ, pauseVal, unitCheckFunc, category)
        for k,v in group.Units do
            if not v.Unit.Dead and not EntityCategoryContains(categories.COMMAND, v.Unit) and (not unitCheckFunc or unitCheckFunc(v.Unit, econ, pauseVal, category)) then
                LOG('*AI DEBUG: Disabling unit for mass')
                --v.Unit:OnPaused()
                IssuePause(v.Unit)
                pauseVal = pauseVal + v.Unit:GetConsumptionPerSecondMass()
                v.Status = false
            end
            if self:MassCheck(econ, pauseVal) then
                return true
            end
        end
        return pauseVal
    end,

    -- ======================================================== --
    --     Functions for when an AI Brain's energy runs dry
    -- ======================================================== --

    DisableEnergyGroupSorian = function(self, group, econ, pauseVal, unitCheckFunc, category)
        for k,v in group.Units do
            if not v.Unit.Dead and not EntityCategoryContains(categories.COMMAND, v.Unit) and (not unitCheckFunc or unitCheckFunc(v.Unit, econ, pauseVal, category)) then
                LOG('*AI DEBUG: Disabling unit for energy')
                --v.Unit:OnPaused()
                IssuePause(v.Unit)
                pauseVal = pauseVal + v.Unit:GetConsumptionPerSecondEnergy()
                v.Status = false
            end
            if self:EnergyCheck(econ, pauseVal) then
                return true
            end
        end
        return pauseVal
    end,

    LowEnergySorian = function(self)
        local econ = AIUtils.AIGetEconomyNumbers(self.Brain)
        local pauseVal = 0

        self.Brain.LowEnergyMode = true

        LOG('*AI DEBUG: Shutting down units for energy needs')

        -- Disable fabricators if mass in > mass out until 10% under
        --if pauseVal != true then
        --    pauseVal = self:DisableEnergyGroup(self.ConsumptionUnits.Fabricators, econ, pauseVal, self.MassDrainCheck)
        --end

        --if pauseVal != true then
        --    pauseVal = self:DisableEnergyGroup(self.ConsumptionUnits.MobileIntel, econ, pauseVal)
        --end

        -- Disable engineers assisting non-econ until 10% under
        if pauseVal != true then
            pauseVal = self:DisableEnergyGroupSorian(self.ConsumptionUnits.Engineers, econ, pauseVal, self.ProductionCheckSorian, categories.ALLUNITS - categories.ENERGYPRODUCTION - categories.MASSPRODUCTION)
        end

        -- Disable Intel if mass in > mass out until 10% under
        --if pauseVal != true then
        --    pauseVal = self:DisableEnergyGroup(self.ConsumptionUnits.Intel, econ, pauseVal)
        --end

        -- Disable fabricators until 10% under
        --if pauseVal != true then
        --    pauseVal = self:DisableEnergyGroup(self.ConsumptionUnits.Fabricators, econ, pauseVal)
        --end

        -- Disable engineers until 10% under
        if pauseVal != true then
            pauseVal = self:DisableEnergyGroupSorian(self.ConsumptionUnits.Engineers, econ, pauseVal, self.ProductionCheckSorian, categories.ALLUNITS - categories.ENERGYPRODUCTION)
        end

        self:ForkThread(self.LowEnergyRepeatThreadSorian)
    end,

    LowEnergyRepeatThreadSorian = function(self)
        WaitSeconds(3)
        if self.Brain.LowEnergyMode then
            self:LowEnergySorian()
        end
    end,

    RestoreEnergySorian = function(self)
        LOG('*AI DEBUG: Activating Shut down energy units')
        self.Brain.LowEnergyMode = false

        -- enable intel
        --self:EnableGroup(self.ConsumptionUnits.Intel)

        -- enable mobile intel
        --self:EnableGroup(self.ConsumptionUnits.MobileIntel)

        -- enable fabricators
        --self:EnableGroup(self.ConsumptionUnits.Fabricators)

        -- enable engineers
        self:EnableGroupSorian(self.ConsumptionUnits.Engineers)
    end,

    -- =============================== --
    --     Builder based functions
    -- =============================== --
    AddBuilder = function(self, builderData, locationType, builderType)
        local newBuilder = Builder.CreateEngineerBuilder(self.Brain, builderData, locationType)
        self:AddInstancedBuilder(newBuilder, builderType)
        return newBuilder
    end,

    AddUnit = function(self, unit, dontAssign)
        for k,v in self.ConsumptionUnits do
            if EntityCategoryContains(v.Category, unit) then
                table.insert(v.Units, { Unit = unit, Status = true })
                table.insert(v.UnitsList, unit)
                v.Count = v.Count + 1

                if not unit.BuilderManagerData then
                    unit.BuilderManagerData = {}
                end
                unit.BuilderManagerData.EngineerManager = self
                unit.BuilderManagerData.LocationType = self.LocationType

                if not unit.BuilderManagerData.CallbacksSetup then
                    unit.BuilderManagerData.CallbacksSetup = true
                    -- Callbacks here
                    local deathFunction = function(unit)
                        unit.BuilderManagerData.EngineerManager:RemoveUnit(unit)
                    end

                    import('/lua/scenariotriggers.lua').CreateUnitDestroyedTrigger(deathFunction, unit)

                    local newlyCapturedFunction = function(unit, captor)
                        local aiBrain = captor:GetAIBrain()
                        --LOG('*AI DEBUG: ENGINEER: I was Captured by '..aiBrain.Nickname..'!')
                        if aiBrain.BuilderManagers then
                            local engManager = aiBrain.BuilderManagers[captor.BuilderManagerData.LocationType].EngineerManager
                            if engManager then
                                engManager:AddUnit(unit)
                            end
                        end
                    end

                    import('/lua/scenariotriggers.lua').CreateUnitCapturedTrigger(nil, newlyCapturedFunction, unit)

                    if EntityCategoryContains(categories.ENGINEER, unit) then
                        local unitConstructionFinished = function(unit, finishedUnit)
                                                    -- Call function on builder manager; let it handle the finish of work
                                                    local aiBrain = unit:GetAIBrain()
                                                    local engManager = aiBrain.BuilderManagers[unit.BuilderManagerData.LocationType].EngineerManager
                                                    if engManager then
                                                        engManager:UnitConstructionFinished(unit, finishedUnit)
                                                    end
                        end
                        import('/lua/ScenarioTriggers.lua').CreateUnitBuiltTrigger(unitConstructionFinished, unit, categories.ALLUNITS)

                        local unitConstructionStarted = function(unit, unitBeingBuilt)
                                                    local aiBrain = unit:GetAIBrain()
                                                    local engManager = aiBrain.BuilderManagers[unit.BuilderManagerData.LocationType].EngineerManager
                                                    if engManager then
                                                        engManager:UnitConstructionStarted(unit, unitBeingBuilt)
                                                    end
                        end
                        import('/lua/ScenarioTriggers.lua').CreateStartBuildTrigger(unitConstructionStarted, unit, categories.ALLUNITS)
                    end
                end

                if not dontAssign then
                    --self:AssignEngineerTask(unit)
                    self:ForkThread(self.InitialWait, unit)
                end

                return
            end
        end
    end,

    GetNumUnits = function(self, unitType)
        if self.ConsumptionUnits[unitType] then
            return self.ConsumptionUnits[unitType].Count
        end
        return 0
    end,

    GetNumCategoryUnits = function(self, unitType, category)
        if self.ConsumptionUnits[unitType] then
            local numUnits = EntityCategoryCount(category, self.ConsumptionUnits[unitType].UnitsList)
            --LOG('*AI DEBUG: '..self.Brain.Nickname..' - GetNumCategoryUnits returns '..numUnits..' at '..self.LocationType)
            return EntityCategoryCount(category, self.ConsumptionUnits[unitType].UnitsList)
        end
        return 0
    end,

    GetNumCategoryBeingBuilt = function(self, category, engCategory)
        return table.getn(self:GetEngineersBuildingCategory(category, engCategory))
    end,

    GetEngineersBuildingCategory = function(self, category, engCategory)
        local engs = self:GetUnits('Engineers', engCategory)
        local units = {}
        for k,v in engs do
            if v.Dead then
                continue
            end

            if not v:IsUnitState('Building') then
                continue
            end

            local beingBuiltUnit = v.UnitBeingBuilt
            if not beingBuiltUnit or beingBuiltUnit.Dead then
                continue
            end

            if not EntityCategoryContains(category, beingBuiltUnit) then
                continue
            end

            table.insert(units, v)
        end
        return units
    end,

    GetEngineerFactionIndex = function(self, engineer)
        if EntityCategoryContains(categories.UEF, engineer) then
            return 1
        elseif EntityCategoryContains(categories.AEON, engineer) then
            return 2
        elseif EntityCategoryContains(categories.CYBRAN, engineer) then
            return 3
        elseif EntityCategoryContains(categories.SERAPHIM, engineer) then
            return 4
        else
            return 5
        end
    end,

    UnitFromCustomFaction = function(self, engineer)
        local customFactions = self.Brain.CustomFactions
        for k,v in customFactions do
            if EntityCategoryContains(v.customCat, engineer) then
                LOG('*AI DEBUG: UnitFromCustomFaction: '..k)
                return k
            end
        end
    end,

    GetBuildingId = function(self, engineer, buildingType)
        local faction = self:GetEngineerFactionIndex(engineer)
        if faction > 4 then
            if self:UnitFromCustomFaction(engineer) then
                faction = self:UnitFromCustomFaction(engineer)
                LOG('*AI DEBUG: GetBuildingId faction: '..faction)
                return self.Brain:DecideWhatToBuild(engineer, buildingType, self.Brain.CustomFactions[faction])
            end
        else
            return self.Brain:DecideWhatToBuild(engineer, buildingType, import('/lua/BuildingTemplates.lua').BuildingTemplates[faction])
        end
    end,

    GetEngineersQueued = function(self, buildingType)
        local engs = self:GetUnits('Engineers', categories.ALLUNITS)
        local units = {}
        for k,v in engs do
            if v.Dead then
                continue
            end

            if not v.EngineerBuildQueue or table.getn(v.EngineerBuildQueue) == 0 then
                continue
            end

            local buildingId = self:GetBuildingId(v, buildingType)
            local found = false
            for num, data in v.EngineerBuildQueue do
                if data[1] == buildingId then
                    found = true
                    break
                end
            end

            if not found then
                continue
            end

            table.insert(units, v)
        end
        return units
    end,

    GetEngineersBuildQueue = function(self, buildingType)
        local engs = self:GetUnits('Engineers', categories.ALLUNITS)
        local units = {}
        for k,v in engs do
            if v.Dead then
                continue
            end

            if not v.EngineerBuildQueue or table.getn(v.EngineerBuildQueue) == 0 then
                continue
            end
            local buildName = v.EngineerBuildQueue[1][1]
            local buildBp = self.Brain:GetUnitBlueprint(buildName)
            local buildingTypes = SUtils.split(buildingType, ' ')
            local found = false
            local count = 0
            for x,z in buildingTypes do
                if buildBp.CategoriesHash[z] then
                    count = count + 1
                end
                if table.getn(buildingTypes) == count then found = true end
                if found then break end
            end

            if not found then
                continue
            end

            table.insert(units, v)
        end
        return units
    end,

    GetEngineersWantingAssistance = function(self, category, engCategory)
        local testUnits = self:GetEngineersBuildingCategory(category, engCategory)

        local retUnits = {}
        for k,v in testUnits do
            if v.DesiresAssist == false then
                continue
            end

            if v.NumAssistees and table.getn(v:GetGuards()) >= v.NumAssistees then
                continue
            end

            table.insert(retUnits, v)
        end
        return retUnits
    end,

    GetUnits = function(self, unitType, category)
        if self.ConsumptionUnits[unitType] then
            return EntityCategoryFilterDown(category, self.ConsumptionUnits[unitType].UnitsList)
        end
        return {}
    end,

    RemoveUnit = function(self, unit)
        local guards = unit:GetGuards()
        for k,v in guards do
            if not v.Dead and v.AssistPlatoon then
                if self.Brain.Sorian and self.Brain:PlatoonExists(v.AssistPlatoon) then
                    v.AssistPlatoon:ForkThread(v.AssistPlatoon.SorianEconAssistBody)
                elseif self.Brain:PlatoonExists(v.AssistPlatoon) then
                    v.AssistPlatoon:ForkThread(v.AssistPlatoon.EconAssistBody)
                else
                    v.AssistPlatoon = nil
                end
            end
        end

        local found = false
        for k,v in self.ConsumptionUnits do
            if EntityCategoryContains(v.Category, unit) then
                for num,sUnit in v.Units do
                    if sUnit.Unit == unit then
                        table.remove(v.Units, num)
                        table.remove(v.UnitsList, num)
                        v.Count = v.Count - 1
                        found = true
                        break
                    end
                end
            end
            if found then
                break
            end
        end

        self.Brain:RemoveConsumption(self.LocationType, unit)
    end,

    ReassignUnit = function(self, unit)
        local managers = self.Brain.BuilderManagers
        local bestManager = false
        local distance = false
        local unitPos = unit:GetPosition()
        for k,v in managers do
            if v.FactoryManager:GetNumCategoryFactories(categories.ALLUNITS) > 0 or v == 'MAIN' then
                local checkDistance = VDist3(v.EngineerManager:GetLocationCoords(), unitPos)
                if not distance or checkDistance < distance then
                    distance = checkDistance
                    bestManager = v.EngineerManager
                end
            end
        end
        self:RemoveUnit(unit)
        if bestManager and not unit.Dead then
            bestManager:AddUnit(unit)
        end
    end,

    TaskFinished = function(self, unit)
        if VDist3(self.Location, unit:GetPosition()) > self.Radius and not EntityCategoryContains(categories.COMMAND, unit) then
            self:ReassignUnit(unit)
        else
            self:AssignEngineerTask(unit)
        end
    end,

    UnitConstructionStarted = function(self, unit, unitBeingBuilt)
        if EntityCategoryContains(categories.FACTORY, unitBeingBuilt) then
            self:AddConsumption(unit, 'Upgrades', unitBeingBuilt)
        elseif EntityCategoryContains(categories.EXPERIMENTAL + categories.MOBILE, unitBeingBuilt) then
            self:AddConsumption(unit, 'Units', unitBeingBuilt)
        elseif EntityCategoryContains(categories.MASSEXTRACTION + categories.MASSFABRICATION + categories.ENERGYPRODUCTION, unitBeingBuilt) then
            self:AddConsumption(unit, 'Resources', unitBeingBuilt)
        elseif EntityCategoryContains(categories.DEFENSE, unitBeingBuilt) then
            self:AddConsumption(unit, 'Defenses', unitBeingBuilt)
        elseif EntityCategoryContains(categories.ENGINEER, unitBeingBuilt) then
            self:AddConsumption(unit, 'Engineers', unitBeingBuilt)
        elseif EntityCategoryContains(categories.STRUCTURE, unitBeingBuilt) then
            self:AddConsumption(unit, 'Upgrades', unitBeingBuilt)
        else
            WARN('*AI DEBUG: Unknown consumption type for UnitId - ' .. unitBeingBuilt:GetUnitId())
        end
    end,

    AddConsumption = function(self, unit, consumptionType, unitBeingBuilt)
        self.Brain:AddConsumption(self.LocationType, consumptionType, unit, unitBeingBuilt)
    end,

    UnitConstructionFinished = function(self, unit, finishedUnit)
        if EntityCategoryContains(categories.FACTORY * categories.STRUCTURE, finishedUnit) and finishedUnit:GetAIBrain():GetArmyIndex() == self.Brain:GetArmyIndex() then
            self.Brain.BuilderManagers[self.LocationType].FactoryManager:AddFactory(finishedUnit)
        end
        if finishedUnit:GetAIBrain():GetArmyIndex() == self.Brain:GetArmyIndex() then
            self:AddUnit(finishedUnit)
        end
        local guards = unit:GetGuards()
        for k,v in guards do
            if not v.Dead and v.AssistPlatoon then
                if self.Brain.Sorian and self.Brain:PlatoonExists(v.AssistPlatoon) then
                    v.AssistPlatoon:ForkThread(v.AssistPlatoon.SorianEconAssistBody)
                elseif self.Brain:PlatoonExists(v.AssistPlatoon) then
                    v.AssistPlatoon:ForkThread(v.AssistPlatoon.EconAssistBody)
                else
                    v.AssistPlatoon = nil
                end
            end
        end
        self.Brain:RemoveConsumption(self.LocationType, unit)
    end,

    EngineerWaiting = function(self, unit)
        WaitSeconds(5)
        self:AssignEngineerTask(unit)
    end,

    InitialWait = function(self, unit)
        WaitSeconds(2)
        self:AssignEngineerTask(unit)
    end,

    AssignTimeout = function(self, builderName)
        local oldPri = self:GetBuilderPriority(builderName)
        if oldPri then
            self:SetBuilderPriority(builderName, 0, true)
        end
    end,

    GetEngineerPlatoonTemplate = function(self, templateName)
        local templateData = PlatoonTemplates[templateName]
        if not templateData then
            error('*AI ERROR: Invalid platoon template named - ' .. templateName)
        end
        if not templateData.Plan then
            error('*AI ERROR: PlatoonTemplate named: ' .. templateName .. ' does not have a Plan')
        end
        if not templateData.GlobalSquads then
            error('*AI ERROR: PlatoonTemplate named: ' .. templateName .. ' does not have a GlobalSquads')
        end
        local template = {
            templateData.Name,
            templateData.Plan,
            unpack(templateData.GlobalSquads)
        }
        return template
    end,

    DelayAssign = function(self, unit)
        if not unit.DelayThread then
            unit.DelayThread = unit:ForkThread(self.DelayAssignBody, self)
        end
    end,

    DelayAssignBody = function(unit, manager)
        WaitSeconds(1)
        if not unit.Dead then
            manager:AssignEngineerTask(unit)
        end
        unit.DelayThread = nil
    end,

    AssignEngineerTask = function(self, unit)
        unit.DesiresAssist = false
        unit.NumAssistees = nil
        unit.MinNumAssistees = nil

        if self.AssigningTask then
            DelayAssign(self, unit)
            return
        else
            self.AssigningTask = true
        end

        local builder = self:GetHighestBuilder('Any', {unit})
        if builder then
            -- Fork off the platoon here
            local template = self:GetEngineerPlatoonTemplate(builder:GetPlatoonTemplate())
            local hndl = self.Brain:MakePlatoon(template[1], template[2])
            self.Brain:AssignUnitsToPlatoon(hndl, {unit}, 'support', 'none')
            unit.PlatoonHandle = hndl

            --if EntityCategoryContains(categories.COMMAND, unit) then
            --    LOG('*AI DEBUG: ARMY '..self.Brain.Nickname..': Engineer Manager Forming - '..builder.BuilderName..' - Priority: '..builder:GetPriority())
            --end

            --LOG('*AI DEBUG: ARMY ', repr(self.Brain:GetArmyIndex()),': Engineer Manager Forming - ',repr(builder.BuilderName),' - Priority: ', builder:GetPriority())
            hndl.PlanName = template[2]

            --If we have specific AI, fork that AI thread
            if builder:GetPlatoonAIFunction() then
                hndl:StopAI()
                local aiFunc = builder:GetPlatoonAIFunction()
                hndl:ForkAIThread(import(aiFunc[1])[aiFunc[2]])
            end
            if builder:GetPlatoonAIPlan() then
                hndl.PlanName = builder:GetPlatoonAIPlan()
                hndl:SetAIPlan(hndl.PlanName)
            end

            --If we have additional threads to fork on the platoon, do that as well.
            if builder:GetPlatoonAddPlans() then
                for papk, papv in builder:GetPlatoonAddPlans() do
                    hndl:ForkThread(hndl[papv])
                end
            end

            if builder:GetPlatoonAddFunctions() then
                for pafk, pafv in builder:GetPlatoonAddFunctions() do
                    hndl:ForkThread(import(pafv[1])[pafv[2]])
                end
            end

            if builder:GetPlatoonAddBehaviors() then
                for pafk, pafv in builder:GetPlatoonAddBehaviors() do
                    hndl:ForkThread(import('/lua/ai/AIBehaviors.lua')[pafv])
                end
            end

            hndl.Priority = builder:GetPriority()
            hndl.BuilderName = builder:GetBuilderName()

            hndl:SetPlatoonData(builder:GetBuilderData(self.LocationType))

            if hndl.PlatoonData.DesiresAssist then
                unit.DesiresAssist = hndl.PlatoonData.DesiresAssist
            else
                unit.DesiresAssist = true
            end

            if hndl.PlatoonData.NumAssistees then
                unit.NumAssistees = hndl.PlatoonData.NumAssistees
            end

            if hndl.PlatoonData.MinNumAssistees then
                unit.MinNumAssistees = hndl.PlatoonData.MinNumAssistees
            end

            builder:StoreHandle(hndl)
            self.AssigningTask = false
            return
        end
        self.AssigningTask = false
        self:ForkThread(self.EngineerWaiting, unit)
    end,

    ManagerLoopBody = function(self,builder,bType)
        if builder.OldPriority and not builder.SetByStrat then
            builder:ResetPriority()
        end
        BuilderManager.ManagerLoopBody(self,builder,bType)
    end,

    BuilderParamCheck = function(self,builder,params)
        local unit = params[1]

        builder:FormDebug()

        -- Check if the category of the unit matches the category of the builder
        local template = self:GetEngineerPlatoonTemplate(builder:GetPlatoonTemplate())
        if not unit.Dead and EntityCategoryContains(template[3][1], unit) and builder:CheckInstanceCount() then
            return true
        end

        -- Nope
        return false
    end,
}

function CreateEngineerManager(brain, lType, location, radius)
    local em = EngineerManager()
    em:Create(brain, lType, location, radius)
    return em
end
