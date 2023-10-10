
--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local AIBuilderManager = import("/lua/aibrains/managers/builder-manager.lua").AIBuilderManager
-- local AIPlatoonEngineer = import("/lua/aibrains/platoons/platoon-engineer.lua").AIPlatoonEngineer

local TableGetSize = table.getsize

local WeakValues = { __mode = 'v' }

---@class AIEngineerManagerReferences
---@field TECH1 table<EntityId, Unit>
---@field TECH2 table<EntityId, Unit>
---@field TECH3 table<EntityId, Unit>
---@field EXPERIMENTAL table<EntityId, Unit>
---@field SUBCOMMANDER table<EntityId, Unit>
---@field COMMAND table<EntityId, Unit>

---@class AIEngineerManagerCount
---@field TECH1 number
---@field TECH2 number
---@field TECH3 number
---@field EXPERIMENTAL number
---@field SUBCOMMANDER number
---@field COMMAND number

---@class AIEngineerManagerDebugInfo

---@class AIEngineerManager : AIBuilderManager
---@field DebugInfo AIEngineerManagerDebugInfo
---@field Engineers AIEngineerManagerReferences
---@field EngineersBeingBuilt AIEngineerManagerReferences     
---@field EngineerTotalCount number                 # Recomputed every 10 ticks
---@field EngineerCount AIEngineerManagerCount      # Recomputed every 10 ticks
AIEngineerManager = Class(AIBuilderManager) {

    ManagerName = "EngineerManager",

    ---@param self AIEngineerManager
    ---@param brain AIBrain
    ---@param base AIBase
    ---@param locationType LocationType
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
        self.Trash:Add(ForkThread(self.UpdateEngineerThread, self))
    end,

    ---@param self AIEngineerManager
    UpdateEngineerThread = function(self)
        while true do
            local total = 0
            local engineers = self.Engineers
            local engineerCount = self.EngineerCount
            for tech, _ in engineerCount do
                local count = TableGetSize(engineers[tech])
                engineerCount[tech] = count
                total = total + count
            end
    
            self.EngineerTotalCount = total
            WaitTicks(10)
        end
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
    ---@param platoon AIPlatoon
    ---@param unit Unit
    ---@return boolean
    BuilderParamCheck = function(self, builder, platoon, unit)
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

    --------------------------------------------------------------------------------------------
    -- engineer manager interface

    ---@param self AIEngineerManager
    ---@param platoon AIPlatoonEngineer
    ---@param unit Unit
    ---@return AIBuilder?
    GetBuildTask = function(self, platoon, unit)
        -- TODO: replace 'Any' with 'BuildTask'
        return self:GetHighestBuilder('Any', platoon, unit)
    end,

    ---@param self AIEngineerManager
    ---@param platoon AIPlatoonEngineer
    ---@param unit Unit
    ---@return AIBuilder?
    GetRepairTask = function(self, platoon, unit)
        -- TODO: replace 'Any' with 'RepairTask'
        return self:GetHighestBuilder('Any', platoon, unit)
    end,

    ---@param self AIEngineerManager
    ---@param platoon AIPlatoonEngineer
    ---@param unit Unit
    ---@return AIBuilder?
    GetReclaimTask = function(self, platoon, unit)
        -- TODO: replace 'Any' with 'ReclaimTask'
        return self:GetHighestBuilder('Any', platoon, unit)
    end,


    ---------------------------------------------------------------------------
    --#region Debug functionality

    ---@param self AIEngineerManager
    ---@return AIEngineerManagerDebugInfo
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
---@return AIEngineerManager
function CreateEngineerManager(brain, base, locationType)
    local em = AIEngineerManager()
    em:Create(brain, base, locationType)
    return em
end
