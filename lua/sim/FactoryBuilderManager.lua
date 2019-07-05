-- ***************************************************************************
-- *
-- **  File     :  /lua/sim/BuilderManager.lua
-- **
-- **  Summary  : Manage builders
-- **
-- **  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local BuilderManager = import('/lua/sim/BuilderManager.lua').BuilderManager
local AIUtils = import('/lua/ai/aiutilities.lua')
local Builder = import('/lua/sim/Builder.lua')
local AIBuildUnits = import('/lua/ai/aibuildunits.lua')

FactoryBuilderManager = Class(BuilderManager) {
    Create = function(self, brain, lType, location, radius, useCenterPoint)
        BuilderManager.Create(self,brain)

        if not lType or not location or not radius then
            error('*FACTORY BUILDER MANAGER ERROR: Invalid parameters; requires locationType, location, and radius')
            return false
        end

        local builderTypes = { 'Air', 'Land', 'Sea', 'Gate', }
        for k,v in builderTypes do
            self:AddBuilderType(v)
        end

        self.Location = location
        self.Radius = radius
        self.LocationType = lType
        self.RallyPoint = false

        self.FactoryList = {}

        self.LocationActive = false

        self.RandomSamePriority = true
        self.PlatoonListEmpty = true

        self.UseCenterPoint = useCenterPoint or false
        self:ForkThread(self.RallyPointMonitor)
    end,

    RallyPointMonitor = function(self)
        while true do
            if self.LocationActive and self.RallyPoint then
                -- LOG('*AI DEBUG: Checking Active Rally Point')
                local newRally = false
                local bestDist = 99999
                local rallyheight = GetTerrainHeight(self.RallyPoint[1], self.RallyPoint[3])
                if self.Brain:GetNumUnitsAroundPoint(categories.STRUCTURE, self.RallyPoint, 15, 'Ally') > 0 then
                    -- LOG('*AI DEBUG: Searching for a new Rally Point Location')
                    for x = -30, 30, 5 do
                        for z = -30, 30, 5 do
                            local height = GetTerrainHeight(self.RallyPoint[1] + x, self.RallyPoint[3] + z)
                            if GetSurfaceHeight(self.RallyPoint[1] + x, self.RallyPoint[3] + z) > height or rallyheight > height + 10 or rallyheight < height - 10 then
                                continue
                            end
                            local tempPos = { self.RallyPoint[1] + x, height, self.RallyPoint[3] + z }
                            if self.Brain:GetNumUnitsAroundPoint(categories.STRUCTURE, tempPos, 15, 'Ally') > 0 then
                                continue
                            end
                            if not newRally or VDist2(tempPos[1], tempPos[3], self.RallyPoint[1], self.RallyPoint[3]) < bestDist then
                                newRally = tempPos
                                bestDist = VDist2(tempPos[1], tempPos[3], self.RallyPoint[1], self.RallyPoint[3])
                            end
                        end
                    end
                    if newRally then
                        self.RallyPoint = newRally
                        -- LOG('*AI DEBUG: Setting a new Rally Point Location')
                        for k,v in self.FactoryList do
                            IssueClearFactoryCommands({v})
                            IssueFactoryRallyPoint({v}, self.RallyPoint)
                        end
                    end
                end
            end
            WaitSeconds(300)
        end
    end,

    AddBuilder = function(self, builderData, locationType)
        local newBuilder = Builder.CreateFactoryBuilder(self.Brain, builderData, locationType)
        if newBuilder:GetBuilderType() == 'All' then
            for k,v in self.BuilderData do
                self:AddInstancedBuilder(newBuilder, k)
            end
        else
            self:AddInstancedBuilder(newBuilder)
        end
        return newBuilder
    end,

    HasPlatoonList = function(self)
        return self.PlatoonListEmpty
    end,

    GetNumFactories = function(self)
        if self.FactoryList then
            return table.getn(self.FactoryList)
        end
        return 0
    end,

    GetNumCategoryFactories = function(self, category)
        if self.FactoryList then
            return EntityCategoryCount(category, self.FactoryList)
        end
        return 0
    end,

    GetNumCategoryBeingBuilt = function(self, category, facCategory)
        return table.getn(self:GetFactoriesBuildingCategory(category, facCategory))
    end,

    GetFactoriesBuildingCategory = function(self, category, facCategory)
        local units = {}
        for k,v in EntityCategoryFilterDown(facCategory, self.FactoryList) do
            if v.Dead then
                continue
            end

            if not v:IsUnitState('Upgrading') and not v:IsUnitState('Building') then
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

    GetFactoriesWantingAssistance = function(self, category, facCatgory)
        local testUnits = self:GetFactoriesBuildingCategory(category, facCatgory)

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

    GetFactories = function(self, category)
        local retUnits = EntityCategoryFilterDown(category, self.FactoryList)
        return retUnits
    end,

    AddFactory = function(self,unit)
        if not self:FactoryAlreadyExists(unit) then
            table.insert(self.FactoryList, unit)
            unit.DesiresAssist = true
            if EntityCategoryContains(categories.LAND, unit) then
                self:SetupNewFactory(unit, 'Land')
            elseif EntityCategoryContains(categories.AIR, unit) then
                self:SetupNewFactory(unit, 'Air')
            elseif EntityCategoryContains(categories.NAVAL, unit) then
                self:SetupNewFactory(unit, 'Sea')
            else
                self:SetupNewFactory(unit, 'Gate')
            end
            self.LocationActive = true
        end
    end,

    FactoryAlreadyExists = function(self, factory)
        for k,v in self.FactoryList do
            if v == factory then
                return true
            end
        end
        return false
    end,

    SetupNewFactory = function(self,unit,bType)
        self:SetupFactoryCallbacks({unit}, bType)
        self:ForkThread(self.DelayRallyPoint, unit)
    end,

    SetupFactoryCallbacks = function(self,factories,bType)
        for k,v in factories do
            if not v.BuilderManagerData then
                v.BuilderManagerData = { FactoryBuildManager = self, BuilderType = bType, }

                local factoryDestroyed = function(v)
                                            -- Call function on builder manager; let it handle death of factory
                                            self:FactoryDestroyed(v)
                                        end
                import('/lua/ScenarioTriggers.lua').CreateUnitDestroyedTrigger(factoryDestroyed, v)

                local factoryNewlyCaptured = function(unit, captor)
                                            local aiBrain = captor:GetAIBrain()
                                            -- LOG('*AI DEBUG: FACTORY: I was Captured by '..aiBrain.Nickname..'!')
                                            if aiBrain.BuilderManagers then
                                                local facManager = aiBrain.BuilderManagers[captor.BuilderManagerData.LocationType].FactoryManager
                                                if facManager then
                                                    facManager:AddFactory(unit)
                                                end
                                            end
                                        end
                import('/lua/ScenarioTriggers.lua').CreateUnitCapturedTrigger(nil, factoryNewlyCaptured, v)

                local factoryWorkStart = function(factory, unitBeingBuilt)
                                            factory.BuilderManagerData.FactoryBuildManager:UnitConstructionStarted(factory, unitBeingBuilt)
                                        end
                import('/lua/ScenarioTriggers.lua').CreateStartBuildTrigger(factoryWorkStart, v, categories.ALLUNITS)

                local factoryWorkFinish = function(v, finishedUnit)
                                            -- Call function on builder manager; let it handle the finish of work
                                            self:FactoryFinishBuilding(v, finishedUnit)
                                        end
                import('/lua/ScenarioTriggers.lua').CreateUnitBuiltTrigger(factoryWorkFinish, v, categories.ALLUNITS)
            end
            self:ForkThread(self.DelayBuildOrder, v, bType, 0.1)
        end
    end,

    FactoryDestroyed = function(self, factory)
        local guards = factory:GetGuards()
        for k,v in guards do
            if not v.Dead and v.AssistPlatoon then
                if self.Brain:PlatoonExists(v.AssistPlatoon) then
                    v.AssistPlatoon:ForkThread(v.AssistPlatoon.EconAssistBody)
                else
                    v.AssistPlatoon = nil
                end
            end
        end
        for k,v in self.FactoryList do
            if v == factory then
                self.FactoryList[k] = nil
            end
        end
        for k,v in self.FactoryList do
            if not v.Dead then
                return
            end
        end
        self.LocationActive = false
        self.Brain:RemoveConsumption(self.LocationType, factory)
    end,

    DelayBuildOrder = function(self,factory,bType,time)
        local guards = factory:GetGuards()
        for k,v in guards do
            if not v.Dead and v.AssistPlatoon then
                if self.Brain:PlatoonExists(v.AssistPlatoon) then
                    v.AssistPlatoon:ForkThread(v.AssistPlatoon.EconAssistBody)
                else
                    v.AssistPlatoon = nil
                end
            end
        end
        if factory.DelayThread then
            return
        end
        factory.DelayThread = true
        WaitSeconds(time)
        factory.DelayThread = false
        self:AssignBuildOrder(factory,bType)
    end,

    GetFactoryFaction = function(self, factory)
        if EntityCategoryContains(categories.UEF, factory) then
            return 'UEF'
        elseif EntityCategoryContains(categories.AEON, factory) then
            return 'Aeon'
        elseif EntityCategoryContains(categories.CYBRAN, factory) then
            return 'Cybran'
        elseif EntityCategoryContains(categories.SERAPHIM, factory) then
            return 'Seraphim'
        elseif self.Brain.CustomFactions then
            return self:UnitFromCustomFaction(factory)
        end
        return false
    end,

    UnitFromCustomFaction = function(self, factory)
        local customFactions = self.Brain.CustomFactions
        for k,v in customFactions do
            if EntityCategoryContains(v.customCat, factory) then
                return v.cat
            end
        end
    end,

    GetFactoryTemplate = function(self, templateName, factory)
        local templateData = PlatoonTemplates[templateName]
        if not templateData then
            error('*AI ERROR: Invalid platoon template named - ' .. templateName)
        end
        if not templateData.FactionSquads then
            error('*AI ERROR: PlatoonTemplate named: ' .. templateName .. ' does not have a GlobalSquads')
        end
        local template = {
            templateData.Name,
            '',
        }

        local faction = self:GetFactoryFaction(factory)
        local customData = self.Brain.CustomUnits[templateName]
        if faction and templateData.FactionSquads[faction] then
            for k,v in templateData.FactionSquads[faction] do
                if customData and customData[faction] then
                    -- LOG('*AI DEBUG: Replacement unit found!')
                    local replacement = self:GetCustomReplacement(v, templateName, faction)
                    if replacement then
                        table.insert(template, replacement)
                    else
                        table.insert(template, v)
                    end
                else
                    table.insert(template, v)
                end
            end
        elseif faction and customData and customData[faction] then
            --LOG('*AI DEBUG: New unit found for '..templateName..'!')
            local Squad = nil
            if templateData.FactionSquads then
                -- get the first squad from the template
                for k,v in templateData.FactionSquads do
                    -- use this squad as base template for the replacement
                    Squad = table.copy(v[1])
                    -- flag this template as dummy
                    Squad[1] = "NoOriginalUnit"
                    break
                end
            end
            -- if we don't have a template use a dummy.
            if not Squad then
                -- this will only happen if we have a empty template. Warn the programmer!
                SPEW('*AI WARNING: No faction squad found for '..templateName..'. using Dummy! '..repr(templateData.FactionSquads) )
                Squad = { "NoOriginalUnit", 1, 1, "attack", "none" }
            end
            local replacement = self:GetCustomReplacement(Squad, templateName, faction)
            if replacement then
                table.insert(template, replacement)
            end
        end
        return template
    end,

    GetCustomReplacement = function(self, template, templateName, faction)
        local retTemplate = false
        local templateData = self.Brain.CustomUnits[templateName]
        if templateData and templateData[faction] then
            -- LOG('*AI DEBUG: Replacement for '..templateName..' exists.')
            local rand = Random(1,100)
            local possibles = {}
            for k,v in templateData[faction] do
                if rand <= v[2] or template[1] == 'NoOriginalUnit' then
                    -- LOG('*AI DEBUG: Insert possibility.')
                    table.insert(possibles, v[1])
                end
            end
            if table.getn(possibles) > 0 then
                rand = Random(1,table.getn(possibles))
                local customUnitID = possibles[rand]
                -- LOG('*AI DEBUG: Replaced with '..customUnitID)
                retTemplate = { customUnitID, template[2], template[3], template[4], template[5] }
            end
        end
        return retTemplate
    end,

    AssignBuildOrder = function(self,factory,bType)
        -- Find a builder the factory can build
        if factory.Dead then
            return
        end
        local builder = self:GetHighestBuilder(bType,{factory})
        if builder then
            local template = self:GetFactoryTemplate(builder:GetPlatoonTemplate(), factory)
            -- LOG('*AI DEBUG: ARMY ', repr(self.Brain:GetArmyIndex()),': Factory Builder Manager Building - ',repr(builder.BuilderName))
            self.Brain:BuildPlatoon(template, {factory}, 1)
        else
            -- No builder found setup way to check again
            self:ForkThread(self.DelayBuildOrder, factory, bType, 2)
        end
    end,

    UnitConstructionStarted = function(self, factory, unitBeingBuilt)
        if EntityCategoryContains(categories.FACTORY, unitBeingBuilt) then
            self:AddConsumption(factory, 'Upgrades', unitBeingBuilt)
        elseif EntityCategoryContains(categories.EXPERIMENTAL + categories.MOBILE, unitBeingBuilt) then
            self:AddConsumption(factory, 'Units', unitBeingBuilt)
        elseif EntityCategoryContains(categories.MASSEXTRACTION + categories.MASSFABRICATION + categories.ENERGYPRODUCTION, unitBeingBuilt) then
            self:AddConsumption(factory, 'Resources', unitBeingBuilt)
        elseif EntityCategoryContains(categories.DEFENSE, unitBeingBuilt) then
            self:AddConsumption(factory, 'Defenses', unitBeingBuilt)
        elseif EntityCategoryContains(categories.ENGINEER, unitBeingBuilt) then
            self:AddConsumption(factory, 'Engineers', unitBeingBuilt)
        elseif EntityCategoryContains(categories.STRUCTURE, unitBeingBuilt) then
            self:AddConsumption(factory, 'Upgrades', unitBeingBuilt)
        else
            WARN('*AI DEBUG: Unknown consumption type for UnitId - ' .. unitBeingBuilt:GetUnitId())
        end
    end,

    AddConsumption = function(self, factory, consumptionType, unitBeingBuilt)
        self.Brain:AddConsumption(self.LocationType, consumptionType, factory, unitBeingBuilt)
    end,

    FactoryFinishBuilding = function(self,factory,finishedUnit)
        if EntityCategoryContains(categories.ENGINEER, finishedUnit) then
            self.Brain.BuilderManagers[self.LocationType].EngineerManager:AddUnit(finishedUnit)
        elseif EntityCategoryContains(categories.FACTORY, finishedUnit) then
            self:AddFactory(finishedUnit)
        end
        self.Brain:RemoveConsumption(self.LocationType, factory)

        self:AssignBuildOrder(factory, factory.BuilderManagerData.BuilderType)
    end,

    -- Check if given factory can build the builder
    BuilderParamCheck = function(self,builder,params)
        -- params[1] is factory, no other params
        local template = self:GetFactoryTemplate(builder:GetPlatoonTemplate(), params[1])
        if not template then
            WARN('*Factory Builder Error: Could not find template named: ' .. builder:GetPlatoonTemplate())
            return false
        end

        -- This faction doesn't have unit of this type
        if table.getn(template) == 2 then
            return false
        end

        local personality = self.Brain:GetPersonality()
        local ptnSize = personality:GetPlatoonSize()

        -- This function takes a table of factories to determine if it can build
        return self.Brain:CanBuildPlatoon(template, params)
    end,

    DelayRallyPoint = function(self, factory)
        WaitSeconds(1)
        if not factory.Dead then
            self:SetRallyPoint(factory)
        end
    end,

    SetRallyPoint = function(self, factory)
        local position = factory:GetPosition()
        local rally = false

        if self.RallyPoint then
            IssueClearFactoryCommands({factory})
            IssueFactoryRallyPoint({factory}, self.RallyPoint)
            return true
        end

        local rallyType = 'Rally Point'
        if EntityCategoryContains(categories.NAVAL, factory) then
            rallyType = 'Naval Rally Point'
        end

        if not self.UseCenterPoint then
            -- Find closest marker to averaged location
            rally = AIUtils.AIGetClosestMarkerLocation(self, rallyType, position[1], position[3])
        elseif self.UseCenterPoint then
            -- use BuilderManager location
            rally = AIUtils.AIGetClosestMarkerLocation(self, rallyType, position[1], position[3])
            local expPoint = AIUtils.AIGetClosestMarkerLocation(self, 'Expansion Area', position[1], position[3])

            if expPoint and rally then
                local rallyPointDistance = VDist2(position[1], position[3], rally[1], rally[3])
                local expansionDistance = VDist2(position[1], position[3], expPoint[1], expPoint[3])

                if expansionDistance < rallyPointDistance then
                    rally = expPoint
                end
            end
        end

        -- Use factory location if no other rally or if rally point is far away
        if not rally or VDist2(rally[1], rally[3], position[1], position[3]) > 75 then
            -- DUNCAN - added to try and vary the rally points.
            position = AIUtils.RandomLocation(position[1],position[3])
            rally = position
        end

        IssueClearFactoryCommands({factory})
        IssueFactoryRallyPoint({factory}, rally)
        self.RallyPoint = rally
        return true
    end,
}

function CreateFactoryBuilderManager(brain, lType, location, radius, useCenterPoint)
    local fbm = FactoryBuilderManager()
    fbm:Create(brain, lType, location, radius, useCenterPoint)
    return fbm
end

