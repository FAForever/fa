--****************************************************************************
--**  File     :  /lua/sim/BaseAIStructureManager.lua
--**  Summary  : Manage structures for a location
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local BuilderManager = import("/lua/sim/buildermanager.lua").BuilderManager

local TableGetSize = table.getsize

local WeakValues = { __mode = 'v' }

---@class BaseAIStructureManager : BuilderManager
---@field Structures table
---@field StructuresBeingBuilt table     
---@field StructureTotalCount number     # Recomputed every 10 ticks
---@field StructureCount table           # Recomputed every 10 ticks
BaseAIStructureManager = Class(BuilderManager) {

    ---@param self BaseAIStructureManager
    ---@param brain AIBrain
    ---@param locationType LocationType
    ---@param location Vector
    ---@param radius number
    ---@return boolean
    Create = function(self, brain, locationType, location, radius)
        BuilderManager.Create(self, brain, locationType, location, radius)

        self.Structures = {
            TECH1 = setmetatable({}, WeakValues),
            TECH2 = setmetatable({}, WeakValues),
            TECH3 = setmetatable({}, WeakValues),
            EXPERIMENTAL = setmetatable({}, WeakValues),
            SUBCOMMANDER = setmetatable({}, WeakValues),
            COMMAND = setmetatable({}, WeakValues),
        }

        self.StructuresBeingBuilt = {
            TECH1 = setmetatable({}, WeakValues),
            TECH2 = setmetatable({}, WeakValues),
            TECH3 = setmetatable({}, WeakValues),
            EXPERIMENTAL = setmetatable({}, WeakValues),
            SUBCOMMANDER = setmetatable({}, WeakValues),
            COMMAND = setmetatable({}, WeakValues),
        }

        self.StructureTotalCount = 0
        self.StructureCount = {
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
    -- manager interface

    ---@param self BaseAIStructureManager
    UpdateThread = function(self)
        while true do
            if self.Active then
                self:Update()
            end

            WaitSeconds(1.0)
        end
    end,

    ---@param self BaseAIStructureManager
    Update = function(self)
        local total = 0
        local engineers = self.Structures
        local engineerCount = self.StructureCount
        for tech, _ in engineerCount do
            local count = TableGetSize(engineers[tech])
            engineerCount[tech] = count
            total = total + count
        end

        self.EngineerTotalCount = total
    end,

    --------------------------------------------------------------------------------------------
    -- unit events

    --- Called by a unit as it starts being built
    --- 
    --- `Time complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self BaseAIStructureManager
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
    ---@param self BaseAIStructureManager
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
    ---@param self BaseAIStructureManager
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
    end,

    --- Called by a unit as it stops building
    ---@param self BuilderManager
    ---@param unit Unit
    ---@param built Unit
    OnUnitStopBuilding = function(self, unit, built)
    end,

    --------------------------------------------------------------------------------------------
    -- unit interface

    --- Add a unit to, similar to calling `OnUnitStopBeingBuilt`
    --- 
    --- `Time complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self BaseAIStructureManager
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
    ---@param self BaseAIStructureManager
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
---@param locationType LocationType
---@param location Vector
---@param radius number
---@return BaseAIStructureManager
function CreateStructureManager(brain, locationType, location, radius)
    local manager = BaseAIStructureManager()
    manager:Create(brain, locationType, location, radius)
    return manager
end
