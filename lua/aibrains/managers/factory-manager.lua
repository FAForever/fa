--****************************************************************************
--**  Summary: Manage factories for a location
--****************************************************************************

local BuilderManager = import("/lua/aibrains/managers/builder-manager.lua").AIBuilderManager

local IsDestroyed = IsDestroyed

local TableGetSize = table.getsize
local TableGetn = table.getn

local WeakValues = { __mode = 'v' }
local FactoryCache = {}
local TemplateCache = {}

local MapFactionCategory = {
    UEF = 'UEF',
    AEON = 'Aeon',
    CYBRAN = 'Cybran',
    SERAPHIM = 'Seraphim',
    NOMADS = 'Nomads'
}

---@class AIFactoryTemplate : PlatoonTemplateFactionalSpec[]
---@field [1] string    # Name of platoon template
---@field [2] string    # Always ''

---@class AIFactoryManagerReferences
---@field RESEARCH { TECH1: table<EntityId, Unit>, TECH2: table<EntityId, Unit>, TECH3: table<EntityId, Unit>, EXPERIMENTAL: table<EntityId, Unit> }
---@field SUPPORT { TECH1: table<EntityId, Unit>, TECH2: table<EntityId, Unit>, TECH3: table<EntityId, Unit>, EXPERIMENTAL: table<EntityId, Unit> }

---@class AIFactoryManagerCounts
---@field RESEARCH { TECH1: number, TECH2: number, TECH3: number, EXPERIMENTAL: number }
---@field SUPPORT { TECH1: number, TECH2: number, TECH3: number, EXPERIMENTAL: number }

