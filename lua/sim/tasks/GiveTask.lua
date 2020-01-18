local ScriptTask = import('/lua/sim/ScriptTask.lua').ScriptTask
local TASKSTATUS = import('/lua/sim/ScriptTask.lua').TASKSTATUS
local AIRESULT = import('/lua/sim/ScriptTask.lua').AIRESULT
local GiveUnitsToPlayer = import('/lua/simutils.lua').GiveUnitsToPlayer
local SpawnPing = import('/lua/SimPing.lua').SpawnPing

local transferList =  {}
GiveTask = Class(ScriptTask) {
    OnCreate = function(self, commandData)
        ScriptTask.OnCreate(self, commandData)

        local unit = self:GetUnit()
        local from = unit.Army
        local to = commandData.To

        self.Army = from

        transferList[from] = transferList[from] or {}
        transferList[from][to] = transferList[from][to] or {}
        table.insert(transferList[from][to], unit)

        self.first = true
    end,

    TaskTick = function(self)
        if self.first then
            -- Wait a tick to let all GiveTask commands execute
            self.first = false
            return TASKSTATUS.Wait
        end

        for to, array in transferList[self.Army] or {} do
            local units = {}
            for _, unit in array do
                if not unit.Dead and unit.Army == self.Army then
                    table.insert(units, unit)
                end
            end

            if units[1] then
                GiveUnitsToPlayer({To=to}, units)
                local data = {
                    Type='alert',
                    Location=units[1]:GetPosition(),
                    Lifetime=10,
                    Owner=self.Army,
                    To=to,
                    Ring='/game/marker/ring_yellow02-blur.dds',
                    Sound='UEF_Select_Radar',
                    Mesh='alert_marker',
                    ArrowColor='yellow',
                }
                SpawnPing(data)
           end
        end

        transferList[self.Army] = {}
        return TASKSTATUS.Done
    end,
}
