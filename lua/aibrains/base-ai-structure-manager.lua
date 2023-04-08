--****************************************************************************
--**  File     :  /lua/sim/BaseAIEngineerManager.lua
--**  Summary  : Manage engineers for a location
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local BuilderManager = import("/lua/sim/buildermanager.lua").BuilderManager
local Builder = import("/lua/sim/builder.lua")

local TableGetn = table.getn
local TableGetSize = table.getsize

local WeakValues = { __mode = 'v' }

---@class BaseAIEngineerManager
---@field Engineers table
---@field EngineersBeingBuilt table     
---@field StructuresBeingBuilt table
---@field EngineerTotalCount number     # Recomputed every 10 ticks
---@field EngineerCount table           # Recomputed every 10 ticks
BaseAIEngineerManager = ClassSimple {
    
    ---@param self BaseAIEngineerManager
    ---@param brain AIBrain
    ---@param locationType LocationType
    ---@param location Vector
    ---@param radius number
    ---@return boolean
    Create = function(self, brain, locationType, location, radius)
        BuilderManager.Create(self, brain, locationType, location, radius)

        self.Structures = {
            ENERGYPRODUCTION = {
                TECH1 = setmetatable({}, WeakValues),
                TECH2 = setmetatable({}, WeakValues),
                TECH3 = setmetatable({}, WeakValues),
                EXPERIMENTAL = setmetatable({}, WeakValues),
                SUBCOMMANDER = setmetatable({}, WeakValues),
                COMMAND = setmetatable({}, WeakValues),
            },
            MASSPRODUCTION = {
                TECH1 = setmetatable({}, WeakValues),
                TECH2 = setmetatable({}, WeakValues),
                TECH3 = setmetatable({}, WeakValues),
                EXPERIMENTAL = setmetatable({}, WeakValues),
                SUBCOMMANDER = setmetatable({}, WeakValues),
                COMMAND = setmetatable({}, WeakValues),
            },
            SHIELD = {
                TECH1 = setmetatable({}, WeakValues),
                TECH2 = setmetatable({}, WeakValues),
                TECH3 = setmetatable({}, WeakValues),
                EXPERIMENTAL = setmetatable({}, WeakValues),
                SUBCOMMANDER = setmetatable({}, WeakValues),
                COMMAND = setmetatable({}, WeakValues),
            },
            RADAR = {
                TECH1 = setmetatable({}, WeakValues),
                TECH2 = setmetatable({}, WeakValues),
                TECH3 = setmetatable({}, WeakValues),
                EXPERIMENTAL = setmetatable({}, WeakValues),
                SUBCOMMANDER = setmetatable({}, WeakValues),
                COMMAND = setmetatable({}, WeakValues),
            },
            SONAR = {
                TECH1 = setmetatable({}, WeakValues),
                TECH2 = setmetatable({}, WeakValues),
                TECH3 = setmetatable({}, WeakValues),
                EXPERIMENTAL = setmetatable({}, WeakValues),
                SUBCOMMANDER = setmetatable({}, WeakValues),
                COMMAND = setmetatable({}, WeakValues),
            },
            ANTIAIR = {
                TECH1 = setmetatable({}, WeakValues),
                TECH2 = setmetatable({}, WeakValues),
                TECH3 = setmetatable({}, WeakValues),
                EXPERIMENTAL = setmetatable({}, WeakValues),
                SUBCOMMANDER = setmetatable({}, WeakValues),
                COMMAND = setmetatable({}, WeakValues),
            },
            ANTISURFACE = {
                TECH1 = setmetatable({}, WeakValues),
                TECH2 = setmetatable({}, WeakValues),
                TECH3 = setmetatable({}, WeakValues),
                EXPERIMENTAL = setmetatable({}, WeakValues),
                SUBCOMMANDER = setmetatable({}, WeakValues),
                COMMAND = setmetatable({}, WeakValues),
            },
            ANTINAVAL = {
                TECH1 = setmetatable({}, WeakValues),
                TECH2 = setmetatable({}, WeakValues),
                TECH3 = setmetatable({}, WeakValues),
                EXPERIMENTAL = setmetatable({}, WeakValues),
                SUBCOMMANDER = setmetatable({}, WeakValues),
                COMMAND = setmetatable({}, WeakValues),
            },
            STRATEGIC = {
                TECH1 = setmetatable({}, WeakValues),
                TECH2 = setmetatable({}, WeakValues),
                TECH3 = setmetatable({}, WeakValues),
                EXPERIMENTAL = setmetatable({}, WeakValues),
                SUBCOMMANDER = setmetatable({}, WeakValues),
                COMMAND = setmetatable({}, WeakValues),
            },
            ANTISTRATEGIC = {
                TECH1 = setmetatable({}, WeakValues),
                TECH2 = setmetatable({}, WeakValues),
                TECH3 = setmetatable({}, WeakValues),
                EXPERIMENTAL = setmetatable({}, WeakValues),
                SUBCOMMANDER = setmetatable({}, WeakValues),
                COMMAND = setmetatable({}, WeakValues),
            },
            TACTICAL = {
                TECH1 = setmetatable({}, WeakValues),
                TECH2 = setmetatable({}, WeakValues),
                TECH3 = setmetatable({}, WeakValues),
                EXPERIMENTAL = setmetatable({}, WeakValues),
                SUBCOMMANDER = setmetatable({}, WeakValues),
                COMMAND = setmetatable({}, WeakValues),
            },
            ANTITACTICAL = {
                TECH1 = setmetatable({}, WeakValues),
                TECH2 = setmetatable({}, WeakValues),
                TECH3 = setmetatable({}, WeakValues),
                EXPERIMENTAL = setmetatable({}, WeakValues),
                SUBCOMMANDER = setmetatable({}, WeakValues),
                COMMAND = setmetatable({}, WeakValues),
            },
            ARTILLERY = {
                TECH1 = setmetatable({}, WeakValues),
                TECH2 = setmetatable({}, WeakValues),
                TECH3 = setmetatable({}, WeakValues),
                EXPERIMENTAL = setmetatable({}, WeakValues),
                SUBCOMMANDER = setmetatable({}, WeakValues),
                COMMAND = setmetatable({}, WeakValues),
            },
        }

        self.StructuresBeingBuilt = {
            ENERGYPRODUCTION = {
                TECH1 = setmetatable({}, WeakValues),
                TECH2 = setmetatable({}, WeakValues),
                TECH3 = setmetatable({}, WeakValues),
                EXPERIMENTAL = setmetatable({}, WeakValues),
                SUBCOMMANDER = setmetatable({}, WeakValues),
                COMMAND = setmetatable({}, WeakValues),
            }
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

    -- This is where the majority of the magic happens. See the description of the same section
    -- in the BuilderManager class for an extensive description

    --------------------------------------------------------------------------------------------
    -- builder list interface

    --------------------------------------------------------------------------------------------
    -- manager interface

    ---@param self BaseAIEngineerManager
    UpdateThread = function(self)
        while true do
            if self.Active then
                self:Update()
            end

            WaitSeconds(1.0)
        end
    end,

    ---@param self BaseAIEngineerManager
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
    ---@param self BaseAIEngineerManager
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnUnitStartBeingBuilt = function(self, unit, builder, layer)
        local tech = unit.Blueprint.TechCategory
        local id = unit.EntityId
        self.EngineersBeingBuilt[tech][id] = unit

        -- used by platoon functions to find the manager
        local builderManagerData = unit.BuilderManagerData or { }
        unit.BuilderManagerData = builderManagerData
        builderManagerData.EngineerManager = self
        builderManagerData.LocationType = self.LocationType
    end,

    --- Called by a unit that is an engineer as it is finished being built
    --- 
    --- `Time complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self BaseAIEngineerManager
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnUnitStopBeingBuilt = function(self, unit, builder, layer)
        local tech = unit.Blueprint.TechCategory
        local id = unit.EntityId
        self.EngineersBeingBuilt[tech][id] = nil
        self.Engineers[tech][id] = unit

        -- used by platoon functions to find the manager
        local builderManagerData = unit.BuilderManagerData or { }
        unit.BuilderManagerData = builderManagerData
        builderManagerData.EngineerManager = self
        builderManagerData.LocationType = self.LocationType

        self:ForkEngineerTask(unit)
    end,

    --- Called by a unit that is an engineer as it is destroyed
    --- 
    --- `Time complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self BaseAIEngineerManager
    ---@param unit Unit
    OnUnitDestroyed = function(self, unit)
        local tech = unit.Blueprint.TechCategory
        local id = unit.EntityId
        self.EngineersBeingBuilt[tech][id] = nil
        self.Engineers[tech][id] = nil
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
    -- platoon events 

    --- Called by a platoon of the engineer as it is being disbanded
    ---@param self BaseAIEngineerManager
    ---@param unit Unit
    TaskFinished = function(self, unit)
        if VDist3(self.Location, unit:GetPosition()) > self.Radius and
            not EntityCategoryContains(categories.COMMAND, unit) then
            self:ReassignUnit(unit)
        else
            self:ForkEngineerTask(unit)
        end
    end,

    --- Called by a platoon of the engineer as it is being disbanded
    --- 
    --- `Time complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self BaseAIEngineerManager
    ---@param builderName string
    AssignTimeout = function(self, builderName)
        local oldPri = self:GetBuilderPriority(builderName)
        if oldPri then
            self:SetBuilderPriority(builderName, 0, true)
        end
    end,

    --------------------------------------------------------------------------------------------
    -- unit interface

    --- Add a unit to the engineer manager, similar to calling `OnUnitStopBeingBuilt`
    --- 
    --- `Time complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self BaseAIEngineerManager
    ---@param unit Unit
    ---@param doNotAssignTask boolean
    AddUnit = function(self, unit, doNotAssignTask)
        local tech = unit.Blueprint.TechCategory
        local id = unit.EntityId
        self.EngineersBeingBuilt[tech][id] = nil
        self.Engineers[tech][id] = unit

        -- used by platoon functions to find the manager
        local builderManagerData = unit.BuilderManagerData or { }
        unit.BuilderManagerData = builderManagerData
        builderManagerData.EngineerManager = self
        builderManagerData.LocationType = self.LocationType

        if not doNotAssignTask then
            self:ForkEngineerTask(unit)
        end
    end,

    --- Remove a unit from the engineer manager, similar to calling `OnUnitDestroyed`
    --- 
    --- `Complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self BaseAIEngineerManager
    ---@param unit Unit
    RemoveUnit = function(self, unit)
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
    ---@param self BaseAIEngineerManager
    ---@return number
    GetNumUnits = function(self)
        return self.EngineerTotalCount
    end,

    --- Retrieves the number of engineers of a given tech
    --- 
    --- `Complexity: O(1)`
    --- 
    --- `Memory complexity: O(1)`
    ---@param self BaseAIEngineerManager
    ---@param tech TechCategory
    ---@return number
    GetNumUnitsByTech = function(self, tech)
        return self.EngineerCount[tech]
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
