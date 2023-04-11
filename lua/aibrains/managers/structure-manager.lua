--****************************************************************************
--**  Summary: Manage structures for a location
--****************************************************************************

local BuilderManager = import("/lua/aibrains/managers/builder-manager.lua").AIBuilderManager

local TableGetSize = table.getsize

local WeakValues = { __mode = 'v' }

---@class AIStructureManagerReferences 
---@field TECH1 table<EntityId, Unit>
---@field TECH2 table<EntityId, Unit>
---@field TECH3 table<EntityId, Unit>
---@field EXPERIMENTAL table<EntityId, Unit>

---@class AIStructureManagerCounts
---@field TECH1 number
---@field TECH2 number
---@field TECH3 number
---@field EXPERIMENTAL number

---@class AIStructureManager : AIBuilderManager
---@field Structures AIStructureManagerReferences
---@field StructuresBeingBuilt AIStructureManagerReferences     
---@field StructureCount AIStructureManagerCounts               # Recomputed every 10 ticks
---@field StructureBeingBuiltCount AIStructureManagerCounts     # Recomputed every 10 ticks
AIStructureManager = Class(BuilderManager) {

    ---@param self AIStructureManager
    ---@param brain AIBrain
    ---@param base AIBase
    Create = function(self, brain, base, locationType)
        BuilderManager.Create(self, brain, base, locationType)
        self.Identifier = 'AIStructureManager at ' .. locationType

        self.Structures = {
            TECH1 = setmetatable({}, WeakValues),
            TECH2 = setmetatable({}, WeakValues),
            TECH3 = setmetatable({}, WeakValues),
            EXPERIMENTAL = setmetatable({}, WeakValues),
        }

        self.StructureCount = {
            TECH1 = 0,
            TECH2 = 0,
            TECH3 = 0,
            EXPERIMENTAL = 0,
        }

        self.StructuresBeingBuilt = {
            TECH1 = setmetatable({}, WeakValues),
            TECH2 = setmetatable({}, WeakValues),
            TECH3 = setmetatable({}, WeakValues),
            EXPERIMENTAL = setmetatable({}, WeakValues),
        }

        self.StructureBeingBuiltCount = {
            TECH1 = 0,
            TECH2 = 0,
            TECH3 = 0,
            EXPERIMENTAL = 0,
        }

        self:AddBuilderType('Any')

        -- TODO: refactor this to base class?
        self:ForkThread(self.UpdateThread)
    end,

    --------------------------------------------------------------------------------------------
    -- manager interface

    ---@param self AIStructureManager
    UpdateThread = function(self)
        while true do
            if self.Active then
                self:Update()
            end

            WaitSeconds(1.0)
        end
    end,

    ---@param self AIStructureManager
    Update = function(self)
        local total = 0
        local engineers = self.Structures
        local engineerCount = self.StructureCount
        for tech, _ in engineerCount do
            local count = TableGetSize(engineers[tech])
            engineerCount[tech] = count
            total = total + count
        end

        local StructureBeingBuilt = self.StructuresBeingBuilt
        local StructureBeingBuiltCount = self.StructureBeingBuiltCount
        for tech, _ in StructureBeingBuiltCount do
            local count = TableGetSize(StructureBeingBuilt[tech])
            StructureBeingBuiltCount[tech] = count
            total = total + count
        end
    end,

    --------------------------------------------------------------------------------------------
    -- unit events

    --- Called by a unit as it starts being built
    --- 
    --- `Time complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self AIStructureManager
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnUnitStartBeingBuilt = function(self, unit, builder, layer)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['STRUCTURE'] then
            local tech = blueprint.TechCategory
            local id = unit.EntityId
            self.StructuresBeingBuilt[tech][id] = unit

            -- used by platoon functions to find the manager
            local builderManagerData = unit.BuilderManagerData or { }
            unit.BuilderManagerData = builderManagerData
            builderManagerData.StructureManager = self
            builderManagerData.LocationType = self.LocationType
        end
    end,

    --- Called by a unit as it is finished being built
    --- 
    --- `Time complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self AIStructureManager
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnUnitStopBeingBuilt = function(self, unit, builder, layer)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['STRUCTURE'] then
            local tech = blueprint.TechCategory
            local id = unit.EntityId
            self.StructuresBeingBuilt[tech][id] = nil
            self.Structures[tech][id] = unit

            -- used by platoon functions to find the manager
            local builderManagerData = unit.BuilderManagerData or { }
            unit.BuilderManagerData = builderManagerData
            builderManagerData.StructureManager = self
            builderManagerData.LocationType = self.LocationType
        end
    end,

    --- Called by a unit as it is destroyed
    --- 
    --- `Time complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self AIStructureManager
    ---@param unit Unit
    OnUnitDestroyed = function(self, unit)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['STRUCTURE'] then
            local tech = blueprint.TechCategory
            local id = unit.EntityId
            self.StructuresBeingBuilt[tech][id] = nil
            self.Structures[tech][id] = nil
        end
    end,

    --- Called by a unit as it starts building
    ---@param self BuilderManager
    ---@param unit Unit
    ---@param built Unit
    OnUnitStartBuilding = function(self, unit, built)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['STRUCTURE'] then
        end
    end,

    --- Called by a unit as it stops building
    ---@param self BuilderManager
    ---@param unit Unit
    ---@param built Unit
    OnUnitStopBuilding = function(self, unit, built)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['STRUCTURE'] then
        end
    end,

    --------------------------------------------------------------------------------------------
    -- unit interface

    --- Add a unit to, similar to calling `OnUnitStopBeingBuilt`
    --- 
    --- `Time complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self AIStructureManager
    ---@param unit Unit
    AddUnit = function(self, unit)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['STRUCTURE'] then
            local tech = blueprint.TechCategory
            local id = unit.EntityId
            self.StructuresBeingBuilt[tech][id] = nil
            self.Structures[tech][id] = unit

            -- used by platoon functions to find the manager
            local builderManagerData = unit.BuilderManagerData or { }
            unit.BuilderManagerData = builderManagerData
            builderManagerData.StructureManager = self
            builderManagerData.LocationType = self.LocationType
        end
    end,

    --- Remove a unit, similar to calling `OnUnitDestroyed`
    --- 
    --- `Complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self AIStructureManager
    ---@param unit Unit
    RemoveUnit = function(self, unit)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['STRUCTURE'] then
            local tech = blueprint.TechCategory
            local id = unit.EntityId
            self.StructuresBeingBuilt[tech][id] = nil
            self.Structures[tech][id] = nil
        end
    end,
}

---@param brain AIBrain
---@param base AIBase
---@param locationType LocationType
---@return AIStructureManager
function CreateStructureManager(brain, base, locationType)
    local manager = AIStructureManager()
    manager:Create(brain, base, locationType)
    return manager
end
