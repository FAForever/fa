
local ScriptTask = import("/lua/sim/scripttask.lua").ScriptTask
local TASKSTATUS = import("/lua/sim/scripttask.lua").TASKSTATUS
local AIRESULT = import("/lua/sim/scripttask.lua").AIRESULT

-- You can issue this task by using:
-- IssueCommand("UNITCOMMAND_Script", { TaskName = "TestTask", Wait = Random(4)*7 }, false)
-- IssueUnitCommand(GetSelectedUnits(), "UNITCOMMAND_Script", { TaskName = "TestTask", Wait = Random(4)*7 }, false)
-- import('/lua/ui/game/commandmode.lua').StartCommandMode('order', { name = "RULEUCC_Script", TaskName = "TestTask" }) -- Note: `UserScriptCommand` overwrites the LuaParams table, so Wait can't be used.
-- or Sim-Side:
-- IssueScript(SelectedUnit(), { TaskName = "TestTask", Wait = Random(4)*7 })

---@class TestTask : ScriptTask
---@field CommandData { TaskName: "TestTask", Wait: number, tailCall?: true } # LuaParams table from the user side. This table is shared by all units ordered the task from one command.
---@field Wait number\
---@field tailCall? true
---@field unitId EntityId # self:GetUnit():GetEntityId()
TestTask = Class(ScriptTask) {

    --- Called immediately when task is created
    --- Initialize lua param wait times
    ---@param self TestTask
    ---@param commandData { TaskName: TestTask, Wait: number } # LuaParams table from the user side. This table is shared by all units ordered the task from one command.
    OnCreate = function (self, commandData)
        ScriptTask.OnCreate(self, commandData)
        LOG(('task %s for unit %s started at tick %d, waiting for %d ticks (until tick %d)'):format(
            tostring(self)
            , tostring(self.unitId)
            , GetGameTick()
            , (commandData.Wait or 5)
            , GetGameTick() + (commandData.Wait or 5)
        ))
        self.Wait = commandData.Wait or 5
        self.unitId = self:GetUnit():GetEntityId()
        LOG(repr(commandData))
        -- LOG(repr(self, {meta = true}))

        -- self:GetUnit():SetBusy(true)
        -- self:GetUnit():SetBlockCommandQueue(true)

        -- if self.Wait >= 2 then
        --     IssueScript({self:GetUnit()}, { TaskName = 'TestTask', Wait = self.Wait - 1 })
        -- end

    end,

    --- Called by the engine every tick. Function must return a value in TaskStatus
    ---@param self TestTask
    ---@return ScriptTaskStatus
    TaskTick = function(self)
        -- "tail call" example: this isn't a true tail call because the queue isn't guaranteed to be empty, 
        -- so execution may not go to the next issued command unless the command queue is cleared first

        -- if not self.CommandData.tailCall then
        --     -- IssueScript({ self:GetUnit() }, { TaskName = "TestTask", Wait = self.Wait, tailCall = true })
        --     self.CommandData.tailCall = true

            -- LOG(repr(self, {meta = true}))

        --     -- ForkThread(function(u)
        --     --     while not IsDestroyed(u) do
        --     --         u:DebugPrintCurrentStates()
        --     --         WaitTicks(1)
        --     --     end
        --     -- end, self:GetUnit())

        --     return TASKSTATUS.Done
        -- end

        local wait = self.Wait

        if wait == TASKSTATUS.Done then
            self:GetUnit():DebugToggleTrackingStateChanges()

            -- if GetGameTick() > self.delaytick then
            --     LOG(('task %s for unit %s ended at tick %d with an actual delay'):format(tostring(self), tostring(self.unitId), GetGameTick()))
            -- end

            LOG(('task %s for unit %s ended at tick %d'):format(tostring(self), tostring(self.unitId), GetGameTick()))

            return wait
        elseif wait == TASKSTATUS.Delay then
            self.Wait = TASKSTATUS.Done
            self.delaytick = GetGameTick()
            -- LOG(('task %s delayed at tick %d'):format(tostring(self), GetGameTick()))

            return wait
        else
            self.Wait = TASKSTATUS.Done
            -- LOG(('task %s waited at tick %d until %d'):format(tostring(self), GetGameTick(), GetGameTick() + wait - 1))
            return wait
        end
    end,

    --- Called by the engine when the task is destroyed. This could be it naturally going away after completion or because it was cancelled by another task.
    ---@param self TestTask
    OnDestroy = function(self)
        LOG(('task %s destroyed at tick %d'):format(tostring(self), GetGameTick()))

        -- self:GetUnit():SetBusy(false)
        -- self:GetUnit():SetBlockCommandQueue(false)

        self:SetAIResult(AIRESULT.Success)
    end,
}
