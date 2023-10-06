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

---@class AIFactoryManagerDebugInfo

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
        self:AddFactory(unit)
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

    ---@param self AIFactoryManager
    ---@return AIPlatoon
    GetFactoryPlatoonMetaTable = function(self)
        return import("/lua/aibrains/platoons/platoon-simple-factory.lua").AIPlatoonSimpleFactory
    end,

    --- Add a unit to the factory manager
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

            -- create a new platoon instance
            local platoon = self.Brain:MakePlatoon("FactoryManager - " .. tostring(unit), '') --[[@as AIPlatoon]]
            setmetatable(platoon, self:GetFactoryPlatoonMetaTable())
            platoon.Base = self.Base
            platoon.Brain = self.Brain
            self.Brain:AssignUnitsToPlatoon(platoon, {unit}, 'Unassigned', 'None')
            ChangeState(platoon, platoon.Start)
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

    --------------------------------------------------------------------------------------------
    -- factory conditions interface

    ---------------------------------------------------------------------------
    --#region Debug functionality

    ---@param self AIFactoryManager
    ---@return AIFactoryManagerDebugInfo
    GetDebugInfo = function(self)
        local info = self.DebugInfo
        if not info then
            info = { }
            self.DebugInfo = info
        end

        return info
    end,

    --#endregion


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
