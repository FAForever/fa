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

        self.Engineers = { 
            TECH1 = { },
            TECH2 = { },
            TECH3 = { },
            EXPERIMENTAL = { },
            SUBCOMMANDER = { },
            COMMAND = { },
        }

        self.EngineersBeingBuilt = {
            TECH1 = { },
            TECH2 = { },
            TECH3 = { },
            EXPERIMENTAL = { },
            SUBCOMMANDER = { },
            COMMAND = { },
        }

        self:AddBuilderType('Any')
    end,

    --------------------------------------------------------------------------------------------
    -- builder interface

    -- This is where the majority of the magic happens. See the description of the same section
    -- in the file BuilderManager class for an extensive description


    ---@param self BuilderManager
    ---@param builderData BuilderSpec
    ---@param locationType LocationType
    ---@param builderType BuilderType
    ---@return Builder
    AddBuilder = function(self, builderData, locationType, builderType)
        local newBuilder = Builder.CreateEngineerBuilder(self.Brain, builderData, locationType)
        self:AddInstancedBuilder(newBuilder, builderType)
        return newBuilder
    end,

    --------------------------------------------------------------------------------------------
    -- builder list interface

    --------------------------------------------------------------------------------------------
    -- manager interface

    --------------------------------------------------------------------------------------------
    -- unit events

    --- Called by a unit as it starts being built
    ---@param self BaseAIBrain
    ---@param unit Unit
    OnUnitStartBeingBuilt = function(self, unit)
    end,

    --- Called by a unit as it is finished being built
    ---@param self BaseAIBrain
    ---@param unit Unit
    OnUnitFinishedBeingBuilt = function(self, unit)
    end,

    --- Called by a unit as it is destroyed
    ---@param self BaseAIBrain
    ---@param unit Unit
    OnUnitDestroyed = function(self, unit)
    end,

    --------------------------------------------------------------------------------------------
    -- properties

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
    ---@param builder BuilderSpec
    ---@param params { [1]: Unit }
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