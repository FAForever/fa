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

local WeakValueTable = { __mode = 'v' }

-- upvalue scope for performance
local setmetatable = setmetatable

local IsDestroyed = IsDestroyed
local EntityCategoryGetUnitList = EntityCategoryGetUnitList
local TableGetn = table.getn

---@alias AITaskStatus
--- | 'Unprocessed'
--- | 'Navigating'
--- | 'Building'
--- | 'Deteriorating'
--- | 'Completed'

---@alias AITaskCondition fun(brain: AIBrain, base: AIBase, platoon: AIPlatoon, ...)

---@alias AITaskBrainCondition fun(brain: AIBrain)
---@alias AITaskBaseCondition fun(base: AIBase)

--- A task template that describes the task. It defines whether it is a build or an enhance task. It also describes
---@class AITaskTemplate
---@field Identifier string             # Unique identifier for a task.
---
---@field BuildCategory EntityCategory         # Used when searching for a task and when executing a task. Defines the categories of the unit that we're trying to build
---@field DefaultDistance? number       # Used when searching for a task. If set, any unit that is within this distance to the base can accept this task.
---@field DefaultPriority number        # Used when creating or evaluating the task.
---@field PreferredChunk? string        # Used when executing a task. Specifically used by engineers that are looking for a place to build
---@field BrainConditions AITaskBrainCondition[]
---@field BaseConditions AITaskBaseCondition[]

--- A task instance of a template.
---
--- Semantically a task is not that much different from a command in a build queue. It
--- represents something that we want to build. Something that we can start, progress
--- on and then complete it.
---
--- The average task is created by the brain of an army and assigned to a base. It represents the
--- strategic direction that the brain wants to take. A base can also generate its own tasks to
--- tackle a local, tactical direction.
---@class AITask
---@field Builders Unit[]       # engineers that can issue the build order
---@field Assistees Unit[]      # engineers that can build, but can only assist
---@field BuildBlueprint? UnitId
---@field CreatedBy 'Base' | 'Brain' | 'Unknown'
---@field Priority number
---@field Template AITaskTemplate
---@field Status AITaskStatus
---@field BuildTarget? Unit         # if defined, then the structure that we're trying to build exists
---@field BuildLocation? Vector     # if defined, then the location where the structure that we're trying to build is determined
AITask = ClassSimple {

    ---@param self AITask
    ---@param template AITaskTemplate
    OnCreate = function(self, template)
        self.AcceptedBy = setmetatable({}, WeakValueTable)
        self.AcceptByEntities = setmetatable({}, WeakValueTable)
        self.CreatedBy = 'Unknown'
        self.Priority = template.DefaultPriority
        self.AcceptBySquaredDistance = template.DefaultDistance
        self.Template = template
    end,

    ---@param self AITask
    ---@param brain AIBrain
    ---@param base AIBase
    ---@param unit Unit
    ---@param faction EntityCategory
    ---@param position Vector
    ---@return UnitId?
    ValidateUnit = function(self, brain, base, unit, faction, position)
        -- bail out, task is already completed
        if self.Status =='Completed' then
            return false
        end

        -- local scope for performance
        local template = self.Template
        local status = self.Status
        local target = self.BuildTarget
        local buildCategory = template.BuildCategory
        -- local acceptBySquaredDistance = self.AcceptBySquaredDistance

        -- -- bail out if we're too far away
        -- if acceptBySquaredDistance then
        --     local center = base.Center
        --     local dx = center[1] - position[1]
        --     local dz = center[3] - position[3]
        --     if dx * dx + dz * dz > acceptBySquaredDistance then
        --         return false
        --     end
        -- end

        -- immediately accept if the task is already in progress and we're nearby
        if status == 'InProgress' and target and not IsDestroyed(target) then
            local tx, _, tz = target:GetPositionXYZ()
            local dx = tx - position[1]
            local dz = tz - position[3]
            if dx * dx + dz * dz < 225 then
                return target.Blueprint.BlueprintId
            end
        end

        -- bail out if we're unable to build any units of this build condition
        local unitIds = EntityCategoryGetUnitList(buildCategory * faction)
        local unitIdCount = TableGetn(unitIds)
        if unitIdCount == 0 then
            return false
        end

        local unitId
        for k = 1, unitIdCount do
            local candidate = unitIds[k]
            if unit:CanBuild(candidate) then
                unitId = candidate
                break
            end
        end

        if not unitId then
            return false
        end

        return unitId
    end,

    ---@param self AITask
    ---@param brain AIBrain
    ---@param base AIBase
    ---@return boolean
    ValidateTask = function(self, brain, base)
        local template = self.Template
        local brainConditions = template.BrainConditions
        local baseConditions = template.BaseConditions

        -- this task is done
        if self.Status == 'Completed' then
            return false
        end

        -- check brain conditions
        for k = 1, TableGetn(brainConditions) do
            if not brainConditions[k](brain) then
                return false
            end
        end

        -- check base conditions
        for k = 1, TableGetn(baseConditions) do
            if not baseConditions[k](base) then
                return false
            end
        end

        return true
    end,
}

---@param a AITask
---@param b AITask
TaskCompare = function(a, b)
    return a.Priority > b.Priority
end

--- Filter tasks that are no longer valid _in-place_
---@param tasks AITask[]
---@param brain AIBrain
---@param base AIBase
---@return AITask[]
---@return number
TaskFilter = function(tasks, brain, base)
    local head = 1
    local count = table.getn(tasks)

    -- keep only tasks that are valid
    for k = 1, count do
        local task = tasks[k]
        if task:ValidateTask(brain, base) then
            tasks[head] = task
            head = head + 1
        else
            LOG("Invalidated task: " .. tostring(task.Template.Identifier))
        end
    end

    -- clean up remaining tasks
    for k = head, count do
        tasks[k] = nil
    end

    return tasks, head - 1
end

--- Validates a task template.
---@param template AITaskTemplate
---@return AITaskTemplate?
ValidateAITaskTemplate = function(template)
    if not template.Identifier then
        WARN('AITask - missing field "Identifier" for ', reprs(template))
        return nil
    end

    if not (template.BuildCategory) then
        WARN('AITask - missing field "BuildCategory" for ', reprs(template.Identifier))
        return nil
    end

    if not template.DefaultPriority then
        WARN('AITask - missing field "DefaultPriority" for ', reprs(template.Identifier))
    end

    return template
end

---@param template AITaskTemplate
---@return AITask
function CreateAITask(template)
    local em = AITask()
    em:OnCreate(template)
    return em
end
