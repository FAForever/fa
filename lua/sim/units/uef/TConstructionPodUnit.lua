local TConstructionUnit = import("/lua/terranunits.lua").TConstructionUnit
local oldGetGuards = TConstructionUnit.GetGuards

---@class TConstructionPodUnit : TConstructionUnit
---@field Pod string
---@field Parent? UEL0301 | UEL0001 # Only these two units set the parent properly
---@field guardCache table
---@field guardDummy Unit
---@field rebuildDrone boolean # If true, the parent should rebuild the pod. Caches script bit 1.
TConstructionPodUnit = ClassUnit(TConstructionUnit) {
    Parent = nil,

    ---@param self TConstructionPodUnit
    OnCreate = function(self)
        TConstructionUnit.OnCreate(self)
        self.guardDummy = CreateUnitHPR('ZXA0003', self:GetArmy(), 0,0,0,0,0,0)
        self.guardDummy:AttachTo(self, -1)
        self.Trash:Add(self.guardDummy)
    end,

    ---@param self TConstructionPodUnit
    ---@param bit number
    OnScriptBitSet = function(self, bit)
        TConstructionUnit.OnScriptBitSet(self, bit)
        if bit == 1 then
            self.rebuildDrone = true
        end
    end,

    ---@param self TConstructionPodUnit
    ---@param bit number
    OnScriptBitClear = function(self, bit)
        TConstructionUnit.OnScriptBitClear(self, bit)
        if bit == 1 then
            self.rebuildDrone = false
        end
    end,

    ---@param self TConstructionPodUnit
    ---@param transport Unit
    ---@param bone number
    OnAttachedToTransport = function(self, transport, bone)
        local guards = self:GetGuards()
        IssueClearCommands(guards)
        IssueGuard(guards, self.guardDummy)
        TConstructionUnit.OnAttachedToTransport(self, transport, bone)
    end,

    ---@param self TConstructionPodUnit
    ---@param transport Unit
    ---@param bone number
    OnDetachedFromTransport = function(self, transport, bone)
        TConstructionUnit.OnDetachedFromTransport(self, transport, bone)
        local guards = self.guardDummy:GetGuards()
        IssueClearCommands(guards)
        IssueGuard(guards, self)
    end,

    ---@param self TConstructionPodUnit
    ---@param parent UEL0301 | UEL0001 # Only these two implement the function `NotifyOfPodDeath`
    ---@param podName string
    SetParent = function(self, parent, podName)
        self.Parent = parent
        self.Pod = podName
        self:SetScriptBit('RULEUTC_WeaponToggle', true)
    end,

    ---@param self TConstructionPodUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        TConstructionUnit.OnStartBuild(self, unitBeingBuilt, order)
        self:FocusAssistersOnCurrentTask()
    end,

    ---@param self TConstructionPodUnit
    ---@param built Unit
    ---@param order string
    OnStopBuild = function(self, built, order)
        TConstructionUnit.OnStopBuild(self, built, order)
        -- Check if we finished our build task and clear our cached command if so
        if self.guardCache and built:GetFractionComplete() == 1 then
            self.guardCache = nil
        end
    end,

    ---@param self TConstructionPodUnit
    ---@param target Unit|Prop
    OnStartReclaim = function(self, target)
        TConstructionUnit.OnStartReclaim(self, target)
        self:FocusAssistersOnCurrentTask()
    end,

    ---@param self TConstructionPodUnit
    ---@param target Unit|Prop
    OnStopReclaim = function(self, target)
        TConstructionUnit.OnStopReclaim(self, target)
        -- Check if we finished our reclaim task and clear our cached commaand if so
        if self.guardCache and table.empty(target) then
            self.guardCache = nil
        end
    end,

    ---@param self TConstructionPodUnit
    ---@param unitBeingRepaired Unit
    OnStartRepair = function(self, unitBeingRepaired)
        TConstructionUnit.OnStartRepair(self, unitBeingRepaired)
        self:FocusAssistersOnCurrentTask()
    end,

    ---@param self TConstructionPodUnit
    FocusAssistersOnCurrentTask = function(self)

        if self.Dead then
            return
        end

        local engineerGuards = self:GetGuards()

        -- Make sure we've got some assisters to work with
        if not next(engineerGuards) then
            self.guardCache = nil
            return
        end

        -- Make sure we're performing an engineering task
        if not (self:IsUnitState('Reclaiming')
        or self:IsUnitState('Building')
        or self:IsUnitState('Repairing')) then
            return
        end

        local command
        if self:IsUnitState('Reclaiming') then
            command = IssueReclaim
        elseif self:IsUnitState('Repairing') or self:IsUnitState('Building') then
            command = IssueRepair
        end

        -- We only need to worry about refocusing our guards if we currently have an engineering target
        local target = self:GetFocusUnit() or self:GetCommandQueue()[1].target
        if target then
            IssueClearCommands(engineerGuards)
            command(engineerGuards, target)
            IssueGuard(engineerGuards, self)
            self.guardCache = engineerGuards
            self.guardCache.target = target
            self.guardCache.command = command
        end
    end,

    ---Called via hotkey to refocus assisters on our current task
    ---@param self TConstructionPodUnit
    RefocusAssisters = function(self)
        local engineerGuards = EntityCategoryFilterDown(categories.ENGINEER, self:GetGuards())
        IssueClearCommands(engineerGuards)
        if self.guardCache then
            LOG('We have a guard cache')
            self.guardCache.command(engineerGuards, self.guardCache.target)
        end
        IssueGuard(engineerGuards, self)
    end,

    ---Override get guards to pick up our assist cache
    ---@param self TConstructionPodUnit
    GetGuards = function(self)
        local guards = oldGetGuards(self)
        local count = 0
        if self.guardCache then
            local firstCommand, secondCommand
            local target = self.guardCache.target
            for _, guard in ipairs(self.guardCache) do
                firstCommand, secondCommand = unpack(guard:GetCommandQueue())
                if firstCommand.target == target
                and secondCommand.target == self then
                    table.insert(guards, guard)
                    count = count + 1
                end
            end
        end
        if count > 0 then
            print(string.format('Found %d cached guards', count))
        end
        return guards
    end,

    ---@param self TConstructionPodUnit
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        local parent = self.Parent
        if parent then
            parent:NotifyOfPodDeath(self.Pod, self.rebuildDrone)
            self.Parent = nil
        end
        TConstructionUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

    CreateWreckage = function (self, overkillRatio)
        -- Don't make wreckage
    end,
}