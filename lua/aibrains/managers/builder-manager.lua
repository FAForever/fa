
local Builder = import("/lua/aibrains/templates/builder-groups/builder.lua")

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
---@field BuilderData table<AIBuilderType, AIBuilderManagerDataData>   # Array table of builders
---@field BuilderLookup table<string, AIBuilder>    # Hash table of builders
---@field BuilderThread? thread                     # Thread that runs the loop, does not exist when the manager is not active
---@field Trash TrashBag                            # Trashbag of this manager
AIBuilderManager = ClassSimple {

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

    --- Adds a builder type to this manager
    ---@param self AIBuilderManager
    ---@param type BuilderType
    AddBuilderType = function(self, type)
        self.BuilderData[type] = { Builders = {}, NeedSort = false }
    end,

    --- Adds a builder to the manager, usually this function is overwritten by the managers that inherit this builder
    ---@param self AIBuilderManager
    ---@param template AIBuilderTemplate
    ---@param builderType BuilderType
    AddBuilder = function(self, template, builderType)
        local builder = Builder.CreateBuilder(self.Brain, self.Base, template)
        self:AddInstancedBuilder(builder, builderType)
    end,

    --- Adds an abstract builder to the manager
    ---@param self AIBuilderManager
    ---@param builder AIBuilder
    ---@param builderType? BuilderType
    AddInstancedBuilder = function(self, builder, builderType)
        builderType = builderType or builder:GetBuilderType()

        -- can't proceed without a builder type that we support
        local builderName = builder:GetBuilderName()
        local builderDataType = self.BuilderData[builderType]
        if not builderDataType then
            WARN('[' ..
                string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1") ..
                ', line:' ..
                debug.getinfo(1).currentline ..
                '] *BUILDERMANAGER ERROR: No BuilderData for builder: ' .. tostring(builderName))
            return
        end

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
    ---@param builderType BuilderType
    ---@param platoon AIPlatoon
    ---@param unit Unit
    ---@return AIBuilder?
    GetHighestBuilder = function(self, builderType, platoon, unit)
        local builderData = self.BuilderData[builderType]
        if not builderData then
            error('*BUILDERMANAGER ERROR: Invalid builder type - ' .. builderType)
        end

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
                    if builder:EvaluateBuilderConditions(brain, base, tick) then
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
