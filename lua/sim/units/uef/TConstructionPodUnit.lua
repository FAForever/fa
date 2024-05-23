local TConstructionUnit = import("/lua/terranunits.lua").TConstructionUnit

---@class TConstructionPodUnit : TConstructionUnit
---@field guardDummy Unit
TConstructionPodUnit = ClassUnit(TConstructionUnit) {
    Parent = nil,

    OnCreate = function(self)
        TConstructionUnit.OnCreate(self)
        self.guardDummy = CreateUnitHPR('ZXA0003', self:GetArmy(), 0,0,0,0,0,0)
        self.guardDummy:AttachTo(self, -1)
        self.Trash:Add(self.guardDummy)
    end,

    OnScriptBitSet = function(self, bit)
        TConstructionUnit.OnScriptBitSet(self, bit)
        if bit == 1 then
            self.rebuildDrone = true
        end
    end,

    OnScriptBitClear = function(self, bit)
        TConstructionUnit.OnScriptBitClear(self, bit)
        if bit == 1 then
            self.rebuildDrone = false
        end
    end,

    OnAttachedToTransport = function(self, transport, bone)
        local guards = self:GetGuards()
        IssueClearCommands(guards)
        IssueGuard(guards, self.guardDummy)
        TConstructionUnit.OnAttachedToTransport(self, transport, bone)
    end,

    OnDetachedFromTransport = function(self, transport, bone)
        TConstructionUnit.OnDetachedFromTransport(self, transport, bone)
        local guards = self.guardDummy:GetGuards()
        IssueClearCommands(guards)
        IssueGuard(guards, self)
    end,

    SetParent = function(self, parent, podName)
        self.Parent = parent
        self.Pod = podName
        self:SetScriptBit('RULEUTC_WeaponToggle', true)
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        self.Parent:NotifyOfPodDeath(self.Pod, self.rebuildDrone)
        self.Parent = nil
        TConstructionUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

    -- Don't make wreckage
    CreateWreckage = function (self, overkillRatio)
        overkillRatio = 1.1
        TConstructionUnit.CreateWreckage(self, overkillRatio)
    end,
}