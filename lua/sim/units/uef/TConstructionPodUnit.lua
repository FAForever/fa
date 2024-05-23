local TConstructionUnit = import("/lua/terranunits.lua").TConstructionUnit

---@class TConstructionPodUnit : TConstructionUnit
TConstructionPodUnit = ClassUnit(TConstructionUnit) {
    Parent = nil,

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