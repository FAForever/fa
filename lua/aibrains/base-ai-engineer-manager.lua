--****************************************************************************
--**  File     :  /lua/sim/BaseAIEngineerManager.lua
--**  Summary  : Manage engineers for a location
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local BuilderManager = import("/lua/sim/buildermanager.lua").BuilderManager
local Builder = import("/lua/sim/builder.lua")

local TableGetn = table.getn

local WeakValues = { __mode = 'v' }

---@class BaseAIEngineerManager : BuilderManager
---@field Location Vector
---@field Radius number
---@field Engineers table
---@field EngineersBeingBuilt table
BaseAIEngineerManager = Class(BuilderManager) {

    --- TODO:

    --- Factor out AddUnit
    --- Factor out RemoveUnit
    --- Factor out unit.BuilderManagerData
    --- Factor out REmoveUnit

    ---@param self BaseAIEngineerManager
    ---@param brain AIBrain
    ---@param lType LocationType
    ---@param location Vector
    ---@param radius number
    ---@return boolean
    Create = function(self, brain, lType, location, radius)
        BuilderManager.Create(self,brain, lType, location, radius)

        self.Engineers = {
            TECH1 = setmetatable({ }, WeakValues),
            TECH2 = setmetatable({ }, WeakValues),
            TECH3 = setmetatable({ }, WeakValues),
            EXPERIMENTAL = setmetatable({ }, WeakValues),
            SUBCOMMANDER = setmetatable({ }, WeakValues),
            COMMAND = setmetatable({ }, WeakValues),
        }

        self.EngineersBeingBuilt = {
            TECH1 = setmetatable({ }, WeakValues),
            TECH2 = setmetatable({ }, WeakValues),
            TECH3 = setmetatable({ }, WeakValues),
            EXPERIMENTAL = setmetatable({ }, WeakValues),
            SUBCOMMANDER = setmetatable({ }, WeakValues),
            COMMAND = setmetatable({ }, WeakValues),
        }

        self:AddBuilderType('Any')
    end,

    --------------------------------------------------------------------------------------------
    -- builder interface

    -- This is where the majority of the magic happens. See the description of the same section
    -- in the file BuilderManager class for an extensive description

    --- TODO
    ---@param self BaseAIEngineerManager
    ---@param builderData BuilderSpec
    ---@param locationType LocationType
    ---@param builderType BuilderType
    ---@return Builder
    AddBuilder = function(self, builderData, locationType, builderType)
        local newBuilder = Builder.CreateEngineerBuilder(self.Brain, builderData, locationType)
        self:AddInstancedBuilder(newBuilder, builderType)
        return newBuilder
    end,

    --- TODO
    ---@param self BaseAIEngineerManager
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

    --- TODO
    ---@param self BaseAIEngineerManager
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

    --------------------------------------------------------------------------------------------
    -- builder list interface

    --------------------------------------------------------------------------------------------
    -- manager interface

    --------------------------------------------------------------------------------------------
    -- unit events

    --- Called by a unit that is an engineer as it starts being built
    ---@param self BaseAIEngineerManager
    ---@param unit Unit
    OnUnitStartBeingBuilt = function(self, unit)
        local tech = unit.Blueprint.TechCategory
        local id = unit.EntityId
        self.EngineersBeingBuilt[tech][id] = unit
    end,

    --- Called by a unit that is an engineer as it is finished being built
    ---@param self BaseAIEngineerManager
    ---@param unit Unit
    OnUnitFinishedBeingBuilt = function(self, unit)
        local tech = unit.Blueprint.TechCategory
        local id = unit.EntityId
        self.EngineersBeingBuilt[tech][id] = nil
        self.Engineers[tech][id] = unit
    end,

    --- Called by a unit that is an engineer as it is destroyed
    ---@param self BaseAIEngineerManager
    ---@param unit Unit
    OnUnitDestroyed = function(self, unit)
        local tech = unit.Blueprint.TechCategory
        local id = unit.EntityId
        self.EngineersBeingBuilt[tech][id] = nil
        self.Engineers[tech][id] = nil
    end,

    --------------------------------------------------------------------------------------------
    -- unit interface

    --- TODO
    ---@param self BaseAIEngineerManager
    ---@param unitType string
    ---@return number
    GetNumUnits = function(self, unitType)
        if self.ConsumptionUnits[unitType] then
            return self.ConsumptionUnits[unitType].Count
        end
        return 0
    end,

    --- TODO
    ---@param self BaseAIEngineerManager
    ---@param unitType string
    ---@param category EntityCategory
    ---@return number
    GetNumCategoryUnits = function(self, unitType, category)
        if self.ConsumptionUnits[unitType] then
            return EntityCategoryCount(category, self.ConsumptionUnits[unitType].UnitsList)
        end
        return 0
    end,

    --- TODO
    ---@param self BaseAIEngineerManager
    ---@param category EntityCategory
    ---@param engCategory EntityCategory
    ---@return integer
    GetNumCategoryBeingBuilt = function(self, category, engCategory)
        return TableGetn(self:GetEngineersBuildingCategory(category, engCategory))
    end,

    --- TODO
    ---@param self BaseAIEngineerManager
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

    --- TODO
    ---@param self BaseAIEngineerManager
    ---@param unitType string
    ---@param category EntityCategory
    ---@return UserUnit[]|nil
    GetUnits = function(self, unitType, category)
        if self.ConsumptionUnits[unitType] then
            return EntityCategoryFilterDown(category, self.ConsumptionUnits[unitType].UnitsList)
        end
        return {}
    end,

    --------------------------------------------------------------------------------------------
    -- properties

    --- TODO
    ---@param self BaseAIEngineerManager
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

    --- TODO
    ---@param self BaseAIEngineerManager
    ---@param unit Unit
    ReassignUnit = function(self, unit)
        local managers = self.Brain.BuilderManagers
        local bestManager = false
        local distance = false
        local unitPos = unit:GetPosition()
        for k,v in managers do
            if v.FactoryManager:GetNumCategoryFactories(categories.ALLUNITS) > 0 or v == 'MAIN' then
                local checkDistance = VDist3(v.BaseAIEngineerManager:GetLocationCoords(), unitPos)
                if not distance or checkDistance < distance then
                    distance = checkDistance
                    bestManager = v.BaseAIEngineerManager
                end
            end
        end
        self:RemoveUnit(unit)
        if bestManager and not unit.Dead then
            bestManager:AddUnit(unit)
        end
    end,

    --- TODO
    ---@param manager BaseAIEngineerManager
    ---@param unit Unit
    TaskFinished = function(manager, unit)
        if VDist3(manager.Location, unit:GetPosition()) > manager.Radius and not EntityCategoryContains(categories.COMMAND, unit) then
            manager:ReassignUnit(unit)
        else
            manager:ForkEngineerTask(unit)
        end
    end,

    --- TODO
    ---@param self BaseAIEngineerManager
    ---@param builderName string
    AssignTimeout = function(self, builderName)
        local oldPri = self:GetBuilderPriority(builderName)
        if oldPri then
            self:SetBuilderPriority(builderName, 0, true)
        end
    end,

    --- TODO
    ---@param manager BaseAIEngineerManager
    ---@param unit Unit
    ForkEngineerTask = function(manager, unit)
        if unit.ForkedEngineerTask then
            KillThread(unit.ForkedEngineerTask)
            unit.ForkedEngineerTask = unit:ForkThread(manager.Wait, manager, 3)
        else
            unit.ForkedEngineerTask = unit:ForkThread(manager.Wait, manager, 20)
        end
    end,

    --- TODO
    ---@param manager BaseAIEngineerManager
    ---@param unit Unit
    ---@param delaytime number          # in ticks
    DelayAssign = function(manager, unit, delaytime)
        if unit.ForkedEngineerTask then
            KillThread(unit.ForkedEngineerTask)
        end
        unit.ForkedEngineerTask = unit:ForkThread(manager.Wait, manager, delaytime or 10)
    end,

    --- TODO
    ---@param unit Unit
    ---@param manager BaseAIEngineerManager
    ---@param ticks integer
    Wait = function(unit, manager, ticks)
        coroutine.yield(ticks)
        if not unit.Dead then
            manager:AssignEngineerTask(unit)
        end
    end,

    --- TODO
    ---@param self BaseAIEngineerManager
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
}

---@param brain AIBrain
---@param locationType LocationType
---@param location Vector
---@param radius number
---@return BaseAIEngineerManager
function CreateEngineerManager(brain, locationType, location, radius)
    local em = BaseAIEngineerManager()
    em:Create(brain, locationType, location, radius)
    return em
end
