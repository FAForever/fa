
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

local Builder = import("/lua/aibrains/templates/builders/builder.lua")

-- upvalue scope for performance
local TableSort = table.sort
local TableInsert = table.insert

local ForkThread = ForkThread

-- caches to preserve memory
local BuilderCache = { }

---@param a AIBuilder
---@param b AIBuilder
local function BuilderSortLambda(a, b)
    return a.Priority > b.Priority
end

---@class AIBuilderManagerDataData
---@field Builders AIBuilder[]
---@field NeedSort boolean

--- An abstract class of the various managers. Introduces the logic to maintain
--- and find builders as the base is trying to figure out what to do
---@class AIBuilderManager
---@field Identifier string
---@field Brain AIBrain         # A reference to the brain that this manager belongs to
---@field Base AIBase           # A reference to the base that this manager belongs to
---@field BuilderData table<string, AIBuilderManagerDataData>   # Array table of builders
---@field BuilderLookup table<string, AIBuilder>    # Hash table of builders
---@field BuilderThread? thread                     # Thread that runs the loop, does not exist when the manager is not active
---@field Trash TrashBag                            # Trashbag of this manager
AIBuilderManager = ClassSimple {

    ManagerName = "BuilderManager",

    ---@param self AIBuilderManager
    ---@param brain AIBrain
    Create = function(self, brain, base, locationType)
        self.Identifier = 'AIBuilderManager at ' .. locationType
        self.Brain = brain
        self.Base = base
        self.BuilderData = {}
        self.BuilderLookup = { }

        self.Trash = TrashBag()
        self.Trash:Add(ForkThread(self.UpdateBuilderThread, self))
    end,

    ---@param self AIBuilderManager
    Destroy = function(self)
        self.Trash:Destroy()
    end,

    --------------------------------------------------------------------------------------------
    -- builder interface

    -- This is where the majority of the magic happens. There are two main phases:
    --
    -- 1. Initialisation
    --
    -- During initialisation the builders are introduced. Usually no builders are introduced
    -- after the manager is created. Note that all builders have unique instances in memory.
    --
    -- 2. Retrieving the highest priority builder
    --
    -- Once all builders are in place we constantly look for the highest possible builder. We
    -- consider the name 'Builder' to be poorly choosen, one should rather read it as a 'Task'
    --
    -- A task has a priority. The tasks with the highest priority are evaluated first. Each
    -- task has a series of conditions attached to it. These conditions are evaluated as
    -- we are searching for a task.
    --
    -- Once a task is found it can be assigned. This abstract manager does not do that, it
    -- is merely an abstraction to interact with the various builders.

    --- Adds a builder to the manager, usually this function is overwritten by the managers that inherit this builder
    ---@param self AIBuilderManager
    ---@param builderTemplate AIBuilderTemplate
    AddBuilder = function(self, builderTemplate)
        -- create the type as necessary
        local builderType = builderTemplate.BuilderType
        if not builderType then
            builderType = 'All'
        end

        if not self.BuilderData[builderTemplate.BuilderType] then
            self.BuilderData[builderType] = { Builders = {}, NeedSort = false }
        end

        SPEW("Registered builder: " .. builderTemplate.BuilderName)

        -- add the instanced builder
        local builder = Builder.CreateBuilder(self.Brain, self.Base, builderTemplate)
        self:AddInstancedBuilder(builder, builderType)
    end,

    --- Adds an abstract builder to the manager
    ---@param self AIBuilderManager
    ---@param builder AIBuilder
    ---@param builderType? BuilderType
    AddInstancedBuilder = function(self, builder, builderType)
        local builderName = builder.Template.BuilderName
        local builderDataType = self.BuilderData[builderType]

        -- register the builder
        builderDataType.NeedSort = true
        TableInsert(builderDataType.Builders, builder)
        self.BuilderLookup[builderName] = builder
    end,

    --- Retrieves the first builder with a matching `BuilderName` field
    ---@param self AIBuilderManager
    ---@param builderName string
    ---@return AIBuilder?
    GetBuilder = function(self, builderName)
        return self.BuilderLookup[builderName]
    end,

    --- Retrieves the highest builder that is valid with the given parameters
    ---@param self AIBuilderManager
    ---@param platoon AIPlatoon
    ---@param unit Unit
    ---@return AIBuilder?
    GetHighestBuilder = function(self, platoon, unit, unitType)
        local builderData = self.BuilderData[unitType]
        if not builderData then
            -- LOG(string.format("Wrong unitType: %s", tostring(unitType)))
            return nil
        end

        -- used to quickly reject builders
        local unitTech = unit.Blueprint.TechCategory
        local unitLayer = unit.Blueprint.LayerCategory
        local unitFaction = unit.Blueprint.FactionCategory

        local tick = GetGameTick()
        local brain = self.Brain
        local base = self.Base
        local candidates = BuilderCache
        local candidateNext = 1
        local candidatePriority = -1

        -- list of builders that is sorted on priority
        local builders = builderData.Builders
        for k in builders do
            local builder = builders[k] --[[@as AIBuilder]]
            local builderTemplate = builder.Template

            -- check tech requirement
            local builderTech = builderTemplate.BuilderTech
            if builderTech and builderTech != unitTech then
                -- LOG(string.format("Wrong unitTech: %s", tostring(unitTech)))
                continue
            end

            -- check layer requirement
            local builderLayer = builderTemplate.BuilderLayer
            if builderLayer and builderLayer != unitLayer then
                -- LOG(string.format("Wrong unitLayer: %s", tostring(unitLayer)))
                continue
            end

            -- check faction requirement
            local builderFaction = builderTemplate.BuilderFaction
            if builderFaction and builderFaction != unitFaction then
                -- LOG(string.format("Wrong unitFaction: %s", tostring(unitFaction)))
                continue
            end

            -- builders with no priority are ignored
            local priority = builder.Priority
            if priority >= 1 then
                -- break when we have found a builder and the next builder has a lower priority
                if priority < candidatePriority then
                    break
                end

                -- check builder conditions
                if self:BuilderParamCheck(builder, platoon, unit) then
                    -- check task conditions
                    if builder:EvaluateBuilderConditions(brain, base, platoon, tick) then
                        candidates[candidateNext] = builder
                        candidateNext = candidateNext + 1
                        candidatePriority = priority
                    end
                end
            end
        end

        -- only one candidate
        if candidateNext == 2 then
            return candidates[1]

        -- multiple candidates, choose one at random
        elseif candidateNext > 2 then
            return candidates[Random(1, candidateNext - 1)]
        end
    end,

    --- Returns true if the given builders matches the manager-specific parameters
    ---@param self AIBuilderManager
    ---@param builder AIBuilder
    ---@param platoon AIPlatoon
    ---@param unit Unit
    ---@return boolean
    BuilderParamCheck = function(self, builder, platoon, unit)
        return true
    end,

    --------------------------------------------------------------------------------------------
    -- builder list interface

    --- Sorts the builders of this manager so that high priority builders are checked first
    ---@param self AIBuilderManager
    ---@param bType BuilderType
    SortBuilderList = function(self, bType)
        -- Make sure there is a type
        if not self.BuilderData[bType] then
            error('*BUILDMANAGER ERROR: Trying to sort platoons of invalid builder type - ' .. bType)
            return false
        end

        TableSort(self.BuilderData[bType].Builders, BuilderSortLambda)
        self.BuilderData[bType].NeedSort = false
    end,

    ---@param self AIBuilderManager
    UpdateBuilderThread = function(self)
        while true do
            for bType, bTypeData in self.BuilderData do
                for _, builder in bTypeData.Builders do
                    if builder:EvaluateBuilderPriority(self) then
                        self.BuilderData[bType].NeedSort = true
                    end
                end

                -- sort the builders accordingly
                if bTypeData.NeedSort then
                    self:SortBuilderList(bType)
                end

                WaitTicks(6)
            end
            WaitTicks(1)
        end
    end,

    --------------------------------------------------------------------------------------------
    -- unit events

    --- Called by a unit as it starts being built
    ---@param self AIBuilderManager
    ---@param unit Unit
    OnUnitStartBeingBuilt = function(self, unit)
    end,

    --- Called by a unit as it is finished being built
    ---@param self AIBuilderManager
    ---@param unit Unit
    OnUnitStopBeingBuilt = function(self, unit)
    end,

    --- Called by a unit as it is destroyed
    ---@param self AIBuilderManager
    ---@param unit Unit
    OnUnitDestroyed = function(self, unit)
    end,

    --- Called by a unit as it starts building
    ---@param self AIBuilderManager
    ---@param unit Unit
    ---@param built Unit
    OnUnitStartBuilding = function(self, unit, built)
    end,

    --- Called by a unit as it stops building
    ---@param self AIBuilderManager
    ---@param unit Unit
    ---@param built Unit
    OnUnitStopBuilding = function(self, unit, built)
    end,

    --------------------------------------------------------------------------------------------
    --- deprecated functionality

    --- This section contains functionality that is either deprecated (unmaintained) or
    --- functionality that is considered bad practice for performance

    --- Root of all performance evil, do not use - inline the function instead
    ---@deprecated
    ---@param self AIBuilderManager
    ---@param fn function
    ---@param ... any
    ---@return thread|nil
    ForkThread = function(self, fn, ...)
        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.Trash:Add(thread)
            return thread
        else
            return nil
        end
    end,

    HasBuilderList = function(self)
        return false
    end,

    ---@param self AIBuilderManager
    ---@return Vector
    GetLocationCoords = function(self)
        return self.Base.Position
    end
}


-- kept for mod backwards compatibility
local AIUtils = import("/lua/ai/aiutilities.lua")
local AIBuildUnits = import("/lua/ai/aibuildunits.lua")
