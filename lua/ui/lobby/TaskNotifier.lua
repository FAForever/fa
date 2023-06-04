-- ==========================================================================================
-- * File       : lua/modules/ui/lobby/TaskNotifier.lua
-- * Authors    : FAF Community, HUSSAR
-- * Summary    : Contains logic for notifying UI about progress of single or multiple tasks
-- ==========================================================================================
-- how to use TaskNotifier:
-- local taskNotifier = import("/lua/ui/lobby/tasknotifier.lua").Create()
-- -- set callback function for updating UI when a task's progress is changed
-- taskNotifier.OnProgressCallback = OnTaskProgress
-- -- set callback function for updating UI
-- taskNotifier.OnCompleteCallback = OnTaskComplete
-- for single task:
-- taskNotifier.totalUpdates = 2
-- taskNotifier:Update('task name with 2 updates', 2, 1) -- total progress = 0.5, task progress = 0.50
-- taskNotifier:Update('task name with 2 updates', 2, 2) -- total progress = 1.0, task progress = 1.00
-- taskNotifier:Complete()
-- or
-- for multiple tasks, set total number of updates from all tasks
-- taskNotifier.totalUpdates = 5
-- update the TaskNotifier, each time progress of tasks should change:
-- taskNotifier:Update('task name 1 with 2 updates', 2, 1) -- total progress = 0.2, task progress = 0.50
-- taskNotifier:Update('task name 1 with 2 updates', 2, 2) -- total progress = 0.4, task progress = 1.00
-- taskNotifier:Update('task name 2 with 3 updates', 3, 1) -- total progress = 0.6, task progress = 0.33
-- taskNotifier:Update('task name 2 with 3 updates', 3, 2) -- total progress = 0.8, task progress = 0.66
-- taskNotifier:Update('task name 2 with 3 updates', 3, 4) -- total progress = 1.0, task progress = 1.00
-- taskNotifier:Complete()

-- function OnTaskProgress(task)
--     --TODO update UI progress bar with info about the task
-- end
-- function OnTaskComplete()
--     --TODO complete and hide UI progress bar
-- end

function Create()
    ---@class TaskNotifier
    return {
        tasks = {},
        currentUpdate = 0,
        totalUpdates = 0,
        totalProgress = 0,
        lastUpdateTime = CurrentTime(),
        OnProgressCallback = false,
        OnCompleteCallback = false,
        -- reset all tasks and progress
        Reset = function(self)
            self.tasks = {}
            self.currentTask = nil
            self.currentUpdate = 0
            self.totalUpdates = 0
            self.totalProgress = 0
            self.lastUpdateTime = nil
        end,
        -- updates progress of specified task and notifies UI
        -- @param taskGoal - an integer specifying how many updates there are for this task
        -- @param taskGoal - an integer specifying current update of a task
        -- note tasks progress = taskUpdate / taskGoal
        Update = function(self, taskName, taskGoal, taskUpdate)
            if not self.totalUpdates or self.totalUpdates == 0 then
                WARN('TaskNotifier cannot update while total number of updates is not specified or invalid')
                return
            elseif not taskName then
                WARN('TaskNotifier cannot update while taskName is not specified')
                return
            elseif not taskGoal or taskGoal == 0 then
                WARN('TaskNotifier cannot update while taskGoal is not specified or invalid')
                return
            end
            -- ensure each task has unique key
            local key = taskName..'-'..taskGoal
            -- update stats for specified task
            if self.tasks[key] then
               self.tasks[key].update = taskUpdate
               if self.tasks[key].goal > 0 then
                    self.tasks[key].progress = self.tasks[key].update / self.tasks[key].goal
               end
            else -- create a new task
                self.tasks[key] = {}
                self.tasks[key].name = taskName
                self.tasks[key].goal = taskGoal
                self.tasks[key].update = 0
                self.tasks[key].progress = 0
            end

            self.currentTask = self.tasks[key]

            -- calculate total progress based on current count of updates
            self.currentUpdate = self.currentUpdate + 1
            if self.totalUpdates > 0 then
               self.totalProgress = self.currentUpdate / self.totalUpdates
               if self.totalProgress > 1 then
                  self.totalProgress = 1
               end
            end
            -- filter out unnecessary UI updates to increase performance
            if not self.lastUpdateTime or CurrentTime() - self.lastUpdateTime > 0.25 then
                self.lastUpdateTime = CurrentTime()
                -- notify UI using OnProgress callback
                if self.OnProgressCallback then
                   self.OnProgressCallback(self.currentTask)
                   WaitSeconds(0.001) -- allow UI to refresh
                end
            end
        end,
        -- completes progress of current task and notifies UI
        Complete = function(self)
            self.totalProgress = 1
            -- complete current task and notify UI
            if self.currentTask and self.OnProgressCallback then
               self.currentTask.progress = 1
               self.OnProgressCallback(self.currentTask)
               WaitSeconds(0.001) -- allow UI to refresh
            end

            if self.OnCompleteCallback then
               self.OnCompleteCallback()
            end
        end,
    }
end