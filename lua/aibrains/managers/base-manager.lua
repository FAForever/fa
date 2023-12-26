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

local TaskCreate = import("/lua/aibrains/tasks/task.lua").CreateAITask
local TaskCompare = import("/lua/aibrains/tasks/task.lua").TaskCompare
local TaskFilter = import("/lua/aibrains/tasks/task.lua").TaskFilter

local FactoryManager = import("/lua/aibrains/managers/factory-manager.lua")
local EngineerManager = import("/lua/aibrains/managers/engineer-manager.lua")
local StructureManager = import("/lua/aibrains/managers/structure-manager.lua")

local Debug = true

-- upvalue scope for performance
local TableGetn = table.getn
local TableSort = table.sort

---@alias LocationType
--- can only be applied to the main base
--- | 'MAIN'
--- can be applied by any base
--- | 'LocationType'
--- name of expansion marker of the base
--- | string

---@class AIBaseDebugInfo
---@field Position Vector
---@field Layer NavLayers
---@field Managers { EngineerManagerDebugInfo: AIEngineerManagerDebugInfo, StructureManagerDebugInfo: AIStructureManagerDebugInfo, FactoryManagerDebugInfo: AIFactoryManagerDebugInfo }

---@class AIBase
---@field Brain AIBrain
---@field DebugInfo AIBaseDebugInfo
---@field FactoryManager AIFactoryManager
---@field EngineerManager AIEngineerManager
---@field StructureManager AIStructureManager
---@field EngineeringTasksBrain AITask[]
---@field EngineeringTasksBase AITask[]
---@field EngineeringTasks AITask[]     # Tasks specifically for engineers
---@field Center Vector
---@field Trash TrashBag
AIBase = ClassSimple {

    ---@param self AIBase
    OnCreate = function(self, brain, location)
        -- store various properties
        self.Brain = brain
        self.Center = location
        self.Trash = TrashBag()

        -- create the various managers
        self.FactoryManager = FactoryManager.CreateFactoryManager(brain, self, '')
        self.EngineerManager = EngineerManager.CreateEngineerManager(brain, self, '')
        self.StructureManager = StructureManager.CreateStructureManager(brain, self, '')

        self.EngineeringTasksBrain = {}
        self.EngineeringTasksBase = {}
        self.EngineeringTasks = {}

        -- start evaluating the base
        self.Trash:Add(ForkThread(self.EvaluateBaseThread, self))
    end,

    ---@param self AIBase
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,

    ---------------------------------------------------------------------------
    --#region Base evaluation

    --- Delay in is game ticks
    EvaluateDelay = 11,

    ---@param self AIBase
    EvaluateBaseThread = function(self)
        while true do
            -- evaluate the base in a protected call to guarantee we can keep evaluating it in the future
            local ok, msg = pcall(self.EvaluateBase, self)
            if not ok then
                WARN(msg)
            end

            local evaluateDelay = self.EvaluateDelay
            if evaluateDelay < 0 then
                evaluateDelay = 1
            end

            WaitTicks(evaluateDelay)
        end
    end,

    ---@param self AIBase
    EvaluateEngineerTasks = function(self)
        local brain = self.Brain
        local engineerTasks = self.EngineeringTasks
        local engineerBrainTasks, engineerBrainTaskCount = TaskFilter(self.EngineeringTasksBrain, brain, self)
        local engineerBaseTasks, engineerBaseTaskCount = TaskFilter(self.EngineeringTasksBase, brain, self)

        local head = 1

        -- gather base tasks
        for k = 1, engineerBaseTaskCount do
            engineerTasks[head] = engineerBaseTasks[k]
            head = head + 1
        end

        -- gather brain tasks
        for k = 1, engineerBrainTaskCount do
            engineerTasks[head] = engineerBrainTasks[k]
            head = head + 1
        end

        -- remove remaining tasks
        for k = head, table.getn(engineerTasks) do
            engineerTasks[k] = nil
        end

        -- sort the tasks by priority
        TableSort(engineerTasks, TaskCompare)
    end,

    ---@param self AIBase
    EvaluateBase = function(self)



        self:EvaluateEngineerTasks()
    end,

    --#region

    ---------------------------------------------------------------------------
    --#region Engineering tasks

    ---@param self AIBase
    ---@param template AITaskTemplate
    AddBrainTask = function(self, template)
        local task = TaskCreate(template)
        local engineerBrainTasks = self.EngineeringTasksBrain
        engineerBrainTasks[table.getn(engineerBrainTasks) + 1] = task
    end,

    ---@param self AIBase
    ---@param platoon AIPlatoon
    ---@return AITask | nil
    FindEngineerTask = function(self, platoon)
        local brain = self.Brain
        local engineerTasks = self.EngineeringTasks

        -- retrieve relevant information from the platoon
        local unit = platoon:GetPlatoonUnits()[1]
        local unitFaction = categories[unit.Blueprint.FactionCategory]
        local unitPosition = unit:GetPosition()

        -- find a task that this platoon can pick up
        for k = 1, table.getn(engineerTasks) do
            local engineerTask = engineerTasks[k]
            local buildBlueprint = engineerTask:ValidateUnit(brain, self, unit, unitFaction, unitPosition)
            if buildBlueprint then
                engineerTask.BuildBlueprint = buildBlueprint
                return engineerTask
            end
        end

        return nil
    end,

    FindBuildLocation = function(self, position, unitId)
        self.TestIndex = (self.TestIndex or 0) + 1
        local values = {
            { 10, GetSurfaceHeight(10, 10), 10 },
            { 16, GetSurfaceHeight(10, 10), 16 },
            { 20, GetSurfaceHeight(10, 10), 20 },
            { 24, GetSurfaceHeight(10, 10), 24 }
        }

        LOG(self.TestIndex)
        return values[self.TestIndex]

    end,

    --#endregion

    ------------------------------------------------------------------------------------------
    -- unit events

    --- Called by a unit as it starts being built
    ---@param self AIBase
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnStartBeingBuilt = function(self, unit, builder, layer)
        self.FactoryManager:OnStartBeingBuilt(unit, builder, layer)
        self.EngineerManager:OnStartBeingBuilt(unit, builder, layer)
        self.StructureManager:OnStartBeingBuilt(unit, builder, layer)
    end,

    --- Called by a unit as it is finished being built
    ---@param self AIBase
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, unit, builder, layer)
        self.FactoryManager:OnStopBeingBuilt(unit, builder, layer)
        self.EngineerManager:OnStopBeingBuilt(unit, builder, layer)
        self.StructureManager:OnStopBeingBuilt(unit, builder, layer)
    end,

    --- Called by a unit as it is destroyed
    ---@param self AIBase
    ---@param unit Unit
    OnUnitDestroy = function(self, unit)
        self.FactoryManager:OnUnitDestroy(unit)
        self.EngineerManager:OnUnitDestroy(unit)
        self.StructureManager:OnUnitDestroy(unit)
    end,

    --- Called by a unit as it starts building
    ---@param self AIBase
    ---@param unit Unit
    ---@param built Unit
    OnUnitStartBuild = function(self, unit, built)
        self.FactoryManager:OnUnitStartBuild(unit, built)
        self.EngineerManager:OnUnitStartBuild(unit, built)
        self.StructureManager:OnUnitStartBuild(unit, built)
    end,

    --- Called by a unit as it stops building
    ---@param self AIBase
    ---@param unit Unit
    ---@param built Unit
    OnUnitStopBuild = function(self, unit, built)
        self.FactoryManager:OnUnitStopBuild(unit, built)
        self.EngineerManager:OnUnitStopBuild(unit, built)
        self.StructureManager:OnUnitStopBuild(unit, built)
    end,

    ---------------------------------------------------------------------------
    --#region Debug functionality

    ---@param self AIBase
    ---@return AIBaseDebugInfo
    GetDebugInfo = function(self)
        local info = self.DebugInfo
        if not info then
            info = {}
            self.DebugInfo = info

            info.Managers = info.Managers or {}
            info.Position = self.Position
            info.Layer = self.Layer
        end

        info.Managers.EngineerManagerDebugInfo = self.EngineerManager:GetDebugInfo()
        info.Managers.FactoryManagerDebugInfo = self.FactoryManager:GetDebugInfo()
        info.Managers.StructureManagerDebugInfo = self.StructureManager:GetDebugInfo()

        return info
    end,

    --#endregion
}

---@param brain AIBrain
---@param location Vector
---@return AIBase
function CreateBaseManager(brain, location)
    local em = AIBase()
    em:OnCreate(brain, location)
    return em
end
