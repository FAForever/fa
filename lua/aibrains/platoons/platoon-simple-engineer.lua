local AIPlatoon = import("/lua/aibrains/platoons/platoon-base.lua").AIPlatoon
local NavUtils = import("/lua/sim/navutils.lua")
local MarkerUtils = import("/lua/sim/markerutilities.lua")

-- upvalue scope for performance
local TableEmpty = table.empty

---@class AITaskEngineerTemplate : AITaskTemplate
---@field Type 'Building' | 'Repairing' | 'Assisting' | 'Reclaiming'

---@class AIPlatoonEngineerSimple : AIPlatoon
---@field Base AIBase
---@field Brain EasyAIBrain
---@field State { Task: AITask }
AIPlatoonEngineerSimple = Class(AIPlatoon) {

    PlatoonName = 'SimpleEngineerBehavior',

    Start = State {

        StateName = 'Start',

        --- Initial state of any state machine
        ---@param self AIPlatoonEngineerSimple
        Main = function(self)
            if not self.Base then
                self:LogWarning("requires a base reference")
                self:ChangeState(self.Error)
                return
            end

            if not self.Brain then
                self:LogWarning("requires a brain reference")
                self:ChangeState(self.Error)
                return
            end

            -- if not self.Base.StructureManager then
            --     self:LogWarning("requires a structure manager reference")
            --     self:ChangeState(self.Error)
            --     return
            -- end

            -- if not self.Base.EngineerManager then
            --     self:LogWarning("requires an engineer manager reference")
            --     self:ChangeState(self.Error)
            --     return
            -- end

            local units, count = self:GetPlatoonUnits()
            if count > 1 then
                self:LogWarning("multiple units is not supported")
                self:ChangeState(self.Error)
                return
            end

            self:ChangeState(self.SearchingForTask)
            return
        end,
    },

    SearchingForTask = State {

        StateName = 'SearchingForTask',

        --- The platoon searches for a target
        ---@param self AIPlatoonEngineerSimple
        Main = function(self)
            local base = self.Base
            local brain = self.Brain

            local task = base:FindEngineerTask(self)
            LOG("Task found: ")
            reprsl(task)
            if task then
                self:ChangeState(self.Building, { Task = task })
                return

                -- self:ChangeState(self.Assisting, task)
                -- return
            end

            self:ChangeState(self.Idle)
            return
        end,
    },

    Building = State {

        StateName = 'Building',

        ---@param self AIPlatoonEngineerSimple
        Main = function(self)
            local base = self.Base
            local task = self.State.Task
            local units = self:GetPlatoonUnits()

            -- determine a build location
            local buildLocation = task.BuildLocation
            if not buildLocation then
                buildLocation = base:FindBuildLocation()
                task.BuildLocation = buildLocation
            end

            -- issue a build order
            IssueBuildAllMobile(units, buildLocation, task.BuildBlueprint, {})
        end,

        ---@param self AIPlatoonEngineerSimple
        ---@param unit Unit
        ---@param target Unit
        ---@param order string
        OnStartBuild = function(self, unit, target, order)
            local task = self.State.Task
            task.BuildTarget = target
            task.Status = 'InProgress'
        end,

        ---@param self AIPlatoonEngineerSimple
        ---@param unit Unit
        ---@param target Unit
        OnStopBuild = function(self, unit, target)
            local task = self.State.Task

            if target:GetFractionComplete() >= 1.0 then
                task.Status = 'Completed'
            end

            self:ChangeStateExt(self.SearchingForTask, nil)
        end,

        ---@param self AIPlatoonEngineerSimple
        ---@param unit Unit
        ---@param instigator Unit | Projectile | nil
        ---@param type DamageType
        ---@param overkillRatio number
        OnKilled = function(self, unit, instigator, type, overkillRatio)
            local task = self.State.Task
            local buildTarget = task.BuildTarget

            if buildTarget and not IsDestroyed(buildTarget) and buildTarget:GetFractionComplete() < 1.0 then
                task.Status = 'Deteriorating'
            end
        end,
    },

    Assisting = State {

        StateName = 'Assisting',

        --- The structure is upgrading. At the end of the sequence the structure no longer exists
        ---@param self AIPlatoonEngineerSimple
        Main = function(self)
            WaitTicks(40)
            self:ChangeState(self.SearchingForTask)
        end,


    },

    Repairing = State {

        StateName = 'Repairing',

        --- The structure is upgrading. At the end of the sequence the structure no longer exists
        ---@param self AIPlatoonEngineerSimple
        Main = function(self)
            WaitTicks(40)
            self:ChangeState(self.SearchingForTask)
        end,
    },

    Reclaiming = State {

        StateName = 'Reclaiming',

        --- The structure is upgrading. At the end of the sequence the structure no longer exists
        ---@param self AIPlatoonEngineerSimple
        Main = function(self)
            WaitTicks(40)
            self:ChangeState(self.SearchingForTask)
        end,
    },

    Navigating = State {

        StateName = 'Navigating',

        --- The structure is upgrading. At the end of the sequence the structure no longer exists
        ---@param self AIPlatoonEngineerSimple
        Main = function(self)
            WaitTicks(40)
            self:ChangeState(self.SearchingForTask)
        end,
    },

    Idling = State {
        ---@param self AIPlatoonEngineerSimple
        Main = function(self)
            WaitTicks(40)
            self:ChangeState(self.SearchingForTask)
        end,
    }

    -----------------------------------------------------------------
    -- brain events
}

---@param data { }
---@param units Unit[]
DebugAssignToUnits = function(data, units)
    if units and not TableEmpty(units) then
        -- trigger the on stop being built event of the brain
        for k = 1, table.getn(units) do
            local unit = units[k]
            unit.Brain:OnUnitStopBeingBuilt(unit, nil, unit.Layer)
        end
    end
end
