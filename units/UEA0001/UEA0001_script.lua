-----------------------------------------------------------------
-- File     :  /cdimage/units/UEA0001/UEA0001_script.lua
-- Author(s):  John Comes
-- Summary  :  UEF CDR Pod Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local TConstructionUnit = import("/lua/terranunits.lua").TConstructionUnit

---@class UEA0001 : TConstructionUnit
UEA0001 = ClassUnit(TConstructionUnit) {
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

TypeClass = UEA0001
