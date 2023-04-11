--****************************************************************************
--**  File     :  /lua/sim/AIEngineerManager.lua
--**  Summary  : Manage engineers for a location
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AIBuilderManager = import("/lua/aibrains/managers/builder-manager.lua").AIBuilderManager

local TableGetn = table.getn
local TableGetSize = table.getsize

local WeakValues = { __mode = 'v' }

---@class AIEngineerManager : AIBuilderManager
---@field Engineers table
---@field EngineersBeingBuilt table     
---@field StructuresBeingBuilt table
---@field EngineerTotalCount number     # Recomputed every 10 ticks
---@field EngineerCount table           # Recomputed every 10 ticks
AIEngineerManager = Class(AIBuilderManager) {

    --- TODO:

    --- Factor out unit.BuilderManagerData
    --- Factor out GetNumCategoryUnits
    --- Factor out GetEngineersWantingAssistance

    ---@param self AIEngineerManager
    ---@param brain AIBrain
    ---@param base AIBase
    ---@param locationType LocationType
    ---@return boolean
    Create = function(self, brain, base, locationType)
        AIBuilderManager.Create(self, brain, base, locationType)
        self.Identifier = 'AIEngineerManager at ' .. locationType

        self.Engineers = {
            TECH1 = setmetatable({}, WeakValues),
            TECH2 = setmetatable({}, WeakValues),
            TECH3 = setmetatable({}, WeakValues),
            EXPERIMENTAL = setmetatable({}, WeakValues),
            SUBCOMMANDER = setmetatable({}, WeakValues),
            COMMAND = setmetatable({}, WeakValues),
        }

        self.EngineersBeingBuilt = {
            TECH1 = setmetatable({}, WeakValues),
            TECH2 = setmetatable({}, WeakValues),
            TECH3 = setmetatable({}, WeakValues),
            EXPERIMENTAL = setmetatable({}, WeakValues),
            SUBCOMMANDER = setmetatable({}, WeakValues),
            COMMAND = setmetatable({}, WeakValues),
        }

        self.EngineerTotalCount = 0
        self.EngineerCount = {
            TECH1 = 0,
            TECH2 = 0,
            TECH3 = 0,
            EXPERIMENTAL = 0,
            SUBCOMMANDER = 0,
            COMMAND = 0,
        }

        self.StructuresBeingBuilt = setmetatable({}, WeakValues)

        self:AddBuilderType('Any')

        -- TODO: refactor this to base class?
        self:ForkThread(self.UpdateThread)

        return true
    end,

    --------------------------------------------------------------------------------------------
    -- builder interface

    --- Retrieves the engineer platoon template. Creates a new table if the cache is not provided
    --- 
    --- `Time complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self AIEngineerManager
    ---@param templateName string
    ---@return table
    GetEngineerPlatoonTemplate = function(self, templateName, cache)
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

        cache = cache or { }

        local template = {
            templateData.Name,
            templateData.Plan,
            unpack(templateData.GlobalSquads)
        }
        return template
    end,

    --- TODO
    ---@param self AIEngineerManager
    ---@param builder AIBuilder
    ---@param params { [1]: Unit }
    ---@return boolean
    BuilderParamCheck = function(self, builder, params)
        local unit = params[1]

        -- and builder:CheckInstanceCount()
        -- Check if the category of the unit matches the category of the builder
        local template = self:GetEngineerPlatoonTemplate(builder:GetPlatoonTemplate())
        if not unit.Dead and EntityCategoryContains(template[3][1], unit) then
            return true
        end

        -- Nope
        return false
    end,

    --------------------------------------------------------------------------------------------
    -- builder list interface

    --------------------------------------------------------------------------------------------
    -- manager interface

    ---@param self AIEngineerManager
    UpdateThread = function(self)
        while true do
            if self.Active then
                self:Update()
            end

            WaitSeconds(1.0)
        end
    end,

    ---@param self AIEngineerManager
    Update = function(self)
        local total = 0
        local engineers = self.Engineers
        local engineerCount = self.EngineerCount
        for tech, _ in engineerCount do
            local count = TableGetSize(engineers[tech])
            engineerCount[tech] = count
            total = total + count
        end

        self.EngineerTotalCount = total
    end,

    --------------------------------------------------------------------------------------------
    -- unit events

    --- Called by a unit that is an engineer as it starts being built
    --- 
    --- `Time complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self AIEngineerManager
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnUnitStartBeingBuilt = function(self, unit, builder, layer)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['ENGINEER'] then
            local tech = blueprint.TechCategory
            local id = unit.EntityId
            self.EngineersBeingBuilt[tech][id] = unit

            -- used by platoon functions to find the manager
            local builderManagerData = unit.BuilderManagerData or { }
            unit.BuilderManagerData = builderManagerData
            builderManagerData.EngineerManager = self
        end
    end,

    --- Called by a unit that is an engineer as it is finished being built
    --- 
    --- `Time complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self AIEngineerManager
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnUnitStopBeingBuilt = function(self, unit, builder, layer)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['ENGINEER'] then
            local tech = blueprint.TechCategory
            local id = unit.EntityId
            self.EngineersBeingBuilt[tech][id] = nil
            self.Engineers[tech][id] = unit

            -- used by platoon functions to find the manager
            local builderManagerData = unit.BuilderManagerData or { }
            unit.BuilderManagerData = builderManagerData
            builderManagerData.EngineerManager = self

            self:ForkEngineerTask(unit)
        end
    end,

    --- Called by a unit that is an engineer as it is destroyed
    --- 
    --- `Time complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self AIEngineerManager
    ---@param unit Unit
    OnUnitDestroyed = function(self, unit)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['ENGINEER'] then
            local tech = blueprint.TechCategory
            local id = unit.EntityId
            self.EngineersBeingBuilt[tech][id] = nil
            self.Engineers[tech][id] = nil
        end
    end,

    --- Called by a unit as it starts building
    --- 
    --- `Time complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self AIBuilderManager
    ---@param unit Unit
    ---@param built Unit
    OnUnitStartBuilding = function(self, unit, built)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['ENGINEER'] then
        end
    end,

    --- Called by a unit as it stops building
    ---@param self AIBuilderManager
    ---@param unit Unit
    ---@param built Unit
    OnUnitStopBuilding = function(self, unit, built)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['ENGINEER'] then
        end
    end,

    --------------------------------------------------------------------------------------------
    -- platoon events 

    --- Called by a platoon of the engineer as it is being disbanded
    ---@param self AIEngineerManager
    ---@param unit Unit
    TaskFinished = function(self, unit)
        self:ForkEngineerTask(unit)
    end,

    -- --- Called by a platoon of the engineer as it is being disbanded
    -- --- 
    -- --- `Time complexity: O(1)`
    -- --- 
    -- --- `Memory complexity: O(1)`
    -- ---@param self AIEngineerManager
    -- ---@param builderName string
    -- AssignTimeout = function(self, builderName)
    --     local oldPri = self:GetBuilderPriority(builderName)
    --     if oldPri then
    --         self:SetBuilderPriority(builderName, 0, true)
    --     end
    -- end,

    --------------------------------------------------------------------------------------------
    -- unit interface

    --- Add a unit to the engineer manager, similar to calling `OnUnitStopBeingBuilt`
    --- 
    --- `Time complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self AIEngineerManager
    ---@param unit Unit
    ---@param doNotAssignTask boolean
    AddEngineer = function(self, unit, doNotAssignTask)
        local tech = unit.Blueprint.TechCategory
        local id = unit.EntityId
        self.EngineersBeingBuilt[tech][id] = nil
        self.Engineers[tech][id] = unit

        -- used by platoon functions to find the manager
        local builderManagerData = unit.BuilderManagerData or { }
        unit.BuilderManagerData = builderManagerData
        builderManagerData.EngineerManager = self

        if not doNotAssignTask then
            self:ForkEngineerTask(unit)
        end
    end,

    --- Remove a unit from the engineer manager, similar to calling `OnUnitDestroyed`
    --- 
    --- `Complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self AIEngineerManager
    ---@param unit Unit
    RemoveEngineer = function(self, unit)
        local tech = unit.Blueprint.TechCategory
        local id = unit.EntityId
        self.EngineersBeingBuilt[tech][id] = nil
        self.Engineers[tech][id] = nil
    end,

    --- Retrieves the total number of engineers
    --- 
    --- `Complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self AIEngineerManager
    ---@return number
    GetNumUnits = function(self)
        return self.EngineerTotalCount
    end,

    --- Retrieves the number of engineers of a given tech
    --- 
    --- `Complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self AIEngineerManager
    ---@param tech TechCategory
    ---@return number
    GetNumUnitsByTech = function(self, tech)
        return self.EngineerCount[tech]
    end,

    --- Retrieves the number of engineers that are building units of a given category
    --- 
    --- `Time complexity: O(n)` where `n` is `EngineerTotalCount`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self AIEngineerManager
    ---@param cat EntityCategory
    ---@return number
    GetNumUnitsRequestingAssistance = function(self, cat)
        local total = 0
        for _, engineers in self.Engineers do
            for _, engineer in engineers do
                local unitBeingBuilt = engineer.UnitBeingBuilt
                if  unitBeingBuilt and
                    engineer:IsUnitState('Building') and
                    EntityCategoryContains(cat, unitBeingBuilt)
                then
                    total = total + 1
                end
            end
        end

        return total
    end,

    --- Retrieves the engineers that are building units of a given category. Creates a new table if the cache is not provided
    --- 
    --- `Time complexity: O(n)` where `n` is `EngineerTotalCount`
    --- 
    --- `Memory complexity: O(k), where `k` is the number of engineers assisting. If the cache is provided then `O(1)`
    ---@param self AIEngineerManager
    ---@param cat EntityCategory
    ---@param cache? table
    ---@return Unit[]
    ---@return number
    GetEngineersRequestingAssistance = function(self, cat, cache)
        cache = cache or { }
        local head = 1
        for _, engineers in self.Engineers do
            for _, engineer in engineers do
                local unitBeingBuilt = engineer.UnitBeingBuilt
                if  unitBeingBuilt and
                    engineer:IsUnitState('Building') and
                    EntityCategoryContains(cat, unitBeingBuilt)
                then
                    cache[head] = engineer
                    head = head + 1
                end
            end
        end

        return cache, head
    end,

    --- Retrieves the number of engineers of a given tech that are building units of a given category
    --- 
    --- `Time complexity: O(n)` where `n` is `EngineerCount[tech]`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self AIEngineerManager
    ---@param tech TechCategory
    ---@param cat EntityCategory
    ---@return number
    GetNumUnitsByTechRequestingAssistance = function(self, tech, cat)
        local total = 0
        local engineers = self.Engineers[tech]
        for _, engineer in engineers do
            local unitBeingBuilt = engineer.UnitBeingBuilt
            if  unitBeingBuilt and
                engineer:IsUnitState('Building') and
                EntityCategoryContains(cat, unitBeingBuilt)
            then
                total = total + 1
            end
        end

        return total
    end,

    --------------------------------------------------------------------------------------------
    -- properties

    --- TODO
    ---@param self AIEngineerManager
    ---@param unit Unit
    ReassignUnit = function(self, unit)
        local managers = self.Brain.BuilderManagers
        local bestManager = false
        local distance = false
        local unitPos = unit:GetPosition()
        for k, v in managers do
            if v.FactoryManager:GetNumCategoryFactories(categories.ALLUNITS) > 0 or v == 'MAIN' then
                local checkDistance = VDist3(v.AIEngineerManager:GetLocationCoords(), unitPos)
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



    --- TODO
    ---@param manager AIEngineerManager
    ---@param unit Unit
    ForkEngineerTask = function(manager, unit)
        local task = unit.ForkedEngineerTask
        local trash = unit.Trash
        if task then
            KillThread(task)
            task = ForkThread(manager.Wait, unit, manager, 3)
            unit.ForkedEngineerTask = task
            trash:Add(task)
        else
            task = unit:ForkThread(manager.Wait, manager, 20)
            unit.ForkedEngineerTask = task
            trash:Add(task)
        end
    end,

    --- TODO
    ---@param manager AIEngineerManager
    ---@param unit Unit
    ---@param delaytime number          # in ticks
    DelayAssign = function(manager, unit, delaytime)
        local task = unit.ForkedEngineerTask
        if task then
            KillThread(task)
        end

        task = ForkThread(manager.Wait, unit, manager, delaytime or 10)
        unit.Trash:Add(task)
        unit.ForkedEngineerTask = task
    end,

    --- TODO
    ---@param unit Unit
    ---@param manager AIEngineerManager
    ---@param ticks number
    Wait = function(unit, manager, ticks)
        coroutine.yield(ticks)
        if not unit.Dead then
            manager:AssignEngineerTask(unit)
        end
    end,

    --- TODO
    ---@param self AIEngineerManager
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

        local builder = self:GetHighestBuilder('Any', { unit })
        if builder then
            -- Fork off the platoon here
            local template = self:GetEngineerPlatoonTemplate(builder:GetPlatoonTemplate())
            local platoon = self.Brain:MakePlatoon(template[1], template[2]) --[[@type Platoon]]
            self.Brain:AssignUnitsToPlatoon(platoon, { unit }, 'support', 'none')
            unit.PlatoonHandle = platoon

            --LOG('*AI DEBUG: ARMY ', repr(self.Brain:GetArmyIndex()),': Engineer Manager Forming - ',repr(builder.BuilderName),' - Priority: ', builder:GetPriority())
            platoon.PlanName = template[2]

            local aiFunc = builder:GetPlatoonAIFunction()
            if aiFunc then
                platoon:StopAI()
                platoon:ForkAIThread(import(aiFunc[1])[ aiFunc[2] ])
            end

            local aiPlan = builder:GetPlatoonAIPlan()
            if aiPlan then
                platoon.PlanName = aiPlan
                platoon:SetAIPlan(aiPlan)
            end

            platoon.Priority = builder:GetBuilderPriority()
            platoon.BuilderName = builder:GetBuilderName()

            platoon:SetPlatoonData(builder:GetBuilderData())

            if platoon.PlatoonData.DesiresAssist then
                unit.DesiresAssist = platoon.PlatoonData.DesiresAssist
            else
                unit.DesiresAssist = true
            end

            if platoon.PlatoonData.NumAssistees then
                unit.NumAssistees = platoon.PlatoonData.NumAssistees
            end

            if platoon.PlatoonData.MinNumAssistees then
                unit.MinNumAssistees = platoon.PlatoonData.MinNumAssistees
            end

            -- builder:StoreHandle(platoon)
            self.AssigningTask = false
            return
        end
        self.AssigningTask = false
        self:DelayAssign(unit, 50)
    end,

    --------------------------------------------------------------------------------------------
    --- deprecated functionality

    --- This section contains functionality that is either deprecated (unmaintained) or
    --- functionality that is considered bad practice for performance

    ---@deprecated
    ---@param self AIEngineerManager
    ---@param unitType string
    ---@param category EntityCategory
    ---@return number
    GetNumCategoryUnits = function(self, unitType, category)
        return 0
    end,

    ---@deprecated
    ---@param self AIEngineerManager
    ---@param category EntityCategory
    ---@param engCategory EntityCategory
    ---@return integer
    GetNumCategoryBeingBuilt = function(self, category, engCategory)
        return 0
    end,

    ---@deprecated
    ---@param self AIEngineerManager
    ---@param category EntityCategory
    ---@param engCategory EntityCategory
    ---@return table
    GetEngineersBuildingCategory = function(self, category, engCategory)
        return { }
    end,

}

---@param brain AIBrain
---@param base AIBase
---@param locationType LocationType
---@return AIEngineerManager
function CreateEngineerManager(brain, base, locationType)
    local em = AIEngineerManager()
    em:Create(brain, base, locationType)
    return em
end
