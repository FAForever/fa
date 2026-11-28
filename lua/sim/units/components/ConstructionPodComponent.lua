local CreateUnitHPR = CreateUnitHPR
local CreateEconomyEvent = CreateEconomyEvent
local RemoveEconomyEvent = RemoveEconomyEvent
local KillThread = KillThread
local WaitFor = WaitFor
local WaitTicks = WaitTicks

--- Removes the drone from the rebuild queue, so that the next queued drone starts its rebuild
---@param unit ConstructionPodUnit
---@param name string
local function LeavePodRebuildQueue(unit, name)
    local queue = unit.PodRebuildQueue
    if queue then
        for i, queued in queue do
            if queued == name then
                table.remove(queue, i)
                break
            end
        end
    end
end

--- Intellisense helper class
---@class ConstructionPodUnit : ConstructionPodComponent, Unit

--- A drone that the unit carries. Its key in [PodDefinitions](lua://ConstructionPodComponent.PodDefinitions) is the
--- drone's name: the unit field that holds the drone. The enhancement `<name>Remove` removes it
---@class ConstructionPodDefinition
---@field UnitId UnitId # A `TConstructionPodUnit`
---@field Bone Bone # Where the drone is created
---@field RebuildTime? number # Seconds. Defaults to the drone's build time divided by the unit's build rate
---@field QueueRebuild? boolean # Rebuild one at a time with the unit's other `QueueRebuild` drones, in the order they died

---@class ConstructionPodSlot
---@field Enabled boolean # Set by `AddPod` and cleared by `RemovePod`. Only an enabled drone is rebuilt
---@field RebuildThread? thread
---@field RebuildEvent? EconomyEvent

--- Gives a unit drones (`TConstructionPodUnit`) that assist it, are rebuilt when they die, and are removed with their
--- enhancement. The unit defines [PodDefinitions](lua://ConstructionPodComponent.PodDefinitions) and calls the
--- component's functions. The component doesn't override any unit functions, and carries the drones over a transfer
--- with the transfer callback `ConstructionPods`
---@class ConstructionPodComponent
---@field PodDefinitions table<string, ConstructionPodDefinition>
---@field PodSlots? table<string, ConstructionPodSlot>
---@field PodRebuildQueue? string[] # Drones with `QueueRebuild` that wait for or are in their rebuild. The first one is being rebuilt
ConstructionPodComponent = ClassSimple {

    --- Returns the drone's state, and creates the state on first use
    ---@param self ConstructionPodUnit
    ---@param name string
    ---@return ConstructionPodSlot
    GetPodSlot = function(self, name)
        local slots = self.PodSlots
        if not slots then
            slots = {}
            self.PodSlots = slots
        end
        local slot = slots[name]
        if not slot then
            slot = { Enabled = false }
            slots[name] = slot
        end
        return slot
    end,

    --- Returns the drone with this name if it is alive
    ---@param self ConstructionPodUnit
    ---@param name string
    ---@return TConstructionPodUnit?
    GetPod = function(self, name)
        local pod = self[name]
        if pod and not pod.Dead then
            return pod
        end
    end,

    --- Returns the drones that are alive
    ---@param self ConstructionPodUnit
    ---@return TConstructionPodUnit[]
    GetPods = function(self)
        local pods = {}
        for name in self.PodDefinitions do
            local pod = self:GetPod(name)
            if pod then
                table.insert(pods, pod)
            end
        end
        return pods
    end,

    --- Returns the economy event of the drone's rebuild, if it is being rebuilt
    ---@param self ConstructionPodUnit
    ---@param name string
    ---@return EconomyEvent?
    GetPodRebuildEvent = function(self, name)
        return self.PodSlots[name].RebuildEvent
    end,

    --- Creates the drone at its bone and links it to the unit
    ---@param self ConstructionPodUnit
    ---@param name string
    ---@return TConstructionPodUnit
    CreatePod = function(self, name)
        local definition = self.PodDefinitions[name]
        local location = self:GetPosition(definition.Bone)
        local pod = CreateUnitHPR(definition.UnitId, self.Army, location[1], location[2], location[3], 0, 0, 0) --[[@as TConstructionPodUnit]]
        pod:SetParent(self, name)
        pod:SetCreator(self)
        self.Trash:Add(pod)
        self[name] = pod
        return pod
    end,

    --- Enables the drone and creates it, unless it is alive or being rebuilt. Call it from the drone's enhancement
    ---@see ConstructionPodComponent.RemovePod
    ---@param self ConstructionPodUnit
    ---@param name string
    AddPod = function(self, name)
        local slot = self:GetPodSlot(name)
        slot.Enabled = true
        if not self.TransferCallbacks.ConstructionPods then
            self:AddTransferCallback('ConstructionPods', true, self.SavePodsForTransfer, self.RestorePodsAfterTransfer)
        end
        -- the enhancement is applied again a tick after a transfer that already restored the drone
        if not self:GetPod(name) and not slot.RebuildThread then
            self:CreatePod(name)
        end
    end,

    --- Disables the drone, kills it, and cancels its rebuild. Call it from the enhancement that removes the drone
    ---@see ConstructionPodComponent.AddPod
    ---@param self ConstructionPodUnit
    ---@param name string
    RemovePod = function(self, name)
        local slot = self:GetPodSlot(name)
        slot.Enabled = false

        local thread = slot.RebuildThread
        if thread then
            KillThread(thread)
            slot.RebuildThread = nil
            LeavePodRebuildQueue(self, name)
        end
        local event = slot.RebuildEvent
        if event then
            RemoveEconomyEvent(self, event)
            slot.RebuildEvent = nil
            self:SetWorkProgress(0.0)
        end

        local pod = self:GetPod(name)
        if pod then
            pod:Kill()
        end
        self[name] = nil
    end,

    --- Starts rebuilding the drone if it is enabled, dead, and not already being rebuilt
    ---@param self ConstructionPodUnit
    ---@param name string
    RebuildPod = function(self, name)
        local slot = self:GetPodSlot(name)
        if slot.Enabled and not slot.RebuildThread and not self:GetPod(name) then
            slot.RebuildThread = self:ForkThread(self.RebuildPodThread, name)
        end
    end,

    ---@param self ConstructionPodUnit
    ---@param name string
    RebuildPodThread = function(self, name)
        local definition = self.PodDefinitions[name]
        local slot = self:GetPodSlot(name)

        if definition.QueueRebuild then
            -- rebuild in the order the drones died, one at a time
            local queue = self.PodRebuildQueue
            if not queue then
                queue = {}
                self.PodRebuildQueue = queue
            end
            table.insert(queue, name)
            while queue[1] ~= name do
                WaitTicks(1)
            end
        end

        local economy = __blueprints[definition.UnitId].Economy
        local time = definition.RebuildTime or economy.BuildTime / self:GetBuildRate()
        local event = CreateEconomyEvent(self, economy.BuildCostEnergy, economy.BuildCostMass, time, self.SetWorkProgress)
        slot.RebuildEvent = event
        self:RequestRefreshUI()
        WaitFor(event)
        self:SetWorkProgress(0.0)
        RemoveEconomyEvent(self, event)
        slot.RebuildEvent = nil
        slot.RebuildThread = nil
        LeavePodRebuildQueue(self, name)

        self:CreatePod(name)
        self:RequestRefreshUI()
    end,

    --- Called by the drone when it is killed. Rebuilds the drone if `rebuildDrone` is set
    ---@see TConstructionPodUnit.OnKilled
    ---@param self ConstructionPodUnit
    ---@param name string
    ---@param rebuildDrone? boolean
    NotifyOfPodDeath = function(self, name, rebuildDrone)
        self[name] = nil
        if rebuildDrone and not self.Dead then
            self:RebuildPod(name)
        end
    end,

    --- Moves the drones that only assist the unit to its current task. Call it when the unit starts or stops building,
    --- repairing, or reclaiming
    ---@param self ConstructionPodUnit
    RefreshPodFocus = function(self)
        for _, pod in self:GetPods() do
            -- AssistCommander
            if pod:GetCommandQueue()[1].commandType == 29 then
                IssueToUnitClearCommands(pod)
            end
        end
    end,

    --- Destroys the drones and returns their health. Called before a transfer by the transfer callback that `AddPod`
    --- adds
    ---@see ConstructionPodComponent.RestorePodsAfterTransfer
    ---@param self ConstructionPodUnit
    ---@return table<string, number | false>? # Health of each enabled drone, `false` if it is dead, or `nil` if no drone is enabled
    SavePodsForTransfer = function(self)
        -- a drone docked on its parent is cargo, which the engine transfers as an extra drone without a parent
        local slots = self.PodSlots
        if not slots then
            return nil
        end

        local data
        for name, slot in slots do
            if slot.Enabled then
                data = data or {}
                local pod = self:GetPod(name)
                if pod then
                    data[name] = pod:GetHealth()
                    pod:Destroy()
                    self[name] = nil
                else
                    data[name] = false
                end
            end
        end
        return data
    end,

    --- Recreates the drones with their health, and rebuilds the dead ones. Called after a transfer by the transfer
    --- callback that `AddPod` adds
    ---@see ConstructionPodComponent.SavePodsForTransfer
    ---@param self ConstructionPodUnit
    ---@param data? table<string, number | false> # The value returned by `SavePodsForTransfer`
    RestorePodsAfterTransfer = function(self, data)
        if not data then
            return
        end

        for name, health in data do
            local slot = self:GetPodSlot(name)
            slot.Enabled = true
            if health then
                if not self:GetPod(name) then
                    self:CreatePod(name):SetHealth(self, health)
                end
            else
                -- so that a transfer doesn't create a dead drone for free
                self:RebuildPod(name)
            end
        end
    end,
}
