-- ***************************************************************************
-- *
-- **  File     :  /lua/sim/BuilderManager.lua
-- **
-- **  Summary  : Manage builders
-- **
-- **  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local BuilderManager = import("/lua/sim/buildermanager.lua").BuilderManager
local AIUtils = import("/lua/ai/aiutilities.lua")
local Builder = import("/lua/sim/builder.lua")

local TableGetn = table.getn

---@class FactoryBuilderManager : BuilderManager
---@field Location Vector
---@field Radius number
---@field LocationType LocationType
---@field RallyPoint Vector | false
---@field LocationActive boolean
---@field RandomSamePriority boolean
---@field PlatoonListEmpty boolean
---@field UseCenterPoint boolean
FactoryBuilderManager = Class(BuilderManager) {
    ---@param self FactoryBuilderManager
    ---@param brain AIBrain
    ---@param lType any
    ---@param location Vector
    ---@param radius number
    ---@param useCenterPoint boolean
    ---@return boolean
    Create = function(self, brain, lType, location, radius, useCenterPoint)
        BuilderManager.Create(self,brain, lType, location, radius)

        if not lType or not location or not radius then
            error('*FACTORY BUILDER MANAGER ERROR: Invalid parameters; requires locationType, location, and radius')
            return false
        end

        local builderTypes = { 'Air', 'Land', 'Sea', 'Gate', }
        for k,v in builderTypes do
            self:AddBuilderType(v)
        end

        -- backwards compatibility for mods
        self.Location = self.Location or location
        self.Radius = self.Radius or radius
        self.LocationType = self.LocationType or lType

        self.RallyPoint = false

        self.FactoryList = {}

        self.LocationActive = false

        self.RandomSamePriority = true
        self.PlatoonListEmpty = true

        self.UseCenterPoint = useCenterPoint or false
        self:ForkThread(self.RallyPointMonitor)
    end,

    ---@param self FactoryBuilderManager
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

    ---@param self FactoryBuilderManager
    ---@param builderData BuilderSpec
    ---@param locationType LocationType
    ---@return boolean
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

    ---@param self FactoryBuilderManager
    ---@return boolean
    HasPlatoonList = function(self)
        return self.PlatoonListEmpty
    end,

    ---@param self FactoryBuilderManager
    ---@return integer
    GetNumFactories = function(self)
        if self.FactoryList then
            return TableGetn(self.FactoryList)
        end
        return 0
    end,

    ---@param self FactoryBuilderManager
    ---@param category EntityCategory
    ---@return number
    GetNumCategoryFactories = function(self, category)
        if self.FactoryList then
            return EntityCategoryCount(category, self.FactoryList)
        end
        return 0
    end,

    ---@param self FactoryBuilderManager
    ---@param category EntityCategory
    ---@param facCategory EntityCategory
    ---@return integer
    GetNumCategoryBeingBuilt = function(self, category, facCategory)
        return TableGetn(self:GetFactoriesBuildingCategory(category, facCategory))
    end,

    ---@param self FactoryBuilderManager
    ---@param category EntityCategory
    ---@param facCategory EntityCategory
    ---@return table
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

    ---@param self FactoryBuilderManager
    ---@param category EntityCategory
    ---@param facCatgory EntityCategory
    ---@return table
    GetFactoriesWantingAssistance = function(self, category, facCatgory)
        local testUnits = self:GetFactoriesBuildingCategory(category, facCatgory)

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

    ---@param self FactoryBuilderManager
    ---@param category EntityCategory
    ---@return UserUnit[]|nil
    GetFactories = function(self, category)
        local retUnits = EntityCategoryFilterDown(category, self.FactoryList)
        return retUnits
    end,

    ---@param self FactoryBuilderManager
    ---@param unit Unit
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

    ---@param self FactoryBuilderManager
    ---@param factory Unit
    ---@return boolean
    FactoryAlreadyExists = function(self, factory)
        for k,v in self.FactoryList do
            if v == factory then
                return true
            end
        end
        return false
    end,

    ---@param self FactoryBuilderManager
    ---@param unit Unit
    ---@param bType string
    SetupNewFactory = function(self,unit,bType)
        self:SetupFactoryCallbacks({unit}, bType)
        self:ForkThread(self.DelayRallyPoint, unit)
    end,

    ---@param self FactoryBuilderManager
    ---@param factories string[]
    ---@param bType string
    SetupFactoryCallbacks = function(self,factories,bType)
        for k,v in factories do
            if not v.BuilderManagerData then
                v.BuilderManagerData = { FactoryBuildManager = self, BuilderType = bType, }

                local factoryDestroyed = function(v)
                                            -- Call function on builder manager; let it handle death of factory
                                            self:FactoryDestroyed(v)
                                        end
                import("/lua/scenariotriggers.lua").CreateUnitDestroyedTrigger(factoryDestroyed, v)

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
                import("/lua/scenariotriggers.lua").CreateUnitCapturedTrigger(nil, factoryNewlyCaptured, v)

                local factoryWorkFinish = function(v, finishedUnit)
                                            -- Call function on builder manager; let it handle the finish of work
                                            self:FactoryFinishBuilding(v, finishedUnit)
                                        end
                import("/lua/scenariotriggers.lua").CreateUnitBuiltTrigger(factoryWorkFinish, v, categories.ALLUNITS)
            end
            self:ForkThread(self.DelayBuildOrder, v, bType, 0.1)
        end
    end,

    ---@param self FactoryBuilderManager
    ---@param factory Unit
    FactoryDestroyed = function(self, factory)
        local factoryDestroyed = false
        for k,v in self.FactoryList do
            if IsDestroyed(v) then
                self.FactoryList[k] = nil
                factoryDestroyed = true
            end
        end
        if factoryDestroyed then
            self.FactoryList = self:RebuildTable(self.FactoryList)
        end
        for k,v in self.FactoryList do
            if not v.Dead then
                return
            end
        end
        self.LocationActive = false
    end,

    ---@param self FactoryBuilderManager
    ---@param factory Unit
    ---@param bType string
    ---@param time number
    DelayBuildOrder = function(self,factory,bType,time)
        if factory.DelayThread then
            return
        end
        factory.DelayThread = true
        WaitSeconds(time)
        factory.DelayThread = false
        self:AssignBuildOrder(factory,bType)
    end,

    ---@param self FactoryBuilderManager
    ---@param factory Unit
    ---@return string|false
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

    ---@param self FactoryBuilderManager
    ---@param factory FactoryBuilderManager
    ---@return Categories|nil
    UnitFromCustomFaction = function(self, factory)
        local customFactions = self.Brain.CustomFactions
        for k,v in customFactions do
            if EntityCategoryContains(v.customCat, factory) then
                return v.cat
            end
        end
    end,

    ---@param self FactoryBuilderManager
    ---@param templateName string
    ---@param factory Unit
    ---@return boolean
    GetFactoryTemplate = function(self, templateName, factory)
        local templateData = PlatoonTemplates[templateName]
        if not templateData then
            SPEW('*AI WARNING: No templateData found for template '..templateName..'. ')
            return false
        end
        if not templateData.FactionSquads then
            SPEW('*AI ERROR: PlatoonTemplate named: ' .. templateName .. ' does not have a FactionSquads')
            return false
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

    ---@param self FactoryBuilderManager
    ---@param template any
    ---@param templateName string
    ---@param faction Unit
    ---@return boolean|table
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
            if not table.empty(possibles) then
                rand = Random(1,TableGetn(possibles))
                local customUnitID = possibles[rand]
                -- LOG('*AI DEBUG: Replaced with '..customUnitID)
                retTemplate = { customUnitID, template[2], template[3], template[4], template[5] }
            end
        end
        return retTemplate
    end,

    ---@param self FactoryBuilderManager
    ---@param factory Unit
    ---@param bType string
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

    ---@param self FactoryBuilderManager
    ---@param factory Unit
    ---@param finishedUnit Unit
    FactoryFinishBuilding = function(self,factory,finishedUnit)
        if EntityCategoryContains(categories.ENGINEER, finishedUnit) then
            self.Brain.BuilderManagers[self.LocationType].EngineerManager:AddUnit(finishedUnit)
        elseif EntityCategoryContains(categories.FACTORY * categories.STRUCTURE, finishedUnit ) then
			if finishedUnit:GetFractionComplete() == 1 then
				self:AddFactory(finishedUnit )
				factory.Dead = true
                factory.Trash:Destroy()
				return self:FactoryDestroyed(factory)
			end
		elseif self.Brain.TransportPool and EntityCategoryContains(categories.TRANSPORTFOCUS - categories.uea0203, finishedUnit ) then
            self.Brain.TransportRequested = nil
            finishedUnit:ForkThread( import('/lua/ai/transportutilities.lua').AssignTransportToPool, finishedUnit:GetAIBrain() )
        end
        self:AssignBuildOrder(factory, factory.BuilderManagerData.BuilderType)
    end,

    -- Check if given factory can build the builder
    ---@param self FactoryBuilderManager
    ---@param builder Builder
    ---@param params FactoryUnit[]
    ---@return boolean
    BuilderParamCheck = function(self, builder, params)

        -- params[1] is factory, no other params
        local template = self:GetFactoryTemplate(builder:GetPlatoonTemplate(), params[1])
        if not template then
            WARN('*Factory Builder Error: Could not find template named: ' .. builder:GetPlatoonTemplate())
            return false
        end

        -- This faction doesn't have unit of this type
        if TableGetn(template) == 2 then
            return false
        end

        local personality = self.Brain:GetPersonality()
        local ptnSize = personality:GetPlatoonSize()

        -- This function takes a table of factories to determine if it can build
        return self.Brain:CanBuildPlatoon(template, params)
    end,

    ---@param self FactoryBuilderManager
    ---@param factory Unit
    DelayRallyPoint = function(self, factory)
        WaitSeconds(1)
        if not factory.Dead then
            self:SetRallyPoint(factory)
        end
    end,

    ---@param self FactoryBuilderManager
    ---@param factory Unit
    ---@return boolean
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
            local locationType = self.LocationType
            local factoryPos = self.Brain.BuilderManagers[locationType].Position
            position = AIUtils.ShiftPosition(factoryPos, self.Brain.MapCenterPoint, 25)
            rally = position
        end

        IssueClearFactoryCommands({factory})
        IssueFactoryRallyPoint({factory}, rally)
        self.RallyPoint = rally
        return true
    end,
}

---@param brain AIBrain
---@param lType string
---@param location Vector
---@param radius number
---@param useCenterPoint boolean
---@return FactoryBuilderManager
function CreateFactoryBuilderManager(brain, lType, location, radius, useCenterPoint)
    local fbm = FactoryBuilderManager()
    fbm:Create(brain, lType, location, radius, useCenterPoint)
    return fbm
end

--- Moved Unsused Imports to bottome for mod support 
local AIBuildUnits = import("/lua/ai/aibuildunits.lua")