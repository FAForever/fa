--****************************************************************************
--**  File     :  /lua/sim/EngineerManager.lua
--**  Summary  : Manage engineers for a location
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local BuilderManager = import("/lua/sim/buildermanager.lua").BuilderManager
local SUtils = import("/lua/ai/sorianutilities.lua")
local AIUtils = import("/lua/ai/aiutilities.lua")
local Builder = import("/lua/sim/builder.lua")

local TableGetn = table.getn

---@class EngineerManager : BuilderManager
---@field Location Vector
---@field Radius number
EngineerManager = Class(BuilderManager) {
    ---@param self EngineerManager
    ---@param brain AIBrain
    ---@param lType LocationType
    ---@param location Vector
    ---@param radius number
    ---@return boolean
    Create = function(self, brain, lType, location, radius)
        BuilderManager.Create(self,brain, lType, location, radius)

        if not lType or not location or not radius then
            error('*PLATOOM FORM MANAGER ERROR: Invalid parameters; requires locationType, location, and radius')
            return false
        end

        -- backwards compatibility for mods
        self.Location = self.Location or location
        self.Radius = self.Radius or radius
        self.LocationType = self.LocationType or lType

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

    -- Universal on/off functions
    ---@param self EngineerManager
    ---@param group table
    EnableGroup = function(self, group)
        for k,v in group.Units do
            if not v.Status and v.Unit and not v.Unit.Dead then
                v.Unit:OnUnpaused()
                v.Status = true
            end
        end
    end,

    -- Check to see if the unit is buildings something in the category given
    ---@param unit Unit
    ---@param econ any unused
    ---@param pauseVal number
    ---@param category EntityCategory
    ---@return boolean
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
    ---@param unit Unit
    ---@param econ any unused
    ---@param pauseVal number
    ---@param category EntityCategory
    ---@return boolean
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

    ---@param unit Unit
    ---@param econ any unused
    ---@param pauseVal number
    ---@param category EntityCategory
    AssistCheck = function(unit, econ, pauseVal, category)
    end,

    -- Functions for when an AI Brain's mass runs dry
    ---@param self EngineerManager
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

    ---@param self EngineerManager
    LowMassRepeatThread = function(self)
        coroutine.yield(30)
        if self.Brain.LowMassMode then
            self:LowMass()
        end
    end,

    ---@param self EngineerManager
    RestoreMass = function(self)
        --LOG('*AI DEBUG: Activating Shut down mass units')
        self.Brain.LowMassMode = false

        -- enable engineers
        self:EnableGroup(self.ConsumptionUnits.Engineers)
    end,

    ---@param self EngineerManager
    ---@param econ any unused
    ---@param pauseVal number
    ---@return boolean
    MassCheck = function(self, econ, pauseVal)
        local massRequest = econ.MassRequestOverTime - pauseVal
        if econ.MassIncome > (massRequest * 0.9) then
            --LOG('*AI DEBUG: Under the cutoff')
            return true
        end
        return false
    end,

    ---@param self EngineerManager
    ---@param group string
    ---@param econ any unused
    ---@param pauseVal number
    ---@param unitCheckFunc any
    ---@param category EntityCategory
    ---@return number | true
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

    -- Functions for when an AI Brain's energy runs dry
    ---@param self EngineerManager
    ---@param econ any unused
    ---@param pauseVal number
    ---@return boolean
    EnergyCheck = function(self, econ, pauseVal)
        local energyRequest = econ.EnergyRequestOverTime - pauseVal
        if econ.EnergyIncome > (energyRequest * 0.9) then
            --LOG('*AI DEBUG: Under the cutoff')
            return true
        end
        return false
    end,

    ---@param self EngineerManager
    ---@param group string
    ---@param econ any unused
    ---@param pauseVal number
    ---@param unitCheckFunc any
    ---@param category EntityCategory
    ---@return number | true
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

    ---@param self EngineerManager
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

    ---@param self EngineerManager
    LowEnergyRepeatThread = function(self)
        coroutine.yield(30)
        if self.Brain.LowEnergyMode then
            self:LowEnergy()
        end
    end,

    ---@param self EngineerManager
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
    ---@param unit Unit
    ---@param econ any unused
    ---@param pauseVal number
    ---@return number | true
    MassDrainCheck = function(unit, econ, pauseVal)
        if econ.MassIncome > econ.MassRequestOverTime then
            return true
        end
        return pauseVal
    end,

    -- Builder based functions
    ---@param self EngineerManager
    ---@param builderData table
    ---@param locationType string
    ---@param builderType string
    ---@return any
    AddBuilder = function(self, builderData, locationType, builderType)
        local newBuilder = Builder.CreateEngineerBuilder(self.Brain, builderData, locationType)
        self:AddInstancedBuilder(newBuilder, builderType)
        return newBuilder
    end,

    ---@param self EngineerManager
    ---@param unit Unit
    ---@param dontAssign boolean
    AddUnit = function(self, unit, dontAssign)
        --LOG('+ AddUnit')
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

                    import("/lua/scenariotriggers.lua").CreateUnitDestroyedTrigger(deathFunction, unit)

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

                    import("/lua/scenariotriggers.lua").CreateUnitCapturedTrigger(nil, newlyCapturedFunction, unit)

                    if EntityCategoryContains(categories.ENGINEER - categories.STATIONASSISTPOD, unit) then
                        local unitConstructionFinished = function(unit, finishedUnit)
                                                    -- Call function on builder manager; let it handle the finish of work
                                                    local aiBrain = unit:GetAIBrain()
                                                    local engManager = aiBrain.BuilderManagers[unit.BuilderManagerData.LocationType].EngineerManager
                                                    if engManager then
                                                        engManager:UnitConstructionFinished(unit, finishedUnit)
                                                    end
                        end
                        import("/lua/scenariotriggers.lua").CreateUnitBuiltTrigger(unitConstructionFinished, unit, categories.ALLUNITS)

                    end
                end

                if not dontAssign then
                    self:ForkEngineerTask(unit)
                end

                return
            end
        end
    end,

    ---@param self EngineerManager
    ---@param unitType string
    ---@return number
    GetNumUnits = function(self, unitType)
        if self.ConsumptionUnits[unitType] then
            return self.ConsumptionUnits[unitType].Count
        end
        return 0
    end,

    ---@param self EngineerManager
    ---@param unitType string
    ---@param category EntityCategory
    ---@return number
    GetNumCategoryUnits = function(self, unitType, category)
        if self.ConsumptionUnits[unitType] then
            return EntityCategoryCount(category, self.ConsumptionUnits[unitType].UnitsList)
        end
        return 0
    end,

    ---@param self EngineerManager
    ---@param category EntityCategory
    ---@param engCategory EntityCategory
    ---@return integer
    GetNumCategoryBeingBuilt = function(self, category, engCategory)
        return TableGetn(self:GetEngineersBuildingCategory(category, engCategory))
    end,

    ---@param self EngineerManager
    ---@param category EntityCategory
    ---@param engCategory EntityCategory
    ---@return table
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

    ---@param self EngineerManager
    ---@param engineer Unit
    ---@return integer
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

    ---@param self EngineerManager
    ---@param engineer Unit
    ---@return any
    UnitFromCustomFaction = function(self, engineer)
        local customFactions = self.Brain.CustomFactions
        for k,v in customFactions do
            if EntityCategoryContains(v.customCat, engineer) then
                LOG('*AI DEBUG: UnitFromCustomFaction: '..k)
                return k
            end
        end
    end,

    ---@param self EngineerManager
    ---@param engineer Unit
    ---@param buildingType string
    ---@return any
    GetBuildingId = function(self, engineer, buildingType)
        local faction = self:GetEngineerFactionIndex(engineer)
        if faction > 4 then
            if self:UnitFromCustomFaction(engineer) then
                faction = self:UnitFromCustomFaction(engineer)
                LOG('*AI DEBUG: GetBuildingId faction: '..faction)
                return self.Brain:DecideWhatToBuild(engineer, buildingType, self.Brain.CustomFactions[faction])
            end
        else
            return self.Brain:DecideWhatToBuild(engineer, buildingType, import("/lua/buildingtemplates.lua").BuildingTemplates[faction])
        end
    end,

    ---@param self EngineerManager
    ---@param buildingType string
    ---@return table
    GetEngineersQueued = function(self, buildingType)
        local engs = self:GetUnits('Engineers', categories.ALLUNITS)
        local units = {}
        for k,v in engs do
            if v.Dead then
                continue
            end

            if not v.EngineerBuildQueue or table.empty(v.EngineerBuildQueue) then
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

    ---@param self EngineerManager
    ---@param buildingType string
    ---@return table
    GetEngineersBuildQueue = function(self, buildingType)
        local engs = self:GetUnits('Engineers', categories.ALLUNITS)
        local units = {}
        for k,v in engs do
            if v.Dead then
                continue
            end

            if not v.EngineerBuildQueue or table.empty(v.EngineerBuildQueue) then
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
                if TableGetn(buildingTypes) == count then found = true end
                if found then break end
            end

            if not found then
                continue
            end

            table.insert(units, v)
        end
        return units
    end,

    ---@param self EngineerManager
    ---@param category EntityCategory
    ---@param engCategory EntityCategory
    ---@return table
    GetEngineersWantingAssistance = function(self, category, engCategory)
        local testUnits = self:GetEngineersBuildingCategory(category, engCategory)

        local retUnits = {}
        for k,v in testUnits do
            if v.DesiresAssist == false then
                continue
            end

            if v.NumAssistees and TableGetn(v:GetGuards()) >= v.NumAssistees then
                continue
            end

            table.insert(retUnits, v)
        end
        return retUnits
    end,

    ---@param self EngineerManager
    ---@param unitType string
    ---@param category EntityCategory
    ---@return UserUnit[]|nil
    GetUnits = function(self, unitType, category)
        if self.ConsumptionUnits[unitType] then
            return EntityCategoryFilterDown(category, self.ConsumptionUnits[unitType].UnitsList)
        end
        return {}
    end,

    ---@param self EngineerManager
    ---@param unit Unit
    RemoveUnit = function(self, unit)

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
    end,

    ---@param self EngineerManager
    ---@param unit Unit
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

    ---@param manager EngineerManager
    ---@param unit Unit
    TaskFinished = function(manager, unit)
        if VDist3(manager.Location, unit:GetPosition()) > manager.Radius and not EntityCategoryContains(categories.COMMAND, unit) then
            manager:ReassignUnit(unit)
        else
            manager:ForkEngineerTask(unit)
        end
    end,

    ---@param self EngineerManager
    ---@param unit Unit
    ---@param finishedUnit Unit
    UnitConstructionFinished = function(self, unit, finishedUnit)
        if EntityCategoryContains(categories.FACTORY * categories.STRUCTURE, finishedUnit) and finishedUnit:GetAIBrain():GetArmyIndex() == self.Brain:GetArmyIndex() then
            self.Brain.BuilderManagers[self.LocationType].FactoryManager:AddFactory(finishedUnit)
        end
        if finishedUnit:GetAIBrain():GetArmyIndex() == self.Brain:GetArmyIndex() then
            self:AddUnit(finishedUnit)
        end
    end,

    ---@param self EngineerManager
    ---@param builderName string
    AssignTimeout = function(self, builderName)
        local oldPri = self:GetBuilderPriority(builderName)
        if oldPri then
            self:SetBuilderPriority(builderName, 0, true)
        end
    end,

    ---@param self EngineerManager
    ---@param templateName string
    ---@return table
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

    ---@param manager EngineerManager
    ---@param unit Unit
    ForkEngineerTask = function(manager, unit)
        if unit.ForkedEngineerTask then
            KillThread(unit.ForkedEngineerTask)
            unit.ForkedEngineerTask = unit:ForkThread(manager.Wait, manager, 3)
        else
            unit.ForkedEngineerTask = unit:ForkThread(manager.Wait, manager, 20)
        end
    end,

    ---@param manager EngineerManager
    ---@param unit Unit
    ---@param delaytime number
    DelayAssign = function(manager, unit, delaytime)
        if unit.ForkedEngineerTask then
            KillThread(unit.ForkedEngineerTask)
        end
        unit.ForkedEngineerTask = unit:ForkThread(manager.Wait, manager, delaytime or 10)
    end,

    ---@param unit Unit
    ---@param manager EngineerManager
    ---@param ticks integer
    Wait = function(unit, manager, ticks)
        coroutine.yield(ticks)
        if not unit.Dead then
            manager:AssignEngineerTask(unit)
        end
    end,

    ---@param manager EngineerManager
    ---@param unit Unit
    EngineerWaiting = function(manager, unit)
        coroutine.yield(50)
        if not unit.Dead then
            manager:AssignEngineerTask(unit)
        end
    end,

    ---@param self EngineerManager
    ---@param unit Unit
    AssignEngineerTask = function(self, unit)
        --LOG('+ AssignEngineerTask')
        if unit.UnitBeingAssist or unit.UnitBeingBuilt or unit.UnitBeingBuiltBehavior or unit.Combat then
            self:DelayAssign(unit, 50)
            return
        end

        unit.DesiresAssist = false
        unit.NumAssistees = nil
        unit.MinNumAssistees = nil

        if self.AssigningTask then
            self:DelayAssign(unit, 50)
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
                    hndl:ForkThread(import("/lua/ai/aibehaviors.lua")[pafv])
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
        self:DelayAssign(unit, 50)
    end,

    ---@param self EngineerManager
    ---@param builder Unit
    ---@param params any
    ---@return boolean
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

---@param brain AIBrain
---@param lType any
---@param location Vector
---@param radius number
---@return EngineerManager
function CreateEngineerManager(brain, lType, location, radius)
    local em = EngineerManager()
    em:Create(brain, lType, location, radius)
    return em
end


-- kept for mod backwards compatibility
local AIBuildUnits = import("/lua/ai/aibuildunits.lua")