---@class AIFactoryManager : AIBuilderManager
---@field Factories AIFactoryManagerReferences
---@field FactoriesBeingBuilt AIFactoryManagerReferences
---@field FactoryCount AIFactoryManagerCounts               # Recomputed every 10 ticks
---@field FactoryBeingBuiltCount AIFactoryManagerCounts     # Recomputed every 10 ticks
AIFactoryManager = Class(BuilderManager) {

    ManagerName = "FactoryManager",

    ---@param self AIFactoryManager
    ---@param brain AIBrain
    ---@param base AIBase
    ---@param locationType LocationType
    Create = function(self, brain, base, locationType)
        BuilderManager.Create(self, brain, base, locationType)
        self.Identifier = 'AIFactoryManager at ' .. locationType

        self.Factories = {
            RESEARCH = {
                TECH1 = setmetatable({}, WeakValues),
                TECH2 = setmetatable({}, WeakValues),
                TECH3 = setmetatable({}, WeakValues),
                EXPERIMENTAL = setmetatable({}, WeakValues),
            },
            SUPPORT = {
                TECH1 = setmetatable({}, WeakValues),
                TECH2 = setmetatable({}, WeakValues),
                TECH3 = setmetatable({}, WeakValues),
                EXPERIMENTAL = setmetatable({}, WeakValues),
            }
        }

        self.FactoryCount = {
            RESEARCH = {
                TECH1 = 0,
                TECH2 = 0,
                TECH3 = 0,
                EXPERIMENTAL = 0,
            },
            SUPPORT = {
                TECH1 = 0,
                TECH2 = 0,
                TECH3 = 0,
                EXPERIMENTAL = 0,
            }
        }

        self.FactoriesBeingBuilt = {
            RESEARCH = {
                TECH1 = setmetatable({}, WeakValues),
                TECH2 = setmetatable({}, WeakValues),
                TECH3 = setmetatable({}, WeakValues),
                EXPERIMENTAL = setmetatable({}, WeakValues),
            },
            SUPPORT = {
                TECH1 = setmetatable({}, WeakValues),
                TECH2 = setmetatable({}, WeakValues),
                TECH3 = setmetatable({}, WeakValues),
                EXPERIMENTAL = setmetatable({}, WeakValues),
            }
        }

        self.FactoryBeingBuiltCount = {
            RESEARCH = {
                TECH1 = 0,
                TECH2 = 0,
                TECH3 = 0,
                EXPERIMENTAL = 0,
            },
            SUPPORT = {
                TECH1 = 0,
                TECH2 = 0,
                TECH3 = 0,
                EXPERIMENTAL = 0,
            }
        }

        self.Trash:Add(ForkThread(self.UpdateFactoryThread, self))
    end,


    ---@param self AIFactoryManager
    UpdateFactoryThread = function(self)
        while true do
            local total = 0
            local engineers = self.Factories
            local engineerCount = self.FactoryCount
            for tech, _ in engineerCount do
                local count = TableGetSize(engineers[tech])
                engineerCount[tech] = count
                total = total + count
            end

            local factoryBeingBuilt = self.FactoriesBeingBuilt
            local factoryBeingBuiltCount = self.FactoryBeingBuiltCount
            for tech, _ in factoryBeingBuiltCount do
                local count = TableGetSize(factoryBeingBuilt[tech])
                factoryBeingBuiltCount[tech] = count
                total = total + count
            end
            WaitTicks(10)
        end
    end,

    -- Check if given factory can build the builder
    ---@param self AIFactoryManager
    ---@param builder AIBuilder
    ---@param factories Unit[]
    ---@return boolean
    BuilderParamCheck = function(self, builder, factories)
        local template = self:GetFactoryTemplate(factories[1], builder:GetPlatoonTemplate())

        -- This faction doesn't have unit of this type
        if TableGetn(template) == 2 then
            return false
        end

        -- This function takes a table of factories to determine if it can build
        return self.Brain:CanBuildPlatoon(template, factories)
    end,

    --------------------------------------------------------------------------------------------
    -- unit events

    --- Called by a unit as it starts being built
    ---@param self AIFactoryManager
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnUnitStartBeingBuilt = function(self, unit, builder, layer)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['STRUCTURE'] and blueprint.CategoriesHash['FACTORY'] then
            local type = (blueprint.CategoriesHash['RESEARCH'] and 'RESEARCH') or 'SUPPORT'
            local tech = blueprint.TechCategory
            local id = unit.EntityId
            self.FactoriesBeingBuilt[type][tech][id] = unit

            -- used by platoon functions to find the manager
            local builderManagerData = unit.BuilderManagerData or {}
            unit.BuilderManagerData = builderManagerData
            builderManagerData.FactoryManager = self
        end
    end,

    --- Called by a unit as it is finished being built
    ---@param self AIFactoryManager
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnUnitStopBeingBuilt = function(self, unit, builder, layer)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['STRUCTURE'] and blueprint.CategoriesHash['FACTORY'] then
            local type = (blueprint.CategoriesHash['RESEARCH'] and 'RESEARCH') or 'SUPPORT'
            local tech = blueprint.TechCategory
            local id = unit.EntityId
            self.FactoriesBeingBuilt[type][tech][id] = nil
            self.Factories[type][tech][id] = unit

            -- used by platoon functions to find the manager
            local builderManagerData = unit.BuilderManagerData or {}
            unit.BuilderManagerData = builderManagerData
            builderManagerData.FactoryManager = self

            self:DelayOrder(unit, 'Any', 10)
        end
    end,

    --- Called by a unit as it is destroyed
    ---@param self AIFactoryManager
    ---@param unit Unit
    OnUnitDestroyed = function(self, unit)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['STRUCTURE'] and blueprint.CategoriesHash['FACTORY'] then
            local type = (blueprint.CategoriesHash['RESEARCH'] and 'RESEARCH') or 'SUPPORT'
            local tech = blueprint.TechCategory
            local id = unit.EntityId
            self.FactoriesBeingBuilt[type][tech][id] = nil
            self.Factories[type][tech][id] = nil
        end
    end,

    --- Called by a unit as it starts building
    ---@param self AIFactoryManager
    ---@param unit Unit
    ---@param built Unit
    OnUnitStartBuilding = function(self, unit, built)
        -- local blueprint = unit.Blueprint
        -- if blueprint.CategoriesHash['STRUCTURE'] then
        -- end
    end,

    --- Called by a unit as it stops building
    ---@param self AIFactoryManager
    ---@param unit Unit
    ---@param built Unit
    OnUnitStopBuilding = function(self, unit, built)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['STRUCTURE'] and blueprint.CategoriesHash['FACTORY'] then
            -- self:DelayOrder(unit, 'Any', 10)
        end
    end,

    --------------------------------------------------------------------------------------------
    -- factory manager interface

    --- Add a unit to, similar to calling `OnUnitStopBeingBuilt`
    ---@param self AIFactoryManager
    ---@param unit Unit
    AddFactory = function(self, unit)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['STRUCTURE'] then
            local type = (blueprint.CategoriesHash['RESEARCH'] and 'RESEARCH') or 'SUPPORT'
            local tech = blueprint.TechCategory
            local id = unit.EntityId
            self.FactoriesBeingBuilt[type][tech][id] = nil
            self.Factories[type][tech][id] = unit

            -- used by platoon functions to find the manager
            local builderManagerData = unit.BuilderManagerData or {}
            unit.BuilderManagerData = builderManagerData
            builderManagerData.StructureManager = self
        end
    end,

    --- Remove a unit, similar to calling `OnUnitDestroyed`
    ---@param self AIFactoryManager
    ---@param unit Unit
    RemoveFactory = function(self, unit)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['STRUCTURE'] then
            local type = (blueprint.CategoriesHash['RESEARCH'] and 'RESEARCH') or 'SUPPORT'
            local tech = blueprint.TechCategory
            local id = unit.EntityId
            self.FactoriesBeingBuilt[type][tech][id] = nil
            self.Factories[type][tech][id] = nil
        end
    end,

    ---@param self FactoryBuilderManager
    ---@param factory Unit
    ---@param templateName string
    ---@return AIFactoryTemplate
    GetFactoryTemplate = function(self, factory, templateName)
        local platoonTemplate = PlatoonTemplates[templateName]

        -- clear out the cached template
        local template = TemplateCache
        for k = 3, table.getn(template) do
            template[k] = nil
        end

        -- populate the template
        template[1] = platoonTemplate.Name
        template[2] = ''

        local head = 3
        for _, squad in platoonTemplate.FactionSquads[MapFactionCategory[factory.Blueprint.FactionCategory]] do
            template[head] = squad
            head = head + 1
        end

        return template
    end,

    --- Assigns a build order to a factory
    ---@param self AIFactoryManager
    ---@param factory Unit
    ---@param builderType AIBuilderType
    AssignOrder = function(self, factory, builderType)
        error("AssignOrder")
        local factoryCache = FactoryCache
        factoryCache[1] = factory

        local builder = self:GetHighestBuilder(builderType, factoryCache)
        if builder then
            -- found something to build
            local template = self:GetFactoryTemplate(factory, builder:GetPlatoonTemplate())
            self.Brain:BuildPlatoon(template, factoryCache, 1)
        else
            -- did not find anything to build
            self:DelayOrder(factory, builderType, 10)
        end
    end,

    --- Assigns a builder order to a factory after waiting a few ticks
    ---@param self AIFactoryManager
    ---@param factory Unit
    ---@param builderType AIBuilderType
    ---@param delayInTicks number
    DelayOrder = function(self, factory, builderType, delayInTicks)
        self.Trash:Add(ForkThread(self.DelayOrderThread, self, factory, builderType, delayInTicks))
    end,

    ---@param self AIFactoryManager
    ---@param factory Unit
    ---@param builderType AIBuilderType
    ---@param delayInTicks number
    DelayOrderThread = function(self, factory, builderType, delayInTicks)
        WaitTicks(delayInTicks)

        if not IsDestroyed(factory) then
            self:AssignOrder(factory, builderType)
        end
    end,

    --------------------------------------------------------------------------------------------
    -- factory conditions interface


}

---@param brain AIBrain
---@param base AIBase
---@param locationType LocationType
---@return AIFactoryManager
function CreateFactoryManager(brain, base, locationType)
    local manager = AIFactoryManager()
    manager:Create(brain, base, locationType)
    return manager
end
